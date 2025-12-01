package domain

import (
	"time"
)

// Product represents a product in the catalog
type Product struct {
	ID         string                 `json:"id"`
	Slug       string                 `json:"slug"`
	Name       string                 `json:"name"`
	GTIN       *string                `json:"gtin,omitempty"`
	CategoryID string                 `json:"categoryId"`
	BrandID    *string                `json:"brandId,omitempty"`
	Attributes map[string]interface{} `json:"attributes"`
	CreatedAt  time.Time              `json:"createdAt"`
	UpdatedAt  time.Time              `json:"updatedAt"`
}

// Price represents a product price from a retailer
type Price struct {
	ID           string    `json:"id"`
	ProductID    string    `json:"productId"`
	RetailerID   string    `json:"retailerId"`
	Price        float64   `json:"price"`
	Shipping     *float64  `json:"shipping,omitempty"`
	TotalPrice   float64   `json:"totalPrice"`
	InStock      bool      `json:"inStock"`
	AffiliateURL string    `json:"affiliateUrl"`
	ScrapedAt    time.Time `json:"scrapedAt"`
	CreatedAt    time.Time `json:"createdAt"`
}

// Category represents a product category
type Category struct {
	ID              string                 `json:"id"`
	Name            string                 `json:"name"`
	Slug            string                 `json:"slug"`
	ParentID        *string                `json:"parentId,omitempty"`
	AttributeSchema map[string]interface{} `json:"attributeSchema"`
	CreatedAt       time.Time              `json:"createdAt"`
	UpdatedAt       time.Time              `json:"updatedAt"`
}

// Retailer represents a store/merchant
type Retailer struct {
	ID               string    `json:"id"`
	Name             string    `json:"name"`
	Slug             string    `json:"slug"`
	WebsiteURL       string    `json:"websiteUrl"`
	LogoURL          *string   `json:"logoUrl,omitempty"`
	AffiliateNetwork *string   `json:"affiliateNetwork,omitempty"`
	AffiliateID      *string   `json:"affiliateId,omitempty"`
	Active           bool      `json:"active"`
	CreatedAt        time.Time `json:"createdAt"`
	UpdatedAt        time.Time `json:"updatedAt"`
}

// ProductWithPrices includes product with all its prices
type ProductWithPrices struct {
	Product
	Prices     []Price  `json:"prices"`
	BestPrice  *float64 `json:"bestPrice,omitempty"`
	PriceCount int      `json:"priceCount"`
}

// CreateProductRequest represents a request to create a product
type CreateProductRequest struct {
	Name       string                 `json:"name"`
	GTIN       *string                `json:"gtin,omitempty"`
	CategoryID string                 `json:"categoryId"`
	BrandID    *string                `json:"brandId,omitempty"`
	Attributes map[string]interface{} `json:"attributes,omitempty"`
}

// UpdateProductRequest represents a request to update a product
type UpdateProductRequest struct {
	Name       *string                `json:"name,omitempty"`
	GTIN       *string                `json:"gtin,omitempty"`
	CategoryID *string                `json:"categoryId,omitempty"`
	BrandID    *string                `json:"brandId,omitempty"`
	Attributes map[string]interface{} `json:"attributes,omitempty"`
}
