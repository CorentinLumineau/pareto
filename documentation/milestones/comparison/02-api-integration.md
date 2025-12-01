# Phase 02: API Integration

> **Go API endpoints for comparison**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      02 - API Integration                              ║
║  Initiative: Comparison                                        ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Create Go API endpoints that fetch products from catalog and delegate Pareto calculation to Python workers.

## Tasks

- [ ] Implement comparison handler
- [ ] Connect to Python Pareto API
- [ ] Add response caching
- [ ] Create comparison routes
- [ ] Add request validation

## Comparison Handler

```go
// apps/api/internal/compare/handler.go
package compare

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "pareto/internal/catalog/repository"
    "pareto/internal/compare/client"
    "pareto/internal/compare/cache"
)

type Handler struct {
    productRepo  repository.ProductRepository
    paretoClient *client.ParetoClient
    cache        cache.CompareCache
}

func NewHandler(
    pr repository.ProductRepository,
    pc *client.ParetoClient,
    c cache.CompareCache,
) *Handler {
    return &Handler{
        productRepo:  pr,
        paretoClient: pc,
        cache:        c,
    }
}

// CompareRequest from frontend
type CompareRequest struct {
    ProductIDs []string           `json:"product_ids" binding:"required,min=2,max=50"`
    Criteria   []CriterionInput   `json:"criteria,omitempty"`
}

type CriterionInput struct {
    Name         string   `json:"name" binding:"required"`
    Objective    string   `json:"objective" binding:"oneof=min max"`
    Weight       float64  `json:"weight" binding:"gte=0,lte=1"`
    DefaultValue *float64 `json:"default_value,omitempty"`
}

// CompareResponse to frontend
type CompareResponse struct {
    Frontier      []ProductScore `json:"frontier"`
    Dominated     []ProductScore `json:"dominated"`
    TotalProducts int            `json:"total_products"`
    FrontierCount int            `json:"frontier_count"`
    CachedAt      *time.Time     `json:"cached_at,omitempty"`
}

type ProductScore struct {
    ID            string             `json:"id"`
    Title         string             `json:"title"`
    Brand         string             `json:"brand"`
    BestPrice     *float64           `json:"best_price"`
    OverallScore  float64            `json:"overall_score"`
    CriteriaScores map[string]float64 `json:"criteria_scores"`
    IsFrontier    bool               `json:"is_frontier"`
}

func (h *Handler) Compare(c *gin.Context) {
    var req CompareRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    ctx := c.Request.Context()

    // Check cache
    cacheKey := h.buildCacheKey(req)
    if cached, err := h.cache.Get(ctx, cacheKey); err == nil {
        c.JSON(http.StatusOK, cached)
        return
    }

    // Fetch products from catalog
    products, err := h.fetchProducts(ctx, req.ProductIDs)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    // Build Pareto request
    paretoReq := h.buildParetoRequest(products, req.Criteria)

    // Call Python Pareto service
    paretoResp, err := h.paretoClient.Compare(ctx, paretoReq)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "pareto calculation failed"})
        return
    }

    // Build response
    response := h.buildResponse(products, paretoResp)

    // Cache for 5 minutes
    h.cache.Set(ctx, cacheKey, response, 5*time.Minute)

    c.JSON(http.StatusOK, response)
}

func (h *Handler) fetchProducts(ctx context.Context, ids []string) ([]repository.ProductWithOffers, error) {
    products := make([]repository.ProductWithOffers, 0, len(ids))

    for _, idStr := range ids {
        id, err := uuid.Parse(idStr)
        if err != nil {
            continue
        }

        product, err := h.productRepo.GetByID(ctx, id)
        if err != nil {
            continue
        }

        products = append(products, *product)
    }

    return products, nil
}

func (h *Handler) buildParetoRequest(products []repository.ProductWithOffers, criteria []CriterionInput) *client.ParetoRequest {
    paretoProducts := make([]client.ProductInput, len(products))

    for i, p := range products {
        values := make(map[string]float64)

        // Price (best offer)
        if len(p.Offers) > 0 {
            bestPrice := float64(999999)
            for _, o := range p.Offers {
                if o.LastPrice != nil {
                    price, _ := o.LastPrice.Float64()
                    if price < bestPrice {
                        bestPrice = price
                    }
                }
            }
            values["price"] = bestPrice
        }

        // Extract attributes
        if attrs := p.Attributes.Data; attrs != nil {
            if storage, ok := attrs["storage"].(float64); ok {
                values["storage"] = storage
            }
            if ram, ok := attrs["ram"].(float64); ok {
                values["ram"] = ram
            }
            if battery, ok := attrs["battery"].(float64); ok {
                values["battery"] = battery
            }
        }

        paretoProducts[i] = client.ProductInput{
            ID:     p.ID.String(),
            Name:   p.Title,
            Values: values,
        }
    }

    req := &client.ParetoRequest{
        Products: paretoProducts,
    }

    // Add custom criteria if provided
    if len(criteria) > 0 {
        req.Criteria = make([]client.CriterionInput, len(criteria))
        for i, c := range criteria {
            req.Criteria[i] = client.CriterionInput{
                Name:         c.Name,
                Objective:    c.Objective,
                Weight:       c.Weight,
                DefaultValue: c.DefaultValue,
            }
        }
    }

    return req
}

func (h *Handler) buildResponse(products []repository.ProductWithOffers, pareto *client.ParetoResponse) *CompareResponse {
    productMap := make(map[string]repository.ProductWithOffers)
    for _, p := range products {
        productMap[p.ID.String()] = p
    }

    frontier := make([]ProductScore, 0, len(pareto.Frontier))
    dominated := make([]ProductScore, 0, len(pareto.Dominated))

    for _, id := range pareto.Frontier {
        if p, ok := productMap[id]; ok {
            score := h.buildProductScore(p, pareto.Scores[id], true)
            frontier = append(frontier, score)
        }
    }

    for _, id := range pareto.Dominated {
        if p, ok := productMap[id]; ok {
            score := h.buildProductScore(p, pareto.Scores[id], false)
            dominated = append(dominated, score)
        }
    }

    return &CompareResponse{
        Frontier:      frontier,
        Dominated:     dominated,
        TotalProducts: pareto.Total,
        FrontierCount: pareto.FrontierCount,
    }
}

func (h *Handler) buildProductScore(p repository.ProductWithOffers, scores map[string]interface{}, isFrontier bool) ProductScore {
    var bestPrice *float64
    for _, o := range p.Offers {
        if o.LastPrice != nil {
            price, _ := o.LastPrice.Float64()
            if bestPrice == nil || price < *bestPrice {
                bestPrice = &price
            }
        }
    }

    ps := ProductScore{
        ID:         p.ID.String(),
        Title:      p.Title,
        Brand:      p.Brand,
        BestPrice:  bestPrice,
        IsFrontier: isFrontier,
    }

    if scores != nil {
        if overall, ok := scores["overall"].(float64); ok {
            ps.OverallScore = overall
        }
        if criteria, ok := scores["criteria"].(map[string]interface{}); ok {
            ps.CriteriaScores = make(map[string]float64)
            for k, v := range criteria {
                if f, ok := v.(float64); ok {
                    ps.CriteriaScores[k] = f
                }
            }
        }
    }

    return ps
}

func (h *Handler) buildCacheKey(req CompareRequest) string {
    // Simple hash of product IDs
    data, _ := json.Marshal(req)
    return fmt.Sprintf("compare:%x", data)
}
```

## Pareto Client

```go
// apps/api/internal/compare/client/pareto.go
package client

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"
)

type ParetoClient struct {
    baseURL    string
    httpClient *http.Client
}

func NewParetoClient(baseURL string) *ParetoClient {
    return &ParetoClient{
        baseURL: baseURL,
        httpClient: &http.Client{
            Timeout: 10 * time.Second,
        },
    }
}

type ProductInput struct {
    ID     string             `json:"id"`
    Name   string             `json:"name"`
    Values map[string]float64 `json:"values"`
}

type CriterionInput struct {
    Name         string   `json:"name"`
    Objective    string   `json:"objective"`
    Weight       float64  `json:"weight"`
    DefaultValue *float64 `json:"default_value,omitempty"`
}

type ParetoRequest struct {
    Products []ProductInput   `json:"products"`
    Criteria []CriterionInput `json:"criteria,omitempty"`
}

type ParetoResponse struct {
    Frontier      []string                          `json:"frontier"`
    Dominated     []string                          `json:"dominated"`
    Scores        map[string]map[string]interface{} `json:"scores"`
    Total         int                               `json:"total"`
    FrontierCount int                               `json:"frontier_count"`
}

func (c *ParetoClient) Compare(ctx context.Context, req *ParetoRequest) (*ParetoResponse, error) {
    body, err := json.Marshal(req)
    if err != nil {
        return nil, err
    }

    httpReq, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+"/compare", bytes.NewReader(body))
    if err != nil {
        return nil, err
    }
    httpReq.Header.Set("Content-Type", "application/json")

    resp, err := c.httpClient.Do(httpReq)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("pareto service returned %d", resp.StatusCode)
    }

    var result ParetoResponse
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }

    return &result, nil
}
```

## Routes

```go
// apps/api/internal/compare/routes.go
package compare

import "github.com/gin-gonic/gin"

func RegisterRoutes(r *gin.RouterGroup, h *Handler) {
    compare := r.Group("/api/v1/compare")

    compare.POST("", h.Compare)
    compare.GET("/criteria", h.GetCriteria)
    compare.POST("/frontier", h.GetFrontier)
}

// GetCriteria returns available comparison criteria
func (h *Handler) GetCriteria(c *gin.Context) {
    criteria := []map[string]interface{}{
        {"name": "price", "objective": "min", "label": "Prix", "default_weight": 1.0},
        {"name": "storage", "objective": "max", "label": "Stockage", "default_weight": 0.8},
        {"name": "ram", "objective": "max", "label": "RAM", "default_weight": 0.6},
        {"name": "battery", "objective": "max", "label": "Batterie", "default_weight": 0.4},
        {"name": "screen_size", "objective": "max", "label": "Taille écran", "default_weight": 0.3},
    }
    c.JSON(http.StatusOK, gin.H{"criteria": criteria})
}

// GetFrontier returns Pareto frontier for a category
func (h *Handler) GetFrontier(c *gin.Context) {
    // Similar to Compare but fetches all products in a category
    // ... implementation
}
```

## Deliverables

- [ ] Compare handler implementation
- [ ] Pareto client for Python service
- [ ] Response caching
- [ ] Route registration
- [ ] Integration tests

---

**Previous Phase**: [01-pareto-engine.md](./01-pareto-engine.md)
**Next Phase**: [03-scoring.md](./03-scoring.md)
**Back to**: [Comparison README](./README.md)
