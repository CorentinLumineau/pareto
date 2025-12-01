package domain

import (
	"time"
)

// Product represents a product in the catalog (from brand websites)
type Product struct {
	ID          string                 `json:"id" db:"id"`
	CategoryID  string                 `json:"categoryId" db:"category_id"`
	Name        string                 `json:"name" db:"name"`
	Slug        string                 `json:"slug" db:"slug"`
	Brand       string                 `json:"brand" db:"brand"`
	Model       string                 `json:"model" db:"model"`
	EAN         *string                `json:"ean,omitempty" db:"ean"`
	SKU         *string                `json:"sku,omitempty" db:"sku"`
	ImageURL    *string                `json:"imageUrl,omitempty" db:"image_url"`
	Images      []string               `json:"images" db:"images"`
	Attributes  map[string]interface{} `json:"attributes" db:"attributes"`
	Source      string                 `json:"source" db:"source"`
	SourceURL   *string                `json:"sourceUrl,omitempty" db:"source_url"`
	Description *string                `json:"description,omitempty" db:"description"`
	Active      bool                   `json:"active" db:"active"`
	CreatedAt   time.Time              `json:"createdAt" db:"created_at"`
	UpdatedAt   time.Time              `json:"updatedAt" db:"updated_at"`
	ScrapedAt   *time.Time             `json:"scrapedAt,omitempty" db:"scraped_at"`
}

// Variant represents a product variant (color, storage combinations)
type Variant struct {
	ID         string                 `json:"id" db:"id"`
	ProductID  string                 `json:"productId" db:"product_id"`
	SKU        string                 `json:"sku" db:"sku"`
	EAN        *string                `json:"ean,omitempty" db:"ean"`
	Color      *string                `json:"color,omitempty" db:"color"`
	ColorHex   *string                `json:"colorHex,omitempty" db:"color_hex"`
	StorageGB  *int                   `json:"storageGb,omitempty" db:"storage_gb"`
	RAMGB      *int                   `json:"ramGb,omitempty" db:"ram_gb"`
	Attributes map[string]interface{} `json:"attributes,omitempty" db:"attributes"`
	ImageURL   *string                `json:"imageUrl,omitempty" db:"image_url"`
	MSRP       *float64               `json:"msrp,omitempty" db:"msrp"`
	Currency   string                 `json:"currency" db:"currency"`
	Active     bool                   `json:"active" db:"active"`
	CreatedAt  time.Time              `json:"createdAt" db:"created_at"`
	UpdatedAt  time.Time              `json:"updatedAt" db:"updated_at"`
}

// Offer represents a marketplace price/offer
type Offer struct {
	ID              string     `json:"id" db:"id"`
	ProductID       string     `json:"productId" db:"product_id"`
	VariantID       *string    `json:"variantId,omitempty" db:"variant_id"`
	RetailerID      string     `json:"retailerId" db:"retailer_id"`
	Price           float64    `json:"price" db:"price"`
	Shipping        float64    `json:"shipping" db:"shipping"`
	Currency        string     `json:"currency" db:"currency"`
	WasPrice        *float64   `json:"wasPrice,omitempty" db:"was_price"`
	DiscountPercent *int       `json:"discountPercent,omitempty" db:"discount_percent"`
	URL             string     `json:"url" db:"url"`
	AffiliateURL    *string    `json:"affiliateUrl,omitempty" db:"affiliate_url"`
	InStock         bool       `json:"inStock" db:"in_stock"`
	StockQuantity   *int       `json:"stockQuantity,omitempty" db:"stock_quantity"`
	DeliveryDays    *int       `json:"deliveryDays,omitempty" db:"delivery_days"`
	SellerName      *string    `json:"sellerName,omitempty" db:"seller_name"`
	IsMarketplace   bool       `json:"isMarketplace" db:"is_marketplace"`
	ScrapedAt       time.Time  `json:"scrapedAt" db:"scraped_at"`
	CreatedAt       time.Time  `json:"createdAt" db:"created_at"`
	UpdatedAt       time.Time  `json:"updatedAt" db:"updated_at"`
}

// Category represents a product category
type Category struct {
	ID              string                 `json:"id" db:"id"`
	Name            string                 `json:"name" db:"name"`
	Slug            string                 `json:"slug" db:"slug"`
	ParentID        *string                `json:"parentId,omitempty" db:"parent_id"`
	Description     *string                `json:"description,omitempty" db:"description"`
	ImageURL        *string                `json:"imageUrl,omitempty" db:"image_url"`
	AttributeSchema map[string]interface{} `json:"attributeSchema" db:"attribute_schema"`
	SortOrder       int                    `json:"sortOrder" db:"sort_order"`
	Active          bool                   `json:"active" db:"active"`
	CreatedAt       time.Time              `json:"createdAt" db:"created_at"`
	UpdatedAt       time.Time              `json:"updatedAt" db:"updated_at"`
}

// Retailer represents a store/merchant
type Retailer struct {
	ID                   string    `json:"id" db:"id"`
	Name                 string    `json:"name" db:"name"`
	Slug                 string    `json:"slug" db:"slug"`
	WebsiteURL           string    `json:"websiteUrl" db:"website_url"`
	LogoURL              *string   `json:"logoUrl,omitempty" db:"logo_url"`
	AffiliateNetwork     *string   `json:"affiliateNetwork,omitempty" db:"affiliate_network"`
	AffiliateID          *string   `json:"affiliateId,omitempty" db:"affiliate_id"`
	AffiliateURLTemplate *string   `json:"affiliateUrlTemplate,omitempty" db:"affiliate_url_template"`
	RateLimitMs          int       `json:"rateLimitMs" db:"rate_limit_ms"`
	AntiBotLevel         string    `json:"antiBotLevel" db:"anti_bot_level"`
	Active               bool      `json:"active" db:"active"`
	Priority             int       `json:"priority" db:"priority"`
	CreatedAt            time.Time `json:"createdAt" db:"created_at"`
	UpdatedAt            time.Time `json:"updatedAt" db:"updated_at"`
}

// PriceHistory represents a historical price record
type PriceHistory struct {
	Time       time.Time `json:"time" db:"time"`
	ProductID  string    `json:"productId" db:"product_id"`
	VariantID  *string   `json:"variantId,omitempty" db:"variant_id"`
	RetailerID string    `json:"retailerId" db:"retailer_id"`
	Price      float64   `json:"price" db:"price"`
	InStock    bool      `json:"inStock" db:"in_stock"`
}

// ScrapeJob represents a scraping job
type ScrapeJob struct {
	ID          string     `json:"id" db:"id"`
	JobType     string     `json:"jobType" db:"job_type"`
	RetailerID  *string    `json:"retailerId,omitempty" db:"retailer_id"`
	ProductID   *string    `json:"productId,omitempty" db:"product_id"`
	URL         *string    `json:"url,omitempty" db:"url"`
	Status      string     `json:"status" db:"status"`
	Priority    int        `json:"priority" db:"priority"`
	Attempts    int        `json:"attempts" db:"attempts"`
	MaxAttempts int        `json:"maxAttempts" db:"max_attempts"`
	LastError   *string    `json:"lastError,omitempty" db:"last_error"`
	ScheduledAt time.Time  `json:"scheduledAt" db:"scheduled_at"`
	StartedAt   *time.Time `json:"startedAt,omitempty" db:"started_at"`
	CompletedAt *time.Time `json:"completedAt,omitempty" db:"completed_at"`
	NextRetryAt *time.Time `json:"nextRetryAt,omitempty" db:"next_retry_at"`
	CreatedAt   time.Time  `json:"createdAt" db:"created_at"`
	UpdatedAt   time.Time  `json:"updatedAt" db:"updated_at"`
}

// AffiliateClick represents a click tracking record
type AffiliateClick struct {
	ID         string    `json:"id" db:"id"`
	OfferID    string    `json:"offerId" db:"offer_id"`
	ProductID  string    `json:"productId" db:"product_id"`
	RetailerID string    `json:"retailerId" db:"retailer_id"`
	UserAgent  *string   `json:"userAgent,omitempty" db:"user_agent"`
	IPHash     *string   `json:"ipHash,omitempty" db:"ip_hash"`
	Referrer   *string   `json:"referrer,omitempty" db:"referrer"`
	ClickID    *string   `json:"clickId,omitempty" db:"click_id"`
	ClickedAt  time.Time `json:"clickedAt" db:"clicked_at"`
}

// ============================================
// Composite Types (for API responses)
// ============================================

// ProductWithOffers includes product with all its offers
type ProductWithOffers struct {
	Product
	Variants   []Variant `json:"variants,omitempty"`
	Offers     []Offer   `json:"offers"`
	BestPrice  *float64  `json:"bestPrice,omitempty"`
	OfferCount int       `json:"offerCount"`
}

// ProductWithVariants includes product with its variants
type ProductWithVariants struct {
	Product
	Variants []Variant `json:"variants"`
}

// OfferWithRetailer includes offer with retailer info
type OfferWithRetailer struct {
	Offer
	Retailer Retailer `json:"retailer"`
}

// ============================================
// Request Types
// ============================================

// CreateProductRequest represents a request to create a product
type CreateProductRequest struct {
	CategoryID  string                 `json:"categoryId" validate:"required,uuid"`
	Name        string                 `json:"name" validate:"required,min=1,max=500"`
	Brand       string                 `json:"brand" validate:"required,min=1,max=100"`
	Model       string                 `json:"model" validate:"required,min=1,max=200"`
	EAN         *string                `json:"ean,omitempty" validate:"omitempty,len=13"`
	SKU         *string                `json:"sku,omitempty" validate:"omitempty,max=100"`
	ImageURL    *string                `json:"imageUrl,omitempty" validate:"omitempty,url"`
	Images      []string               `json:"images,omitempty" validate:"omitempty,dive,url"`
	Attributes  map[string]interface{} `json:"attributes,omitempty"`
	Source      string                 `json:"source" validate:"required,oneof=brand manual api"`
	SourceURL   *string                `json:"sourceUrl,omitempty" validate:"omitempty,url"`
	Description *string                `json:"description,omitempty" validate:"omitempty,max=5000"`
}

// UpdateProductRequest represents a request to update a product
type UpdateProductRequest struct {
	CategoryID  *string                `json:"categoryId,omitempty" validate:"omitempty,uuid"`
	Name        *string                `json:"name,omitempty" validate:"omitempty,min=1,max=500"`
	Brand       *string                `json:"brand,omitempty" validate:"omitempty,min=1,max=100"`
	Model       *string                `json:"model,omitempty" validate:"omitempty,min=1,max=200"`
	EAN         *string                `json:"ean,omitempty" validate:"omitempty,len=13"`
	SKU         *string                `json:"sku,omitempty" validate:"omitempty,max=100"`
	ImageURL    *string                `json:"imageUrl,omitempty" validate:"omitempty,url"`
	Images      []string               `json:"images,omitempty" validate:"omitempty,dive,url"`
	Attributes  map[string]interface{} `json:"attributes,omitempty"`
	Description *string                `json:"description,omitempty" validate:"omitempty,max=5000"`
	Active      *bool                  `json:"active,omitempty"`
}

// CreateVariantRequest represents a request to create a variant
type CreateVariantRequest struct {
	ProductID string                 `json:"productId" validate:"required,uuid"`
	SKU       string                 `json:"sku" validate:"required,min=1,max=100"`
	EAN       *string                `json:"ean,omitempty" validate:"omitempty,len=13"`
	Color     *string                `json:"color,omitempty" validate:"omitempty,max=50"`
	ColorHex  *string                `json:"colorHex,omitempty" validate:"omitempty,hexcolor"`
	StorageGB *int                   `json:"storageGb,omitempty" validate:"omitempty,min=1"`
	RAMGB     *int                   `json:"ramGb,omitempty" validate:"omitempty,min=1"`
	Attributes map[string]interface{} `json:"attributes,omitempty"`
	ImageURL  *string                `json:"imageUrl,omitempty" validate:"omitempty,url"`
	MSRP      *float64               `json:"msrp,omitempty" validate:"omitempty,min=0"`
}

// CreateOfferRequest represents a request to create an offer
type CreateOfferRequest struct {
	ProductID     string   `json:"productId" validate:"required,uuid"`
	VariantID     *string  `json:"variantId,omitempty" validate:"omitempty,uuid"`
	RetailerID    string   `json:"retailerId" validate:"required"`
	Price         float64  `json:"price" validate:"required,min=0"`
	Shipping      float64  `json:"shipping" validate:"min=0"`
	WasPrice      *float64 `json:"wasPrice,omitempty" validate:"omitempty,min=0"`
	URL           string   `json:"url" validate:"required,url"`
	AffiliateURL  *string  `json:"affiliateUrl,omitempty" validate:"omitempty,url"`
	InStock       bool     `json:"inStock"`
	StockQuantity *int     `json:"stockQuantity,omitempty" validate:"omitempty,min=0"`
	DeliveryDays  *int     `json:"deliveryDays,omitempty" validate:"omitempty,min=0"`
	SellerName    *string  `json:"sellerName,omitempty" validate:"omitempty,max=200"`
	IsMarketplace bool     `json:"isMarketplace"`
}

// ============================================
// Query Types
// ============================================

// ProductFilter represents filters for querying products
type ProductFilter struct {
	CategoryID  *string                `json:"categoryId,omitempty"`
	Brand       *string                `json:"brand,omitempty"`
	Search      *string                `json:"search,omitempty"`
	MinPrice    *float64               `json:"minPrice,omitempty"`
	MaxPrice    *float64               `json:"maxPrice,omitempty"`
	InStock     *bool                  `json:"inStock,omitempty"`
	Attributes  map[string]interface{} `json:"attributes,omitempty"`
	Active      *bool                  `json:"active,omitempty"`
	Limit       int                    `json:"limit,omitempty"`
	Offset      int                    `json:"offset,omitempty"`
	SortBy      string                 `json:"sortBy,omitempty"`
	SortOrder   string                 `json:"sortOrder,omitempty"`
}

// ============================================
// Constants
// ============================================

// Job types
const (
	JobTypeBrandCatalog = "brand_catalog"
	JobTypeBrandProduct = "brand_product"
	JobTypePrice        = "price"
)

// Job statuses
const (
	JobStatusPending   = "pending"
	JobStatusRunning   = "running"
	JobStatusCompleted = "completed"
	JobStatusFailed    = "failed"
)

// Product sources
const (
	SourceBrand  = "brand"
	SourceManual = "manual"
	SourceAPI    = "api"
)

// Anti-bot levels
const (
	AntiBotNone   = "none"
	AntiBotLight  = "light"
	AntiBotMedium = "medium"
	AntiBotHeavy  = "heavy"
)
