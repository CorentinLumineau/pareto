# Phase 01: Database Schema

> **PostgreSQL tables, indexes, and TimescaleDB setup**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      01 - Database Schema                              ║
║  Initiative: Catalog                                           ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Design and implement the database schema for products, offers, and price history.

## Tasks

- [ ] Create database migration system
- [ ] Implement products table
- [ ] Implement offers table
- [ ] Setup TimescaleDB for prices
- [ ] Create indexes for performance
- [ ] Add full-text search

## Schema Migrations

```sql
-- migrations/001_create_products.sql

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For fuzzy search

-- Categories table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    parent_id UUID REFERENCES categories(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ean VARCHAR(13) UNIQUE,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(200) NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id),
    attributes JSONB DEFAULT '{}',
    fingerprint VARCHAR(200),  -- For matching
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for products
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_model ON products(model);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_fingerprint ON products(fingerprint);
CREATE INDEX idx_products_ean ON products(ean) WHERE ean IS NOT NULL;

-- Full-text search
CREATE INDEX idx_products_title_trgm ON products
    USING gin(title gin_trgm_ops);
CREATE INDEX idx_products_search ON products
    USING gin(to_tsvector('french', title || ' ' || COALESCE(brand, '') || ' ' || COALESCE(model, '')));
```

```sql
-- migrations/002_create_offers.sql

-- Retailers reference
CREATE TABLE retailers (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    domain VARCHAR(200) NOT NULL,
    affiliate_network VARCHAR(50),
    rate_limit_ms INTEGER DEFAULT 2000,
    active BOOLEAN DEFAULT true
);

-- Insert initial retailers
INSERT INTO retailers (id, name, domain, affiliate_network, rate_limit_ms) VALUES
    ('amazon_fr', 'Amazon France', 'amazon.fr', 'amazon', 2000),
    ('fnac', 'Fnac', 'fnac.com', 'awin', 3000),
    ('cdiscount', 'Cdiscount', 'cdiscount.com', 'effinity', 3000),
    ('darty', 'Darty', 'darty.com', 'awin', 2000),
    ('boulanger', 'Boulanger', 'boulanger.com', 'awin', 1000),
    ('ldlc', 'LDLC', 'ldlc.com', 'awin', 1000);

-- Offers table
CREATE TABLE offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    retailer_id VARCHAR(50) NOT NULL REFERENCES retailers(id),
    external_id VARCHAR(100) NOT NULL,
    url VARCHAR(2000) NOT NULL,
    affiliate_url VARCHAR(2000),
    in_stock BOOLEAN DEFAULT true,
    last_price DECIMAL(10,2),
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(retailer_id, external_id)
);

-- Indexes for offers
CREATE INDEX idx_offers_product ON offers(product_id);
CREATE INDEX idx_offers_retailer ON offers(retailer_id);
CREATE INDEX idx_offers_last_seen ON offers(last_seen_at);
CREATE INDEX idx_offers_in_stock ON offers(in_stock) WHERE in_stock = true;
```

```sql
-- migrations/003_create_prices.sql

-- Enable TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Prices table (will be hypertable)
CREATE TABLE prices (
    time TIMESTAMPTZ NOT NULL,
    offer_id UUID NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    was_price DECIMAL(10,2),  -- Crossed out price
    shipping_price DECIMAL(10,2)
);

-- Convert to TimescaleDB hypertable
SELECT create_hypertable('prices', 'time');

-- Indexes for prices
CREATE INDEX idx_prices_offer ON prices(offer_id, time DESC);

-- Compression policy (after 7 days)
ALTER TABLE prices SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'offer_id'
);
SELECT add_compression_policy('prices', INTERVAL '7 days');

-- Retention policy (keep 1 year)
SELECT add_retention_policy('prices', INTERVAL '1 year');

-- Continuous aggregate for daily prices
CREATE MATERIALIZED VIEW daily_prices
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS day,
    offer_id,
    first(price, time) AS open_price,
    last(price, time) AS close_price,
    min(price) AS min_price,
    max(price) AS max_price
FROM prices
GROUP BY day, offer_id
WITH NO DATA;

-- Refresh policy
SELECT add_continuous_aggregate_policy('daily_prices',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour'
);
```

## Go Migration Tool

```go
// apps/api/internal/catalog/migrations/migrate.go
package migrations

import (
    "embed"
    "github.com/golang-migrate/migrate/v4"
    _ "github.com/golang-migrate/migrate/v4/database/postgres"
    "github.com/golang-migrate/migrate/v4/source/iofs"
)

//go:embed *.sql
var migrations embed.FS

func RunMigrations(databaseURL string) error {
    source, err := iofs.New(migrations, ".")
    if err != nil {
        return err
    }

    m, err := migrate.NewWithSourceInstance("iofs", source, databaseURL)
    if err != nil {
        return err
    }

    if err := m.Up(); err != nil && err != migrate.ErrNoChange {
        return err
    }

    return nil
}
```

## Sample Queries

```sql
-- Get product with best price
SELECT
    p.id, p.title, p.brand, p.model,
    MIN(o.last_price) as best_price,
    COUNT(o.id) as offer_count
FROM products p
JOIN offers o ON o.product_id = p.id
WHERE o.in_stock = true
GROUP BY p.id
ORDER BY best_price ASC
LIMIT 20;

-- Price history for last 30 days
SELECT
    time_bucket('1 day', time) as day,
    AVG(price) as avg_price,
    MIN(price) as min_price,
    MAX(price) as max_price
FROM prices
WHERE offer_id = $1
  AND time > NOW() - INTERVAL '30 days'
GROUP BY day
ORDER BY day;

-- Full-text search
SELECT id, title, brand,
    ts_rank(to_tsvector('french', title), query) as rank
FROM products,
    plainto_tsquery('french', $1) query
WHERE to_tsvector('french', title) @@ query
ORDER BY rank DESC
LIMIT 20;
```

## Deliverables

- [ ] Migration files created
- [ ] TimescaleDB configured
- [ ] Indexes optimized
- [ ] Full-text search working
- [ ] Sample data inserted
- [ ] Query performance tested

---

**Next Phase**: [02-repository.md](./02-repository.md)
**Back to**: [Catalog README](./README.md)
