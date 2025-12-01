# Data Architecture - Multi-Tenant Scaling

> **Database architecture for scalable multi-tenancy**

## Overview

Pareto's data architecture evolves to support:
- Multi-country data isolation
- Multi-organization tenancy (B2B)
- White-label deployments
- Horizontal data scaling

## Data Model Evolution

```
                    DATA MODEL EVOLUTION

    MVP (Single-Tenant)         Growth (Country-Aware)      Scale (Multi-Tenant)
    ───────────────────         ──────────────────────      ────────────────────

    products                    products                    products
    ├─ id                       ├─ id                       ├─ id
    ├─ name                     ├─ country_code  ←──NEW     ├─ organization_id ←──NEW
    ├─ attributes               ├─ name                     ├─ country_code
    └─ ...                      ├─ attributes               ├─ name
                                └─ ...                      ├─ attributes
                                                            └─ ...

    offers                      offers                      offers
    ├─ product_id               ├─ product_id               ├─ id
    ├─ retailer                 ├─ retailer_id  ←──FK       ├─ organization_id
    ├─ price                    ├─ price                    ├─ product_id
    └─ url                      ├─ currency     ←──NEW      ├─ retailer_id
                                └─ url                      ├─ price
                                                            ├─ currency
                                                            └─ affiliate_url
```

## Core Schema

### Organizations (Multi-Tenancy)

```sql
-- Organizations table (B2B multi-tenancy)
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    tier TEXT NOT NULL DEFAULT 'free',

    -- Configuration
    settings JSONB DEFAULT '{}',
    branding JSONB DEFAULT '{}',

    -- Affiliate override for white-label
    affiliate_override BOOLEAN DEFAULT false,
    affiliate_config JSONB DEFAULT '{}',

    -- Limits
    api_rate_limit INTEGER DEFAULT 100,
    max_products INTEGER DEFAULT 10000,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default organization for consumer app
INSERT INTO organizations (id, slug, name, tier)
VALUES ('00000000-0000-0000-0000-000000000001', 'pareto', 'Pareto Consumer', 'enterprise');
```

### Countries & Currencies

```sql
-- Countries
CREATE TABLE countries (
    code CHAR(2) PRIMARY KEY,  -- ISO 3166-1 alpha-2
    name TEXT NOT NULL,
    currency_code CHAR(3) NOT NULL,
    locale TEXT NOT NULL,
    timezone TEXT NOT NULL,
    enabled BOOLEAN DEFAULT false,
    config JSONB DEFAULT '{}'
);

-- Currencies with exchange rates
CREATE TABLE currencies (
    code CHAR(3) PRIMARY KEY,  -- ISO 4217
    name TEXT NOT NULL,
    symbol TEXT NOT NULL,
    rate_to_eur DECIMAL(10,6) NOT NULL DEFAULT 1.0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Initial data
INSERT INTO countries VALUES
    ('FR', 'France', 'EUR', 'fr-FR', 'Europe/Paris', true, '{}'),
    ('DE', 'Germany', 'EUR', 'de-DE', 'Europe/Berlin', false, '{}'),
    ('GB', 'United Kingdom', 'GBP', 'en-GB', 'Europe/London', false, '{}');

INSERT INTO currencies VALUES
    ('EUR', 'Euro', '€', 1.000000, NOW()),
    ('GBP', 'British Pound', '£', 1.170000, NOW()),
    ('USD', 'US Dollar', '$', 0.920000, NOW());
```

### Categories (Vertical Expansion)

```sql
-- Categories with schema-driven attributes
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    parent_id UUID REFERENCES categories(id),
    name TEXT NOT NULL,

    -- JSON Schema for product attributes
    attribute_schema JSONB NOT NULL,

    -- Pareto comparison config
    comparison_objectives JSONB NOT NULL,

    -- Display config
    display_config JSONB DEFAULT '{}',

    -- Metadata
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example: Smartphones category
INSERT INTO categories (slug, name, attribute_schema, comparison_objectives) VALUES
('smartphones', 'Smartphones', '{
  "type": "object",
  "required": ["screen_size", "storage", "ram", "battery"],
  "properties": {
    "screen_size": {"type": "number", "unit": "inches"},
    "storage": {"type": "integer", "unit": "GB"},
    "ram": {"type": "integer", "unit": "GB"},
    "battery": {"type": "integer", "unit": "mAh"}
  }
}', '[
  {"name": "price", "sense": "min", "weight": 1.5},
  {"name": "storage", "sense": "max", "weight": 1.0},
  {"name": "battery", "sense": "max", "weight": 1.0}
]');
```

### Retailers (Per-Country)

```sql
-- Retailers are country-specific
CREATE TABLE retailers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code CHAR(2) NOT NULL REFERENCES countries(code),
    slug TEXT NOT NULL,
    name TEXT NOT NULL,
    base_url TEXT NOT NULL,

    -- Affiliate configuration
    affiliate_program TEXT,
    affiliate_config JSONB DEFAULT '{}',

    -- Scraping configuration
    scraper_config JSONB DEFAULT '{}',

    -- Status
    enabled BOOLEAN DEFAULT true,
    last_scraped_at TIMESTAMPTZ,

    UNIQUE(country_code, slug)
);

-- French retailers
INSERT INTO retailers (country_code, slug, name, base_url, affiliate_program) VALUES
    ('FR', 'amazon_fr', 'Amazon France', 'https://www.amazon.fr', 'amazon_associates'),
    ('FR', 'fnac', 'Fnac', 'https://www.fnac.com', 'awin'),
    ('FR', 'darty', 'Darty', 'https://www.darty.com', 'awin'),
    ('FR', 'boulanger', 'Boulanger', 'https://www.boulanger.com', 'tradedoubler');
```

### Products (Multi-Tenant)

```sql
-- Products with organization isolation
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Multi-tenancy
    organization_id UUID NOT NULL REFERENCES organizations(id)
        DEFAULT '00000000-0000-0000-0000-000000000001',

    -- Core fields
    category_id UUID NOT NULL REFERENCES categories(id),
    name TEXT NOT NULL,
    brand TEXT,
    model TEXT,
    ean TEXT,  -- EAN-13 barcode

    -- Flexible attributes (JSONB)
    attributes JSONB NOT NULL DEFAULT '{}',

    -- Images
    image_url TEXT,
    images JSONB DEFAULT '[]',

    -- Search optimization
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(name, '') || ' ' || coalesce(brand, ''))
    ) STORED,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_products_org ON products(organization_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_ean ON products(ean) WHERE ean IS NOT NULL;
CREATE INDEX idx_products_search ON products USING gin(search_vector);
```

### Offers (Prices)

```sql
-- Current offers (live prices)
CREATE TABLE offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id)
        DEFAULT '00000000-0000-0000-0000-000000000001',
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    retailer_id UUID NOT NULL REFERENCES retailers(id),

    -- Pricing
    price DECIMAL(10,2) NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'EUR',
    original_price DECIMAL(10,2),  -- Before discount

    -- Offer details
    condition TEXT DEFAULT 'new',  -- new, refurbished, used
    availability TEXT DEFAULT 'in_stock',
    shipping_cost DECIMAL(10,2),

    -- URLs
    url TEXT NOT NULL,
    affiliate_url TEXT,

    -- Metadata
    scraped_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(organization_id, product_id, retailer_id, condition)
);

-- Indexes
CREATE INDEX idx_offers_product ON offers(product_id);
CREATE INDEX idx_offers_retailer ON offers(retailer_id);
CREATE INDEX idx_offers_price ON offers(price);
```

### Price History (TimescaleDB)

```sql
-- Historical prices (TimescaleDB hypertable)
CREATE TABLE price_history (
    time TIMESTAMPTZ NOT NULL,
    product_id UUID NOT NULL,
    retailer_id UUID NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    condition TEXT DEFAULT 'new'
);

-- Convert to hypertable
SELECT create_hypertable('price_history', 'time');

-- Compression policy (after 7 days)
ALTER TABLE price_history SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'product_id, retailer_id'
);
SELECT add_compression_policy('price_history', INTERVAL '7 days');

-- Retention policy (keep 2 years)
SELECT add_retention_policy('price_history', INTERVAL '2 years');

-- Continuous aggregate for daily prices
CREATE MATERIALIZED VIEW daily_prices
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS day,
    product_id,
    retailer_id,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price,
    LAST(price, time) AS close_price
FROM price_history
GROUP BY time_bucket('1 day', time), product_id, retailer_id;
```

## Row-Level Security (RLS)

```sql
-- Enable RLS on all tenant tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE offers ENABLE ROW LEVEL SECURITY;

-- Policy: Users see only their organization's data
CREATE POLICY org_isolation_products ON products
    FOR ALL
    USING (organization_id = current_setting('app.organization_id', true)::uuid);

CREATE POLICY org_isolation_offers ON offers
    FOR ALL
    USING (organization_id = current_setting('app.organization_id', true)::uuid);

-- Consumer app sees default organization
-- B2B clients see their own organization
```

### Application Usage

```go
// apps/api/internal/db/context.go
func SetOrganizationContext(ctx context.Context, db *pgxpool.Pool, orgID uuid.UUID) error {
    _, err := db.Exec(ctx,
        "SET app.organization_id = $1",
        orgID.String(),
    )
    return err
}

// Middleware sets context per request
func OrganizationMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        orgID := getOrgFromAuth(r)
        ctx := r.Context()

        db := database.FromContext(ctx)
        if err := SetOrganizationContext(ctx, db, orgID); err != nil {
            http.Error(w, "Database error", http.StatusInternalServerError)
            return
        }

        next.ServeHTTP(w, r)
    })
}
```

## Partitioning Strategy

### By Country (Geographic Scaling)

```sql
-- Partition offers by country for geographic scaling
CREATE TABLE offers_partitioned (
    id UUID NOT NULL,
    organization_id UUID NOT NULL,
    product_id UUID NOT NULL,
    retailer_id UUID NOT NULL,
    country_code CHAR(2) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    url TEXT NOT NULL,
    affiliate_url TEXT,
    scraped_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (id, country_code)
) PARTITION BY LIST (country_code);

-- Create partitions per country
CREATE TABLE offers_fr PARTITION OF offers_partitioned FOR VALUES IN ('FR');
CREATE TABLE offers_de PARTITION OF offers_partitioned FOR VALUES IN ('DE');
CREATE TABLE offers_es PARTITION OF offers_partitioned FOR VALUES IN ('ES');
CREATE TABLE offers_gb PARTITION OF offers_partitioned FOR VALUES IN ('GB');
```

### By Organization (B2B Scaling)

```sql
-- For very large B2B customers, separate schemas
CREATE SCHEMA org_enterprise_customer;

-- Migrate data to dedicated schema
CREATE TABLE org_enterprise_customer.products AS
SELECT * FROM public.products WHERE organization_id = 'enterprise-customer-id';
```

## Caching Strategy

### Redis Data Structures

```yaml
# Cache hierarchy
cache:
  # Product cache (10 min TTL)
  products:
    key: "product:{org}:{id}"
    ttl: 600
    type: json

  # Price cache (5 min TTL, prices change frequently)
  prices:
    key: "prices:{org}:{product_id}"
    ttl: 300
    type: json

  # Pareto results (1 hour TTL)
  pareto:
    key: "pareto:{org}:{hash(product_ids)}:{hash(objectives)}"
    ttl: 3600
    type: json

  # Category tree (24 hour TTL)
  categories:
    key: "categories:{org}"
    ttl: 86400
    type: json

  # Search results (15 min TTL)
  search:
    key: "search:{org}:{category}:{hash(query)}"
    ttl: 900
    type: json
```

### Cache Invalidation

```go
// apps/api/internal/cache/invalidation.go
package cache

func InvalidateProduct(ctx context.Context, orgID, productID uuid.UUID) error {
    keys := []string{
        fmt.Sprintf("product:%s:%s", orgID, productID),
        fmt.Sprintf("prices:%s:%s", orgID, productID),
    }

    // Also invalidate any Pareto caches containing this product
    pattern := fmt.Sprintf("pareto:%s:*", orgID)
    paretoKeys, _ := redis.Keys(ctx, pattern).Result()
    keys = append(keys, paretoKeys...)

    return redis.Del(ctx, keys...).Err()
}

func InvalidateCategory(ctx context.Context, orgID uuid.UUID) error {
    return redis.Del(ctx, fmt.Sprintf("categories:%s", orgID)).Err()
}
```

## Backup & Recovery

### Backup Strategy

```yaml
# Backup configuration
backups:
  # Full backup daily
  full:
    schedule: "0 2 * * *"  # 2 AM daily
    retention: 30 days

  # Incremental backup hourly
  incremental:
    schedule: "0 * * * *"
    retention: 7 days

  # WAL archiving for PITR
  wal:
    enabled: true
    retention: 7 days

  # Storage
  storage:
    provider: S3-compatible
    bucket: pareto-backups
    encryption: AES-256
```

### Disaster Recovery

```bash
# Point-in-time recovery
pg_restore --target-time="2025-12-01 10:00:00" \
    --dbname=pareto_recovery \
    /backups/pareto_full.dump

# Verify and swap
# 1. Verify data integrity
# 2. Update DNS to recovery instance
# 3. Notify operations team
```

## Related Documentation

- [Infrastructure Scaling](./infrastructure-scaling.md) - VPS to K8s
- [Platform Expansion](./platform-expansion.md) - Multi-tenancy use cases
- [PostgreSQL Stack](../../reference/stack/postgresql.md) - Database details

---

**Last Updated**: 2025-12-01
