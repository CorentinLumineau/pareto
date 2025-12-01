# Phase 04: Public API

> **Frontend-facing REST endpoints**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      04 - Public API                                   ║
║  Initiative: Catalog                                           ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     3 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Build public API endpoints for the frontend to list products, search, and view price history.

## Tasks

- [ ] Implement product list endpoint
- [ ] Implement product detail endpoint
- [ ] Implement search endpoint
- [ ] Add price history endpoint
- [ ] Implement caching
- [ ] Add rate limiting

## Public Routes

```go
// apps/api/internal/catalog/routes/public.go
package routes

import (
    "github.com/gin-gonic/gin"
    "pareto/internal/catalog/handlers"
)

func RegisterPublicRoutes(r *gin.RouterGroup, h *handlers.PublicHandler) {
    v1 := r.Group("/api/v1")

    // Products
    v1.GET("/products", h.ListProducts)
    v1.GET("/products/search", h.SearchProducts)
    v1.GET("/products/:id", h.GetProduct)
    v1.GET("/products/:id/offers", h.GetProductOffers)
    v1.GET("/products/:id/prices", h.GetPriceHistory)

    // Categories
    v1.GET("/categories", h.ListCategories)
    v1.GET("/categories/:slug/products", h.GetCategoryProducts)
}
```

## Public Handler

```go
// apps/api/internal/catalog/handlers/public.go
package handlers

import (
    "net/http"
    "strconv"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "pareto/internal/catalog/cache"
    "pareto/internal/catalog/repository"
)

type PublicHandler struct {
    productRepo repository.ProductRepository
    offerRepo   repository.OfferRepository
    priceRepo   repository.PriceRepository
    cache       cache.Cache
}

func NewPublicHandler(
    pr repository.ProductRepository,
    or repository.OfferRepository,
    prr repository.PriceRepository,
    c cache.Cache,
) *PublicHandler {
    return &PublicHandler{
        productRepo: pr,
        offerRepo:   or,
        priceRepo:   prr,
        cache:       c,
    }
}

// ListProducts returns paginated product list
type ProductListResponse struct {
    Products   []ProductSummary `json:"products"`
    Total      int64            `json:"total"`
    Page       int              `json:"page"`
    PerPage    int              `json:"per_page"`
    TotalPages int              `json:"total_pages"`
}

type ProductSummary struct {
    ID         string   `json:"id"`
    Title      string   `json:"title"`
    Brand      string   `json:"brand"`
    Model      string   `json:"model"`
    BestPrice  *float64 `json:"best_price"`
    OfferCount int      `json:"offer_count"`
    ImageURL   *string  `json:"image_url"`
}

func (h *PublicHandler) ListProducts(c *gin.Context) {
    page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
    perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))
    brand := c.Query("brand")
    sortBy := c.DefaultQuery("sort", "title")
    sortOrder := c.DefaultQuery("order", "asc")

    if page < 1 {
        page = 1
    }
    if perPage < 1 || perPage > 100 {
        perPage = 20
    }

    opts := repository.ListOptions{
        Brand:     brand,
        SortBy:    sortBy,
        SortOrder: sortOrder,
        Limit:     perPage,
        Offset:    (page - 1) * perPage,
    }

    products, total, err := h.productRepo.List(c.Request.Context(), opts)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    summaries := make([]ProductSummary, len(products))
    for i, p := range products {
        var bestPrice *float64
        for _, offer := range p.Offers {
            if offer.LastPrice != nil {
                price, _ := offer.LastPrice.Float64()
                if bestPrice == nil || price < *bestPrice {
                    bestPrice = &price
                }
            }
        }

        summaries[i] = ProductSummary{
            ID:         p.ID.String(),
            Title:      p.Title,
            Brand:      p.Brand,
            Model:      p.Model,
            BestPrice:  bestPrice,
            OfferCount: len(p.Offers),
        }
    }

    totalPages := int((total + int64(perPage) - 1) / int64(perPage))

    c.JSON(http.StatusOK, ProductListResponse{
        Products:   summaries,
        Total:      total,
        Page:       page,
        PerPage:    perPage,
        TotalPages: totalPages,
    })
}

// SearchProducts performs full-text search
type SearchResponse struct {
    Results []ProductSummary `json:"results"`
    Query   string           `json:"query"`
    Count   int              `json:"count"`
}

func (h *PublicHandler) SearchProducts(c *gin.Context) {
    query := c.Query("q")
    if query == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "query required"})
        return
    }

    limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
    if limit > 50 {
        limit = 50
    }

    products, err := h.productRepo.Search(c.Request.Context(), query, repository.SearchOptions{
        Limit: limit,
    })
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    results := make([]ProductSummary, len(products))
    for i, p := range products {
        results[i] = ProductSummary{
            ID:    p.ID.String(),
            Title: p.Title,
            Brand: p.Brand,
            Model: p.Model,
        }
    }

    c.JSON(http.StatusOK, SearchResponse{
        Results: results,
        Query:   query,
        Count:   len(results),
    })
}

// GetProduct returns detailed product info
type ProductDetailResponse struct {
    ID          string           `json:"id"`
    EAN         *string          `json:"ean"`
    Title       string           `json:"title"`
    Brand       string           `json:"brand"`
    Model       string           `json:"model"`
    Description *string          `json:"description"`
    Attributes  map[string]any   `json:"attributes"`
    Category    *CategoryInfo    `json:"category"`
    Offers      []OfferInfo      `json:"offers"`
    BestPrice   *float64         `json:"best_price"`
    OfferCount  int              `json:"offer_count"`
}

type CategoryInfo struct {
    ID   string `json:"id"`
    Name string `json:"name"`
    Slug string `json:"slug"`
}

type OfferInfo struct {
    ID           string   `json:"id"`
    RetailerID   string   `json:"retailer_id"`
    RetailerName string   `json:"retailer_name"`
    Price        *float64 `json:"price"`
    URL          string   `json:"url"`
    AffiliateURL *string  `json:"affiliate_url"`
    InStock      bool     `json:"in_stock"`
    LastSeenAt   string   `json:"last_seen_at"`
}

func (h *PublicHandler) GetProduct(c *gin.Context) {
    idStr := c.Param("id")
    id, err := uuid.Parse(idStr)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
        return
    }

    // Try cache first
    cacheKey := "product:" + idStr
    var cached ProductDetailResponse
    if err := h.cache.Get(c.Request.Context(), cacheKey, &cached); err == nil {
        c.JSON(http.StatusOK, cached)
        return
    }

    product, err := h.productRepo.GetByID(c.Request.Context(), id)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "product not found"})
        return
    }

    offers := make([]OfferInfo, len(product.Offers))
    var bestPrice *float64
    for i, o := range product.Offers {
        var price *float64
        if o.LastPrice != nil {
            p, _ := o.LastPrice.Float64()
            price = &p
            if bestPrice == nil || p < *bestPrice {
                bestPrice = &p
            }
        }

        retailerName := o.RetailerID
        if o.Retailer != nil {
            retailerName = o.Retailer.Name
        }

        offers[i] = OfferInfo{
            ID:           o.ID.String(),
            RetailerID:   o.RetailerID,
            RetailerName: retailerName,
            Price:        price,
            URL:          o.URL,
            AffiliateURL: o.AffiliateURL,
            InStock:      o.InStock,
            LastSeenAt:   o.LastSeenAt.Format(time.RFC3339),
        }
    }

    response := ProductDetailResponse{
        ID:          product.ID.String(),
        EAN:         product.EAN,
        Title:       product.Title,
        Brand:       product.Brand,
        Model:       product.Model,
        Description: product.Description,
        Attributes:  product.Attributes.Data,
        Offers:      offers,
        BestPrice:   bestPrice,
        OfferCount:  len(offers),
    }

    if product.Category != nil {
        response.Category = &CategoryInfo{
            ID:   product.Category.ID.String(),
            Name: product.Category.Name,
            Slug: product.Category.Slug,
        }
    }

    // Cache for 5 minutes
    h.cache.Set(c.Request.Context(), cacheKey, response, 5*time.Minute)

    c.JSON(http.StatusOK, response)
}

// GetPriceHistory returns price history for a product
type PriceHistoryResponse struct {
    ProductID string            `json:"product_id"`
    OfferID   string            `json:"offer_id"`
    Retailer  string            `json:"retailer"`
    Prices    []PricePointDTO   `json:"prices"`
}

type PricePointDTO struct {
    Date  string  `json:"date"`
    Price float64 `json:"price"`
    Min   float64 `json:"min"`
    Max   float64 `json:"max"`
}

func (h *PublicHandler) GetPriceHistory(c *gin.Context) {
    productID := c.Param("id")
    retailer := c.Query("retailer")
    days, _ := strconv.Atoi(c.DefaultQuery("days", "30"))

    if days > 365 {
        days = 365
    }

    // Get offer for this product/retailer
    offers, err := h.offerRepo.GetByProduct(c.Request.Context(), productID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "offers not found"})
        return
    }

    var targetOffer *models.Offer
    for _, o := range offers {
        if retailer == "" || o.RetailerID == retailer {
            targetOffer = &o
            break
        }
    }

    if targetOffer == nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "offer not found"})
        return
    }

    history, err := h.priceRepo.GetDailyHistory(c.Request.Context(), targetOffer.ID, days)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    prices := make([]PricePointDTO, len(history))
    for i, h := range history {
        close, _ := h.ClosePrice.Float64()
        min, _ := h.MinPrice.Float64()
        max, _ := h.MaxPrice.Float64()
        prices[i] = PricePointDTO{
            Date:  h.Day.Format("2006-01-02"),
            Price: close,
            Min:   min,
            Max:   max,
        }
    }

    c.JSON(http.StatusOK, PriceHistoryResponse{
        ProductID: productID,
        OfferID:   targetOffer.ID.String(),
        Retailer:  targetOffer.RetailerID,
        Prices:    prices,
    })
}
```

## Rate Limiting Middleware

```go
// apps/api/internal/catalog/middleware/ratelimit.go
package middleware

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/redis/go-redis/v9"
    "golang.org/x/time/rate"
    "sync"
)

type RateLimiter struct {
    limiters map[string]*rate.Limiter
    mu       sync.RWMutex
    rate     rate.Limit
    burst    int
}

func NewRateLimiter(r rate.Limit, b int) *RateLimiter {
    return &RateLimiter{
        limiters: make(map[string]*rate.Limiter),
        rate:     r,
        burst:    b,
    }
}

func (rl *RateLimiter) getLimiter(ip string) *rate.Limiter {
    rl.mu.Lock()
    defer rl.mu.Unlock()

    limiter, exists := rl.limiters[ip]
    if !exists {
        limiter = rate.NewLimiter(rl.rate, rl.burst)
        rl.limiters[ip] = limiter
    }

    return limiter
}

func (rl *RateLimiter) Middleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        ip := c.ClientIP()
        limiter := rl.getLimiter(ip)

        if !limiter.Allow() {
            c.JSON(http.StatusTooManyRequests, gin.H{
                "error": "rate limit exceeded",
            })
            c.Abort()
            return
        }

        c.Next()
    }
}
```

## Deliverables

- [ ] Product list with pagination
- [ ] Product detail with offers
- [ ] Full-text search
- [ ] Price history endpoint
- [ ] Redis caching
- [ ] Rate limiting
- [ ] API documentation

---

**Previous Phase**: [03-internal-api.md](./03-internal-api.md)
**Back to**: [Catalog README](./README.md)
