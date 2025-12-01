# Phase 03: Internal API

> **Normalizer integration endpoints**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      03 - Internal API                                 ║
║  Initiative: Catalog                                           ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Build internal API endpoints for the normalizer service to create/update products and record prices.

## Tasks

- [ ] Implement product upsert endpoint
- [ ] Implement offer creation
- [ ] Implement price recording
- [ ] Add entity matching endpoint
- [ ] Setup authentication for internal calls

## Internal Routes

```go
// apps/api/internal/catalog/routes/internal.go
package routes

import (
    "github.com/gin-gonic/gin"
    "pareto/internal/catalog/handlers"
)

func RegisterInternalRoutes(r *gin.RouterGroup, h *handlers.InternalHandler) {
    internal := r.Group("/internal")
    internal.Use(InternalAuthMiddleware())

    // Products
    internal.POST("/products", h.UpsertProduct)
    internal.GET("/products/by-ean/:ean", h.GetByEAN)
    internal.POST("/products/match", h.MatchProduct)
    internal.GET("/products/by-fingerprint/:fp", h.GetByFingerprint)

    // Offers
    internal.POST("/offers", h.UpsertOffer)

    // Prices
    internal.POST("/prices", h.RecordPrice)
}

// Simple token auth for internal services
func InternalAuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := c.GetHeader("X-Internal-Token")
        if token != config.InternalToken {
            c.AbortWithStatusJSON(401, gin.H{"error": "unauthorized"})
            return
        }
        c.Next()
    }
}
```

## Internal Handler

```go
// apps/api/internal/catalog/handlers/internal.go
package handlers

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "github.com/shopspring/decimal"
    "pareto/internal/catalog/models"
    "pareto/internal/catalog/repository"
    "pareto/internal/catalog/service"
)

type InternalHandler struct {
    productRepo repository.ProductRepository
    offerRepo   repository.OfferRepository
    priceRepo   repository.PriceRepository
    matcher     *service.ProductMatcher
}

func NewInternalHandler(
    pr repository.ProductRepository,
    or repository.OfferRepository,
    prr repository.PriceRepository,
    m *service.ProductMatcher,
) *InternalHandler {
    return &InternalHandler{
        productRepo: pr,
        offerRepo:   or,
        priceRepo:   prr,
        matcher:     m,
    }
}

// UpsertProduct creates or updates a product
type UpsertProductRequest struct {
    ExternalID  string            `json:"external_id" binding:"required"`
    RetailerID  string            `json:"retailer_id" binding:"required"`
    EAN         *string           `json:"ean"`
    Brand       string            `json:"brand" binding:"required"`
    Model       string            `json:"model" binding:"required"`
    Title       string            `json:"title" binding:"required"`
    URL         string            `json:"url" binding:"required"`
    Price       float64           `json:"price" binding:"required,gt=0"`
    Attributes  map[string]any    `json:"attributes"`
    Fingerprint *string           `json:"fingerprint"`
    MatchInfo   *MatchInfo        `json:"match_info"`
}

type MatchInfo struct {
    Matched    bool    `json:"matched"`
    ProductID  *string `json:"product_id"`
    Confidence float64 `json:"confidence"`
    Method     string  `json:"method"`
}

func (h *InternalHandler) UpsertProduct(c *gin.Context) {
    var req UpsertProductRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    ctx := c.Request.Context()
    var product *models.Product

    // If matched to existing product, use that
    if req.MatchInfo != nil && req.MatchInfo.Matched && req.MatchInfo.ProductID != nil {
        productID, err := uuid.Parse(*req.MatchInfo.ProductID)
        if err == nil {
            product, _ = h.productRepo.GetByID(ctx, productID)
        }
    }

    // Otherwise try EAN match
    if product == nil && req.EAN != nil {
        product, _ = h.productRepo.GetByEAN(ctx, *req.EAN)
    }

    // Create new if not found
    if product == nil {
        product = &models.Product{
            EAN:         req.EAN,
            Brand:       req.Brand,
            Model:       req.Model,
            Title:       req.Title,
            Fingerprint: req.Fingerprint,
        }
        if req.Attributes != nil {
            product.Attributes.Data = req.Attributes
        }
        if err := h.productRepo.Create(ctx, product); err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }
    }

    // Upsert offer
    offer := &models.Offer{
        ProductID:  product.ID,
        RetailerID: req.RetailerID,
        ExternalID: req.ExternalID,
        URL:        req.URL,
        InStock:    true,
        LastPrice:  decimalPtr(req.Price),
    }
    if err := h.offerRepo.Upsert(ctx, offer); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    // Record price
    price := decimal.NewFromFloat(req.Price)
    if err := h.priceRepo.Record(ctx, offer.ID, price); err != nil {
        // Log but don't fail
    }

    c.JSON(http.StatusOK, gin.H{
        "product_id": product.ID,
        "offer_id":   offer.ID,
        "created":    product.CreatedAt,
    })
}

// GetByEAN finds product by EAN
func (h *InternalHandler) GetByEAN(c *gin.Context) {
    ean := c.Param("ean")

    product, err := h.productRepo.GetByEAN(c.Request.Context(), ean)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "product not found"})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "id":    product.ID,
        "ean":   product.EAN,
        "title": product.Title,
    })
}

// MatchProduct performs entity resolution
type MatchRequest struct {
    Fingerprint string  `json:"fingerprint"`
    Brand       string  `json:"brand"`
    Model       string  `json:"model"`
    Storage     *string `json:"storage"`
    Title       string  `json:"title"`
}

type MatchResponse struct {
    Matches []MatchResult `json:"matches"`
}

type MatchResult struct {
    ID         string  `json:"id"`
    Title      string  `json:"title"`
    Confidence float64 `json:"confidence"`
}

func (h *InternalHandler) MatchProduct(c *gin.Context) {
    var req MatchRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    matches, err := h.matcher.FindMatches(c.Request.Context(), req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, MatchResponse{Matches: matches})
}

// RecordPrice adds a price point
type RecordPriceRequest struct {
    OfferID  string  `json:"offer_id" binding:"required"`
    Price    float64 `json:"price" binding:"required,gt=0"`
    WasPrice *float64 `json:"was_price"`
}

func (h *InternalHandler) RecordPrice(c *gin.Context) {
    var req RecordPriceRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    offerID, err := uuid.Parse(req.OfferID)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid offer_id"})
        return
    }

    price := decimal.NewFromFloat(req.Price)
    if err := h.priceRepo.Record(c.Request.Context(), offerID, price); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"status": "recorded"})
}

func decimalPtr(f float64) *decimal.Decimal {
    d := decimal.NewFromFloat(f)
    return &d
}
```

## Product Matcher Service

```go
// apps/api/internal/catalog/service/matcher.go
package service

import (
    "context"
    "strings"
    "pareto/internal/catalog/repository"
    "pareto/internal/catalog/handlers"
)

type ProductMatcher struct {
    productRepo repository.ProductRepository
}

func NewProductMatcher(pr repository.ProductRepository) *ProductMatcher {
    return &ProductMatcher{productRepo: pr}
}

func (m *ProductMatcher) FindMatches(ctx context.Context, req handlers.MatchRequest) ([]handlers.MatchResult, error) {
    var results []handlers.MatchResult

    // 1. Try fingerprint exact match
    if req.Fingerprint != "" {
        product, err := m.productRepo.GetByFingerprint(ctx, req.Fingerprint)
        if err == nil {
            results = append(results, handlers.MatchResult{
                ID:         product.ID.String(),
                Title:      product.Title,
                Confidence: 0.95,
            })
            return results, nil
        }
    }

    // 2. Try brand + model search
    searchQuery := req.Brand + " " + req.Model
    if req.Storage != nil {
        searchQuery += " " + *req.Storage
    }

    products, err := m.productRepo.Search(ctx, searchQuery, repository.SearchOptions{
        Brand: req.Brand,
        Limit: 5,
    })
    if err != nil {
        return nil, err
    }

    for _, p := range products {
        confidence := m.calculateConfidence(req, p)
        if confidence > 0.5 {
            results = append(results, handlers.MatchResult{
                ID:         p.ID.String(),
                Title:      p.Title,
                Confidence: confidence,
            })
        }
    }

    return results, nil
}

func (m *ProductMatcher) calculateConfidence(req handlers.MatchRequest, product models.Product) float64 {
    confidence := 0.0

    // Brand match
    if strings.EqualFold(req.Brand, product.Brand) {
        confidence += 0.3
    }

    // Model match
    if strings.Contains(strings.ToLower(product.Model), strings.ToLower(req.Model)) {
        confidence += 0.4
    }

    // Title similarity
    if strings.Contains(strings.ToLower(product.Title), strings.ToLower(req.Title[:min(50, len(req.Title))])) {
        confidence += 0.2
    }

    // Storage match if available
    if req.Storage != nil {
        attrs := product.Attributes.Data
        if storage, ok := attrs["storage"].(string); ok {
            if strings.Contains(strings.ToLower(storage), strings.ToLower(*req.Storage)) {
                confidence += 0.1
            }
        }
    }

    return confidence
}
```

## Deliverables

- [ ] Product upsert endpoint
- [ ] Offer upsert endpoint
- [ ] Price recording endpoint
- [ ] Entity matching endpoint
- [ ] Internal auth middleware
- [ ] Integration tests

---

**Previous Phase**: [02-repository.md](./02-repository.md)
**Next Phase**: [04-public-api.md](./04-public-api.md)
**Back to**: [Catalog README](./README.md)
