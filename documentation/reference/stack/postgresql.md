# PostgreSQL 18 - Primary Database

> **Relational database with TimescaleDB for time-series data**

## Version Info

| Attribute | Value |
|-----------|-------|
| **Version** | 18.1 |
| **Release** | November 2025 |
| **EOL** | November 2030 |
| **TimescaleDB** | 2.23.0 |

## PostgreSQL 18 Key Features

### UUIDv7 Native Support

```sql
-- PostgreSQL 18: Native UUIDv7 generation
-- Time-ordered, sortable UUIDs
CREATE TABLE products (
    id UUID DEFAULT uuidv7() PRIMARY KEY,
    slug VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(500) NOT NULL,
    brand VARCHAR(255),
    category_id UUID REFERENCES categories(id),
    attributes JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- UUIDv7 benefits:
-- 1. Time-ordered (better index performance)
-- 2. No coordination needed (unlike sequences)
-- 3. Sortable by creation time
```

### 3x I/O Performance Improvements

```sql
-- PostgreSQL 18 has significantly improved:
-- - Parallel query execution
-- - Vacuum performance
-- - Index-only scans

-- Enable parallel query for complex aggregations
SET max_parallel_workers_per_gather = 4;

-- Analyze query performance
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    p.id,
    p.name,
    COUNT(o.id) as offer_count,
    MIN(o.price) as min_price
FROM products p
LEFT JOIN offers o ON o.product_id = p.id
WHERE p.category_id = 'smartphones'
GROUP BY p.id
ORDER BY min_price;
```

### Virtual Generated Columns

```sql
-- PostgreSQL 18: Virtual columns computed on read
ALTER TABLE products
ADD COLUMN search_vector tsvector
GENERATED ALWAYS AS (
    setweight(to_tsvector('french', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('french', coalesce(brand, '')), 'B')
) STORED;

-- Create index for full-text search
CREATE INDEX idx_products_search ON products USING GIN(search_vector);
```

## Database Schema

### Core Tables

```sql
-- Categories
CREATE TABLE categories (
    id UUID DEFAULT uuidv7() PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    parent_id UUID REFERENCES categories(id),
    attributes_schema JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Products
CREATE TABLE products (
    id UUID DEFAULT uuidv7() PRIMARY KEY,
    slug VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(500) NOT NULL,
    brand VARCHAR(255),
    category_id UUID NOT NULL REFERENCES categories(id),
    gtin VARCHAR(14),  -- EAN/UPC barcode
    attributes JSONB DEFAULT '{}',
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('french', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('french', coalesce(brand, '')), 'B')
    ) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Retailers
CREATE TABLE retailers (
    id UUID DEFAULT uuidv7() PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) NOT NULL,
    affiliate_network VARCHAR(100),
    affiliate_id VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    config JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Offers (current offers from retailers)
CREATE TABLE offers (
    id UUID DEFAULT uuidv7() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    retailer_id UUID NOT NULL REFERENCES retailers(id),
    url TEXT NOT NULL,
    affiliate_url TEXT,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    condition VARCHAR(50) DEFAULT 'new',  -- new, refurbished, used
    availability VARCHAR(50) DEFAULT 'in_stock',
    shipping_cost DECIMAL(10, 2),
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(product_id, retailer_id, condition)
);

-- Indexes
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_gtin ON products(gtin) WHERE gtin IS NOT NULL;
CREATE INDEX idx_products_search ON products USING GIN(search_vector);

CREATE INDEX idx_offers_product ON offers(product_id);
CREATE INDEX idx_offers_retailer ON offers(retailer_id);
CREATE INDEX idx_offers_price ON offers(product_id, price);
CREATE INDEX idx_offers_last_seen ON offers(last_seen_at);
```

### TimescaleDB for Price History

```sql
-- Enable TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Price history hypertable
CREATE TABLE price_history (
    time TIMESTAMPTZ NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    retailer_id UUID NOT NULL REFERENCES retailers(id),
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    condition VARCHAR(50) DEFAULT 'new'
);

-- Convert to hypertable (partitioned by time)
SELECT create_hypertable('price_history', 'time');

-- Add compression policy (compress chunks older than 7 days)
ALTER TABLE price_history SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'product_id,retailer_id'
);

SELECT add_compression_policy('price_history', INTERVAL '7 days');

-- Add retention policy (keep 2 years of data)
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
    AVG(price)::DECIMAL(10, 2) AS avg_price
FROM price_history
GROUP BY day, product_id, retailer_id;

-- Refresh policy for continuous aggregate
SELECT add_continuous_aggregate_policy('daily_prices',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour'
);
```

### Comparison Results

```sql
-- Store Pareto comparison results
CREATE TABLE comparison_results (
    id UUID DEFAULT uuidv7() PRIMARY KEY,
    session_id VARCHAR(100),
    product_ids UUID[] NOT NULL,
    objectives JSONB NOT NULL,
    results JSONB NOT NULL,
    pareto_frontier UUID[] NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comparisons_session ON comparison_results(session_id);
CREATE INDEX idx_comparisons_created ON comparison_results(created_at DESC);

-- Example objectives JSON:
-- [
--   {"name": "price", "sense": "min", "weight": 2},
--   {"name": "performance", "sense": "max", "weight": 1}
-- ]
```

## Queries

### Product Search

```sql
-- Full-text search with ranking
SELECT
    id,
    slug,
    name,
    brand,
    ts_rank(search_vector, query) AS rank
FROM products, plainto_tsquery('french', $1) query
WHERE search_vector @@ query
ORDER BY rank DESC
LIMIT 20;

-- Function for search
CREATE OR REPLACE FUNCTION search_products(
    search_query TEXT,
    category_slug TEXT DEFAULT NULL,
    limit_count INT DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    slug VARCHAR,
    name VARCHAR,
    brand VARCHAR,
    min_price DECIMAL,
    offer_count BIGINT,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.slug,
        p.name,
        p.brand,
        MIN(o.price) AS min_price,
        COUNT(o.id) AS offer_count,
        ts_rank(p.search_vector, query) AS rank
    FROM products p
    LEFT JOIN offers o ON o.product_id = p.id AND o.availability = 'in_stock'
    LEFT JOIN categories c ON c.id = p.category_id,
    plainto_tsquery('french', search_query) query
    WHERE p.search_vector @@ query
      AND (category_slug IS NULL OR c.slug = category_slug)
    GROUP BY p.id, p.slug, p.name, p.brand, p.search_vector, query
    ORDER BY rank DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;
```

### Price History

```sql
-- Get price history for a product
SELECT
    time_bucket('1 day', time) AS day,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price)::DECIMAL(10, 2) AS avg_price
FROM price_history
WHERE product_id = $1
  AND time > NOW() - INTERVAL '90 days'
GROUP BY day
ORDER BY day;

-- Get price drop alerts
SELECT
    p.id,
    p.name,
    ph.retailer_id,
    r.name AS retailer_name,
    ph.price AS current_price,
    yesterday.avg_price AS yesterday_price,
    ((yesterday.avg_price - ph.price) / yesterday.avg_price * 100)::DECIMAL(5, 2) AS drop_percent
FROM price_history ph
JOIN products p ON p.id = ph.product_id
JOIN retailers r ON r.id = ph.retailer_id
JOIN daily_prices yesterday ON
    yesterday.product_id = ph.product_id
    AND yesterday.retailer_id = ph.retailer_id
    AND yesterday.day = time_bucket('1 day', NOW() - INTERVAL '1 day')
WHERE ph.time > NOW() - INTERVAL '1 hour'
  AND ph.price < yesterday.avg_price * 0.9  -- 10%+ drop
ORDER BY drop_percent DESC;
```

### Offers with Ranking

```sql
-- Get offers for a product with Pareto-like ranking
SELECT
    o.id,
    o.price,
    o.condition,
    o.availability,
    o.shipping_cost,
    r.name AS retailer_name,
    r.slug AS retailer_slug,
    o.affiliate_url,
    -- Simple score: lower price + free shipping = better
    (o.price + COALESCE(o.shipping_cost, 0)) AS total_cost
FROM offers o
JOIN retailers r ON r.id = o.retailer_id
WHERE o.product_id = $1
  AND o.availability = 'in_stock'
ORDER BY total_cost ASC;
```

## JSONB Operations

```sql
-- Query JSONB attributes
SELECT * FROM products
WHERE attributes->>'storage' = '256GB'
  AND (attributes->>'ram')::INT >= 8;

-- Update JSONB attributes
UPDATE products
SET attributes = attributes || '{"color": "black"}'::jsonb
WHERE id = $1;

-- Remove JSONB key
UPDATE products
SET attributes = attributes - 'old_key'
WHERE id = $1;

-- JSONB index for common queries
CREATE INDEX idx_products_attrs_storage ON products((attributes->>'storage'));
CREATE INDEX idx_products_attrs ON products USING GIN(attributes);
```

## Functions & Triggers

```sql
-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER offers_updated_at
    BEFORE UPDATE ON offers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Record price history on offer update
CREATE OR REPLACE FUNCTION record_price_history()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.price IS DISTINCT FROM NEW.price THEN
        INSERT INTO price_history (time, product_id, retailer_id, price, condition)
        VALUES (NOW(), NEW.product_id, NEW.retailer_id, NEW.price, NEW.condition);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER offers_price_history
    AFTER UPDATE ON offers
    FOR EACH ROW
    EXECUTE FUNCTION record_price_history();
```

## Connection with pgx (Go)

```go
// internal/shared/database/postgres.go
package database

import (
    "context"
    "fmt"
    "time"

    "github.com/jackc/pgx/v5/pgxpool"
)

func NewPool(ctx context.Context, dsn string) (*pgxpool.Pool, error) {
    config, err := pgxpool.ParseConfig(dsn)
    if err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }

    // Pool settings
    config.MaxConns = 25
    config.MinConns = 5
    config.MaxConnLifetime = time.Hour
    config.MaxConnIdleTime = 30 * time.Minute
    config.HealthCheckPeriod = time.Minute

    pool, err := pgxpool.NewWithConfig(ctx, config)
    if err != nil {
        return nil, fmt.Errorf("create pool: %w", err)
    }

    if err := pool.Ping(ctx); err != nil {
        return nil, fmt.Errorf("ping: %w", err)
    }

    return pool, nil
}
```

## Migrations

```sql
-- migrations/001_initial.up.sql
BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create tables...

COMMIT;

-- migrations/001_initial.down.sql
BEGIN;

DROP TABLE IF EXISTS price_history;
DROP TABLE IF EXISTS offers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS retailers;
DROP TABLE IF EXISTS categories;

COMMIT;
```

## Docker Configuration

```yaml
# docker-compose.yml
services:
  postgres:
    image: timescale/timescaledb:latest-pg18
    container_name: pareto-postgres
    environment:
      POSTGRES_USER: pareto
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: pareto
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pareto"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

## Commands

```bash
# Connect to database
psql -h localhost -U pareto -d pareto

# Run migrations
migrate -path ./migrations -database "postgres://pareto:pass@localhost:5432/pareto?sslmode=disable" up

# Backup
pg_dump -h localhost -U pareto pareto > backup.sql

# Restore
psql -h localhost -U pareto pareto < backup.sql

# TimescaleDB: Check hypertable info
SELECT * FROM timescaledb_information.hypertables;

# TimescaleDB: Check compression
SELECT * FROM timescaledb_information.compression_settings;
```

---

**See Also**:
- [TimescaleDB Docs](https://docs.timescale.com/)
- [Redis](./redis.md)
- [Go pgx](https://github.com/jackc/pgx)
