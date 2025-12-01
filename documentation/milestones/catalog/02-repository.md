# Phase 02: Repository Layer

> **GORM models and database access patterns**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      02 - Repository Layer                             ║
║  Initiative: Catalog                                           ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     3 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Implement GORM models and repository pattern for clean database access.

## Tasks

- [ ] Define GORM models
- [ ] Implement ProductRepository
- [ ] Implement OfferRepository
- [ ] Implement PriceRepository
- [ ] Add caching layer
- [ ] Write unit tests

## GORM Models

```go
// apps/api/internal/catalog/models/product.go
package models

import (
    "time"
    "github.com/google/uuid"
    "gorm.io/datatypes"
)

type Product struct {
    ID          uuid.UUID          `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
    EAN         *string            `gorm:"type:varchar(13);uniqueIndex"`
    Brand       string             `gorm:"type:varchar(100);not null;index"`
    Model       string             `gorm:"type:varchar(200);not null;index"`
    Title       string             `gorm:"type:varchar(500);not null"`
    Description *string            `gorm:"type:text"`
    CategoryID  *uuid.UUID         `gorm:"type:uuid;index"`
    Category    *Category          `gorm:"foreignKey:CategoryID"`
    Attributes  datatypes.JSONType[map[string]any] `gorm:"type:jsonb;default:'{}'"`
    Fingerprint *string            `gorm:"type:varchar(200);index"`
    Offers      []Offer            `gorm:"foreignKey:ProductID"`
    CreatedAt   time.Time          `gorm:"autoCreateTime"`
    UpdatedAt   time.Time          `gorm:"autoUpdateTime"`
}

func (Product) TableName() string {
    return "products"
}
```

```go
// apps/api/internal/catalog/models/offer.go
package models

import (
    "time"
    "github.com/google/uuid"
    "github.com/shopspring/decimal"
)

type Offer struct {
    ID           uuid.UUID        `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
    ProductID    uuid.UUID        `gorm:"type:uuid;not null;index"`
    Product      *Product         `gorm:"foreignKey:ProductID"`
    RetailerID   string           `gorm:"type:varchar(50);not null;index"`
    Retailer     *Retailer        `gorm:"foreignKey:RetailerID"`
    ExternalID   string           `gorm:"type:varchar(100);not null"`
    URL          string           `gorm:"type:varchar(2000);not null"`
    AffiliateURL *string          `gorm:"type:varchar(2000)"`
    InStock      bool             `gorm:"default:true;index"`
    LastPrice    *decimal.Decimal `gorm:"type:decimal(10,2)"`
    LastSeenAt   time.Time        `gorm:"autoUpdateTime"`
    CreatedAt    time.Time        `gorm:"autoCreateTime"`
    UpdatedAt    time.Time        `gorm:"autoUpdateTime"`
}

func (Offer) TableName() string {
    return "offers"
}

// Unique constraint
func (o *Offer) BeforeCreate(tx *gorm.DB) error {
    tx.Statement.AddClause(clause.OnConflict{
        Columns:   []clause.Column{{Name: "retailer_id"}, {Name: "external_id"}},
        UpdateAll: true,
    })
    return nil
}
```

```go
// apps/api/internal/catalog/models/price.go
package models

import (
    "time"
    "github.com/google/uuid"
    "github.com/shopspring/decimal"
)

type Price struct {
    Time          time.Time        `gorm:"primaryKey"`
    OfferID       uuid.UUID        `gorm:"type:uuid;primaryKey"`
    Offer         *Offer           `gorm:"foreignKey:OfferID"`
    Price         decimal.Decimal  `gorm:"type:decimal(10,2);not null"`
    Currency      string           `gorm:"type:varchar(3);default:'EUR'"`
    WasPrice      *decimal.Decimal `gorm:"type:decimal(10,2)"`
    ShippingPrice *decimal.Decimal `gorm:"type:decimal(10,2)"`
}

func (Price) TableName() string {
    return "prices"
}
```

## Product Repository

```go
// apps/api/internal/catalog/repository/product.go
package repository

import (
    "context"
    "github.com/google/uuid"
    "gorm.io/gorm"
    "pareto/internal/catalog/models"
)

type ProductRepository interface {
    Create(ctx context.Context, product *models.Product) error
    Update(ctx context.Context, product *models.Product) error
    GetByID(ctx context.Context, id uuid.UUID) (*models.Product, error)
    GetByEAN(ctx context.Context, ean string) (*models.Product, error)
    GetByFingerprint(ctx context.Context, fp string) (*models.Product, error)
    Search(ctx context.Context, query string, opts SearchOptions) ([]models.Product, error)
    List(ctx context.Context, opts ListOptions) ([]models.Product, int64, error)
}

type productRepo struct {
    db *gorm.DB
}

func NewProductRepository(db *gorm.DB) ProductRepository {
    return &productRepo{db: db}
}

func (r *productRepo) Create(ctx context.Context, product *models.Product) error {
    return r.db.WithContext(ctx).Create(product).Error
}

func (r *productRepo) Update(ctx context.Context, product *models.Product) error {
    return r.db.WithContext(ctx).Save(product).Error
}

func (r *productRepo) GetByID(ctx context.Context, id uuid.UUID) (*models.Product, error) {
    var product models.Product
    err := r.db.WithContext(ctx).
        Preload("Category").
        Preload("Offers", "in_stock = ?", true).
        Preload("Offers.Retailer").
        First(&product, "id = ?", id).Error
    if err != nil {
        return nil, err
    }
    return &product, nil
}

func (r *productRepo) GetByEAN(ctx context.Context, ean string) (*models.Product, error) {
    var product models.Product
    err := r.db.WithContext(ctx).
        Where("ean = ?", ean).
        First(&product).Error
    if err != nil {
        return nil, err
    }
    return &product, nil
}

func (r *productRepo) GetByFingerprint(ctx context.Context, fp string) (*models.Product, error) {
    var product models.Product
    err := r.db.WithContext(ctx).
        Where("fingerprint = ?", fp).
        First(&product).Error
    if err != nil {
        return nil, err
    }
    return &product, nil
}

type SearchOptions struct {
    Query    string
    Brand    string
    MinPrice float64
    MaxPrice float64
    InStock  *bool
    Limit    int
    Offset   int
}

func (r *productRepo) Search(ctx context.Context, query string, opts SearchOptions) ([]models.Product, error) {
    var products []models.Product

    tx := r.db.WithContext(ctx).
        Select("products.*, ts_rank(to_tsvector('french', title), plainto_tsquery('french', ?)) as rank", query).
        Where("to_tsvector('french', title) @@ plainto_tsquery('french', ?)", query).
        Order("rank DESC")

    if opts.Brand != "" {
        tx = tx.Where("brand ILIKE ?", "%"+opts.Brand+"%")
    }

    if opts.Limit > 0 {
        tx = tx.Limit(opts.Limit)
    }
    if opts.Offset > 0 {
        tx = tx.Offset(opts.Offset)
    }

    err := tx.Find(&products).Error
    return products, err
}

type ListOptions struct {
    CategoryID *uuid.UUID
    Brand      string
    SortBy     string
    SortOrder  string
    Limit      int
    Offset     int
}

func (r *productRepo) List(ctx context.Context, opts ListOptions) ([]models.Product, int64, error) {
    var products []models.Product
    var total int64

    tx := r.db.WithContext(ctx).Model(&models.Product{})

    if opts.CategoryID != nil {
        tx = tx.Where("category_id = ?", *opts.CategoryID)
    }
    if opts.Brand != "" {
        tx = tx.Where("brand ILIKE ?", "%"+opts.Brand+"%")
    }

    // Count total
    tx.Count(&total)

    // Apply sorting
    if opts.SortBy != "" {
        order := opts.SortBy
        if opts.SortOrder == "desc" {
            order += " DESC"
        }
        tx = tx.Order(order)
    }

    // Apply pagination
    if opts.Limit > 0 {
        tx = tx.Limit(opts.Limit)
    }
    if opts.Offset > 0 {
        tx = tx.Offset(opts.Offset)
    }

    err := tx.Preload("Offers", "in_stock = ?", true).Find(&products).Error
    return products, total, err
}
```

## Price Repository with TimescaleDB

```go
// apps/api/internal/catalog/repository/price.go
package repository

import (
    "context"
    "time"
    "github.com/google/uuid"
    "github.com/shopspring/decimal"
    "gorm.io/gorm"
    "pareto/internal/catalog/models"
)

type PriceRepository interface {
    Record(ctx context.Context, offerID uuid.UUID, price decimal.Decimal) error
    GetHistory(ctx context.Context, offerID uuid.UUID, from, to time.Time) ([]models.Price, error)
    GetDailyHistory(ctx context.Context, offerID uuid.UUID, days int) ([]DailyPrice, error)
    GetLatest(ctx context.Context, offerID uuid.UUID) (*models.Price, error)
}

type DailyPrice struct {
    Day        time.Time       `json:"day"`
    OpenPrice  decimal.Decimal `json:"open_price"`
    ClosePrice decimal.Decimal `json:"close_price"`
    MinPrice   decimal.Decimal `json:"min_price"`
    MaxPrice   decimal.Decimal `json:"max_price"`
}

type priceRepo struct {
    db *gorm.DB
}

func NewPriceRepository(db *gorm.DB) PriceRepository {
    return &priceRepo{db: db}
}

func (r *priceRepo) Record(ctx context.Context, offerID uuid.UUID, price decimal.Decimal) error {
    p := models.Price{
        Time:    time.Now(),
        OfferID: offerID,
        Price:   price,
    }
    return r.db.WithContext(ctx).Create(&p).Error
}

func (r *priceRepo) GetHistory(ctx context.Context, offerID uuid.UUID, from, to time.Time) ([]models.Price, error) {
    var prices []models.Price
    err := r.db.WithContext(ctx).
        Where("offer_id = ? AND time BETWEEN ? AND ?", offerID, from, to).
        Order("time DESC").
        Find(&prices).Error
    return prices, err
}

func (r *priceRepo) GetDailyHistory(ctx context.Context, offerID uuid.UUID, days int) ([]DailyPrice, error) {
    var prices []DailyPrice

    // Use the continuous aggregate
    err := r.db.WithContext(ctx).
        Table("daily_prices").
        Where("offer_id = ? AND day > NOW() - INTERVAL '? days'", offerID, days).
        Order("day DESC").
        Find(&prices).Error

    return prices, err
}

func (r *priceRepo) GetLatest(ctx context.Context, offerID uuid.UUID) (*models.Price, error) {
    var price models.Price
    err := r.db.WithContext(ctx).
        Where("offer_id = ?", offerID).
        Order("time DESC").
        First(&price).Error
    if err != nil {
        return nil, err
    }
    return &price, nil
}
```

## Caching Layer

```go
// apps/api/internal/catalog/cache/redis.go
package cache

import (
    "context"
    "encoding/json"
    "time"
    "github.com/redis/go-redis/v9"
)

type Cache interface {
    Get(ctx context.Context, key string, dest interface{}) error
    Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error
    Delete(ctx context.Context, keys ...string) error
}

type redisCache struct {
    client *redis.Client
}

func NewRedisCache(client *redis.Client) Cache {
    return &redisCache{client: client}
}

func (c *redisCache) Get(ctx context.Context, key string, dest interface{}) error {
    data, err := c.client.Get(ctx, key).Bytes()
    if err != nil {
        return err
    }
    return json.Unmarshal(data, dest)
}

func (c *redisCache) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
    data, err := json.Marshal(value)
    if err != nil {
        return err
    }
    return c.client.Set(ctx, key, data, ttl).Err()
}

func (c *redisCache) Delete(ctx context.Context, keys ...string) error {
    return c.client.Del(ctx, keys...).Err()
}
```

## Deliverables

- [ ] GORM models implemented
- [ ] ProductRepository with search
- [ ] OfferRepository with upsert
- [ ] PriceRepository with TimescaleDB
- [ ] Redis caching layer
- [ ] Unit tests >80% coverage

---

**Previous Phase**: [01-schema.md](./01-schema.md)
**Next Phase**: [03-internal-api.md](./03-internal-api.md)
**Back to**: [Catalog README](./README.md)
