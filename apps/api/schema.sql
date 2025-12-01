-- Pareto Comparator Database Schema
-- Declarative schema managed by Atlas
-- Edit this file, then run: make db:diff name=<migration_name>

-- ============================================
-- Extensions
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For fuzzy text search

-- Note: TimescaleDB extension should be enabled manually on the database
-- CREATE EXTENSION IF NOT EXISTS "timescaledb";

-- ============================================
-- Categories
-- ============================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    description TEXT,
    image_url TEXT,
    -- JSONB schema for category-specific attributes
    -- e.g., {"screen_size": "number", "battery_mah": "number", "5g": "boolean"}
    attribute_schema JSONB DEFAULT '{}',
    sort_order INT DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_active ON categories(active) WHERE active = true;

-- ============================================
-- Retailers
-- ============================================
CREATE TABLE retailers (
    id TEXT PRIMARY KEY,  -- e.g., 'amazon_fr', 'fnac'
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    website_url TEXT NOT NULL,
    logo_url TEXT,
    -- Affiliate configuration
    affiliate_network TEXT,  -- 'awin', 'effiliation', 'tradedoubler'
    affiliate_id TEXT,
    affiliate_url_template TEXT,  -- URL template with {product_url} placeholder
    -- Scraping configuration
    rate_limit_ms INT DEFAULT 2000,
    anti_bot_level TEXT DEFAULT 'medium',  -- 'none', 'light', 'medium', 'heavy'
    -- Status
    active BOOLEAN DEFAULT true,
    priority INT DEFAULT 0,  -- Higher = more important
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_retailers_active ON retailers(active) WHERE active = true;
CREATE INDEX idx_retailers_priority ON retailers(priority DESC);

-- ============================================
-- Products (from brand websites)
-- ============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id),

    -- Basic info
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,

    -- Identifiers
    ean TEXT UNIQUE,  -- EAN-13 barcode (primary matching key)
    sku TEXT,         -- Brand's internal SKU

    -- Media
    image_url TEXT,
    images JSONB DEFAULT '[]',  -- Array of image URLs

    -- Complete specifications (40+ attributes from brand websites)
    -- Stored as JSONB for flexibility across categories
    attributes JSONB DEFAULT '{}',

    -- Source tracking
    source TEXT NOT NULL DEFAULT 'brand',  -- 'brand', 'manual', 'api'
    source_url TEXT,

    -- SEO & Display
    description TEXT,
    meta_title TEXT,
    meta_description TEXT,

    -- Status
    active BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    scraped_at TIMESTAMPTZ  -- Last time we fetched from source
);

-- Indexes for common queries
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_ean ON products(ean) WHERE ean IS NOT NULL;
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_products_active ON products(active) WHERE active = true;

-- GIN index for JSONB attribute queries
-- Enables queries like: attributes @> '{"5g": true}'
CREATE INDEX idx_products_attributes ON products USING GIN(attributes);

-- Trigram index for fuzzy name search
CREATE INDEX idx_products_name_trgm ON products USING GIN(name gin_trgm_ops);

-- ============================================
-- Product Variants (color, storage combinations)
-- ============================================
CREATE TABLE variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,

    -- Variant identifiers
    sku TEXT NOT NULL,
    ean TEXT UNIQUE,  -- Each variant has unique EAN

    -- Variant attributes
    color TEXT,
    color_hex TEXT,  -- e.g., '#1D1D1F'
    storage_gb INT,
    ram_gb INT,

    -- Additional variant-specific attributes
    attributes JSONB DEFAULT '{}',

    -- Media
    image_url TEXT,

    -- Official price (MSRP from brand)
    msrp DECIMAL(10, 2),
    currency TEXT DEFAULT 'EUR',

    -- Status
    active BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_variants_product ON variants(product_id);
CREATE INDEX idx_variants_ean ON variants(ean) WHERE ean IS NOT NULL;
CREATE INDEX idx_variants_color_storage ON variants(color, storage_gb);
CREATE UNIQUE INDEX idx_variants_product_sku ON variants(product_id, sku);

-- ============================================
-- Offers (marketplace prices)
-- ============================================
CREATE TABLE offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES variants(id) ON DELETE CASCADE,
    retailer_id TEXT NOT NULL REFERENCES retailers(id),

    -- Price info
    price DECIMAL(10, 2) NOT NULL,
    shipping DECIMAL(10, 2) DEFAULT 0,
    currency TEXT DEFAULT 'EUR',

    -- Sale info
    was_price DECIMAL(10, 2),  -- Original price if on sale
    discount_percent INT,      -- Calculated discount percentage

    -- Links
    url TEXT NOT NULL,              -- Original product page URL
    affiliate_url TEXT,             -- URL with affiliate tracking

    -- Availability
    in_stock BOOLEAN DEFAULT true,
    stock_quantity INT,            -- If available
    delivery_days INT,             -- Estimated delivery time

    -- Seller info (for marketplaces)
    seller_name TEXT,              -- e.g., "Vendu par Amazon"
    is_marketplace BOOLEAN DEFAULT false,  -- vs direct from retailer

    -- Timestamps
    scraped_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique constraint: one offer per product/variant/retailer
    UNIQUE(product_id, variant_id, retailer_id)
);

CREATE INDEX idx_offers_product ON offers(product_id);
CREATE INDEX idx_offers_variant ON offers(variant_id);
CREATE INDEX idx_offers_retailer ON offers(retailer_id);
CREATE INDEX idx_offers_price ON offers(price);
CREATE INDEX idx_offers_in_stock ON offers(in_stock) WHERE in_stock = true;
CREATE INDEX idx_offers_scraped_at ON offers(scraped_at DESC);

-- ============================================
-- Price History (for trends and alerts)
-- ============================================
CREATE TABLE price_history (
    time TIMESTAMPTZ NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES variants(id) ON DELETE CASCADE,
    retailer_id TEXT NOT NULL REFERENCES retailers(id),
    price DECIMAL(10, 2) NOT NULL,
    in_stock BOOLEAN DEFAULT true,

    PRIMARY KEY (time, product_id, retailer_id)
);

-- Note: Convert to TimescaleDB hypertable after creation:
-- SELECT create_hypertable('price_history', 'time');

CREATE INDEX idx_price_history_product ON price_history(product_id, time DESC);
CREATE INDEX idx_price_history_retailer ON price_history(retailer_id, time DESC);

-- ============================================
-- Scrape Jobs (for tracking scrape status)
-- ============================================
CREATE TABLE scrape_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Job type
    job_type TEXT NOT NULL,  -- 'brand_catalog', 'brand_product', 'price'

    -- Target
    retailer_id TEXT REFERENCES retailers(id),
    product_id UUID REFERENCES products(id),
    url TEXT,

    -- Status
    status TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'running', 'completed', 'failed'
    priority INT DEFAULT 0,

    -- Retry logic
    attempts INT DEFAULT 0,
    max_attempts INT DEFAULT 3,
    last_error TEXT,

    -- Timing
    scheduled_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    next_retry_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_scrape_jobs_status ON scrape_jobs(status, priority DESC, scheduled_at);
CREATE INDEX idx_scrape_jobs_retailer ON scrape_jobs(retailer_id);
CREATE INDEX idx_scrape_jobs_product ON scrape_jobs(product_id);
CREATE INDEX idx_scrape_jobs_next_retry ON scrape_jobs(next_retry_at)
    WHERE status = 'failed' AND attempts < max_attempts;

-- ============================================
-- Affiliate Clicks (for revenue tracking)
-- ============================================
CREATE TABLE affiliate_clicks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id UUID NOT NULL REFERENCES offers(id),
    product_id UUID NOT NULL REFERENCES products(id),
    retailer_id TEXT NOT NULL REFERENCES retailers(id),

    -- Click metadata
    user_agent TEXT,
    ip_hash TEXT,  -- Hashed for GDPR compliance
    referrer TEXT,

    -- Tracking
    click_id TEXT,  -- External tracking ID

    -- Timestamps
    clicked_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_affiliate_clicks_offer ON affiliate_clicks(offer_id);
CREATE INDEX idx_affiliate_clicks_product ON affiliate_clicks(product_id);
CREATE INDEX idx_affiliate_clicks_retailer ON affiliate_clicks(retailer_id);
CREATE INDEX idx_affiliate_clicks_date ON affiliate_clicks(clicked_at DESC);

-- ============================================
-- Functions & Triggers
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER trg_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_retailers_updated_at
    BEFORE UPDATE ON retailers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_variants_updated_at
    BEFORE UPDATE ON variants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_offers_updated_at
    BEFORE UPDATE ON offers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_scrape_jobs_updated_at
    BEFORE UPDATE ON scrape_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- Initial Seed Data
-- ============================================

-- Default category
INSERT INTO categories (id, name, slug, description, attribute_schema, active)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Smartphones',
    'smartphones',
    'Mobile phones and smartphones',
    '{
        "screen_size": {"type": "number", "unit": "inches"},
        "screen_resolution": {"type": "string"},
        "refresh_rate": {"type": "number", "unit": "Hz"},
        "cpu": {"type": "string"},
        "ram_gb": {"type": "number", "unit": "GB"},
        "storage_gb": {"type": "number", "unit": "GB"},
        "battery_mah": {"type": "number", "unit": "mAh"},
        "fast_charging_w": {"type": "number", "unit": "W"},
        "rear_camera_mp": {"type": "number", "unit": "MP"},
        "front_camera_mp": {"type": "number", "unit": "MP"},
        "5g": {"type": "boolean"},
        "nfc": {"type": "boolean"},
        "water_resistance": {"type": "string"},
        "weight_g": {"type": "number", "unit": "g"}
    }'::jsonb,
    true
) ON CONFLICT (slug) DO NOTHING;

-- Default retailers
INSERT INTO retailers (id, name, slug, website_url, affiliate_network, rate_limit_ms, anti_bot_level, active, priority)
VALUES
    ('amazon_fr', 'Amazon France', 'amazon-fr', 'https://www.amazon.fr', 'amazon', 2000, 'heavy', true, 100),
    ('fnac', 'Fnac', 'fnac', 'https://www.fnac.com', 'awin', 3000, 'heavy', true, 90),
    ('darty', 'Darty', 'darty', 'https://www.darty.com', 'awin', 2000, 'medium', true, 80),
    ('boulanger', 'Boulanger', 'boulanger', 'https://www.boulanger.com', 'awin', 1500, 'light', true, 70),
    ('cdiscount', 'Cdiscount', 'cdiscount', 'https://www.cdiscount.com', 'awin', 3000, 'heavy', true, 60),
    ('ldlc', 'LDLC', 'ldlc', 'https://www.ldlc.com', 'awin', 1500, 'light', true, 50)
ON CONFLICT (id) DO NOTHING;
