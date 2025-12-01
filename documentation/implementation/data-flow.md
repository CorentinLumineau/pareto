# Complete Data Flow - Scraping to UI Display

> **End-to-end data pipeline for Pareto Comparator**

## Overview

This document traces the complete journey of product data from retailer websites to user screens, ensuring:
1. **All hardware characteristics are captured** (JSONB flexibility)
2. **No reprocessing of known products** (entity resolution)
3. **Real-time price updates** without re-scraping attributes

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           COMPLETE DATA FLOW                                │
└─────────────────────────────────────────────────────────────────────────────┘

  RETAILER WEBSITES                    PARETO SYSTEM                    USER
  ─────────────────                    ─────────────                    ────

  ┌──────────────┐     ┌─────────────────────────────────────────────────┐
  │  Amazon.fr   │────▶│  1. SCRAPER (Go + Python curl_cffi)            │
  │  Fnac        │     │     • Anti-bot bypass (TLS fingerprinting)     │
  │  Darty       │     │     • Raw HTML capture                         │
  │  Boulanger   │     │     • Store in Redis (24hr debug TTL)          │
  │  Cdiscount   │     └─────────────────────────────────────────────────┘
  └──────────────┘                          │
                                            ▼
                       ┌─────────────────────────────────────────────────┐
                       │  2. NORMALIZER (Python BeautifulSoup)          │
                       │     • Extract ALL attributes                    │
                       │     • Retailer-specific parsers                 │
                       │     • Validate with Pydantic schemas            │
                       └─────────────────────────────────────────────────┘
                                            │
                                            ▼
                       ┌─────────────────────────────────────────────────┐
                       │  3. ENTITY RESOLVER (Go)                       │
                       │     • GTIN match (EAN-13) → 100% confidence    │
                       │     • SKU lookup → 100% confidence             │
                       │     • Fuzzy title → 85-95% confidence          │
                       │                                                 │
                       │  ┌─────────────────────────────────────────┐   │
                       │  │ KNOWN PRODUCT?                          │   │
                       │  │   YES → Update PRICE only (offers)      │   │
                       │  │   NO  → Create product + price          │   │
                       │  └─────────────────────────────────────────┘   │
                       └─────────────────────────────────────────────────┘
                                            │
                                            ▼
                       ┌─────────────────────────────────────────────────┐
                       │  4. STORAGE (PostgreSQL + TimescaleDB)         │
                       │                                                 │
                       │  products (created ONCE, attributes immutable) │
                       │  ├─ id, name, brand, ean                       │
                       │  ├─ attributes JSONB ← ALL characteristics     │
                       │  └─ category_id                                │
                       │                                                 │
                       │  offers (updated on EVERY scrape)              │
                       │  ├─ product_id, retailer_id                    │
                       │  ├─ price, currency, condition                 │
                       │  └─ scraped_at                                 │
                       │                                                 │
                       │  price_history (TimescaleDB hypertable)        │
                       │  └─ Compressed after 7 days, 2-year retention  │
                       └─────────────────────────────────────────────────┘
                                            │
                                            ▼
                       ┌─────────────────────────────────────────────────┐
                       │  5. COMPARISON ENGINE (Python paretoset)       │
                       │     • Fetch products + current prices          │
                       │     • Calculate Pareto frontier                │
                       │     • Z-score normalization                    │
                       │     • Cache results (Redis, 1hr TTL)           │
                       └─────────────────────────────────────────────────┘
                                            │
                                            ▼
                       ┌─────────────────────────────────────────────────┐
                       │  6. API LAYER (Go Chi router)                  │  ┌──────────┐
                       │     • REST endpoints                           │──▶│  Web UI  │
                       │     • Response caching                         │  │ (Next.js)│
                       │     • Affiliate link injection                 │  └──────────┘
                       └─────────────────────────────────────────────────┘        │
                                                                                  ▼
                                                                           ┌──────────┐
                                                                           │  Mobile  │
                                                                           │  (Expo)  │
                                                                           └──────────┘
```

## Stage 1: Scraping

### What Gets Scraped

```python
# Every retailer page captures:
class ScrapeResult:
    url: str              # Product page URL
    html: bytes           # FULL raw HTML (for re-parsing if needed)
    status_code: int      # HTTP status
    retailer_id: str      # amazon_fr, fnac, etc.
    scraped_at: datetime  # Timestamp
```

### Anti-Bot Strategy

| Retailer | Protection | Our Bypass |
|----------|------------|------------|
| Amazon.fr | DataDome | curl_cffi Chrome 136 + Residential proxy |
| Fnac | DataDome | curl_cffi Chrome 136 + Residential proxy |
| Cdiscount | Cloudflare | Rotating fingerprints + Residential proxy |
| Darty | Cloudflare | Chrome 120 + Datacenter proxy OK |
| Boulanger | Cloudflare | Chrome 120 + Datacenter proxy OK |

### Scraping Schedule

```yaml
schedules:
  # Price-sensitive: Every 4 hours
  price_check:
    retailers: [amazon_fr, fnac, cdiscount]
    interval: 4h
    scope: known_products_only  # No re-extraction

  # New product discovery: Daily
  catalog_scan:
    retailers: [all]
    interval: 24h
    scope: category_pages  # Find new products

  # Deep refresh: Weekly
  full_refresh:
    retailers: [all]
    interval: 7d
    scope: all_products  # Re-validate attributes
```

## Stage 2: Normalization (Attribute Extraction)

### What Gets Extracted

**EVERY attribute the retailer provides** is captured in JSONB:

```python
# Smartphone example - ALL fields stored
{
    # Core identifiers
    "ean": "0194253715214",           # EAN-13 barcode
    "mpn": "MU793ZD/A",               # Manufacturer part number
    "asin": "B0DGHY8DSR",             # Amazon-specific

    # Display
    "screen_size": 6.3,               # inches
    "screen_resolution": "2622x1206", # pixels
    "screen_technology": "OLED",
    "refresh_rate": 120,              # Hz
    "brightness_nits": 2000,

    # Performance
    "cpu": "Apple A18 Pro",
    "cpu_cores": 6,
    "ram": 8,                         # GB
    "storage": 256,                   # GB
    "storage_expandable": false,

    # Camera
    "rear_camera_mp": 48,
    "rear_camera_count": 3,
    "front_camera_mp": 12,
    "video_4k": true,
    "video_8k": false,

    # Battery
    "battery_mah": 4685,
    "fast_charging_w": 45,
    "wireless_charging": true,

    # Connectivity
    "5g": true,
    "wifi_version": "WiFi 7",
    "bluetooth": "5.3",
    "nfc": true,
    "usb_type": "USB-C",

    # Physical
    "weight_g": 199,
    "height_mm": 149.6,
    "width_mm": 71.5,
    "depth_mm": 8.25,
    "water_resistance": "IP68",
    "color": "Titanium Black",

    # Software
    "os": "iOS 18",
    "release_date": "2024-09-20",

    # Extras (anything else retailer shows)
    "face_id": true,
    "satellite_sos": true,
    "action_button": true
}
```

### Retailer-Specific Parsers

```python
# apps/workers/src/normalizer/extractors/amazon_fr.py
class AmazonFRExtractor(BaseExtractor):
    def extract_attributes(self, soup: BeautifulSoup) -> dict:
        attributes = {}

        # Technical specs table
        specs_table = soup.select_one("#productDetails_techSpec_section_1")
        if specs_table:
            for row in specs_table.select("tr"):
                key = self._normalize_key(row.select_one("th").text)
                value = self._parse_value(row.select_one("td").text)
                attributes[key] = value

        # Product features list
        features = soup.select("#feature-bullets li")
        for i, feature in enumerate(features):
            attributes[f"feature_{i}"] = feature.text.strip()

        return attributes
```

### Schema Validation

```python
# Category-specific validation ensures data quality
SMARTPHONE_SCHEMA = {
    "type": "object",
    "required": ["screen_size", "storage", "ram"],
    "properties": {
        "screen_size": {"type": "number", "minimum": 4, "maximum": 8},
        "storage": {"type": "integer", "enum": [64, 128, 256, 512, 1024]},
        "ram": {"type": "integer", "minimum": 4, "maximum": 24},
        "battery_mah": {"type": "integer", "minimum": 2000, "maximum": 10000}
    }
}

# Validation happens before storage
def validate_product(attributes: dict, category: str) -> bool:
    schema = get_schema_for_category(category)
    return jsonschema.validate(attributes, schema)
```

## Stage 3: Entity Resolution (Deduplication)

### The Critical Question: Is This Product Already Known?

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTITY RESOLUTION FLOW                       │
└─────────────────────────────────────────────────────────────────┘

    Incoming Product Data
           │
           ▼
    ┌──────────────────┐
    │ Has EAN/GTIN?    │──YES──▶ Search products.ean
    └──────────────────┘               │
           │                           ▼
           NO                    ┌───────────┐
           │                     │  FOUND?   │
           ▼                     └───────────┘
    ┌──────────────────┐              │
    │ Has Retailer SKU?│         YES  │  NO
    └──────────────────┘          │   │
           │                      │   ▼
          YES──▶ Search sku_mappings table
           │              │
           NO             ▼
           │        ┌───────────┐
           ▼        │  FOUND?   │
    ┌──────────────────┐ └───────────┘
    │ Fuzzy Title Match│      │
    │ (Brand + Model)  │  YES │  NO
    └──────────────────┘   │  │
           │               │  │
           ▼               │  │
    ┌───────────┐          │  │
    │ Score>95%?│          │  │
    └───────────┘          │  │
        │                  │  │
       YES                 │  │
        │                  │  │
        ▼                  ▼  ▼
    ┌─────────────────────────────────────────────────┐
    │              KNOWN PRODUCT                      │
    │  ─────────────────────────────────────────────  │
    │  • DO NOT update product attributes             │
    │  • DO NOT re-extract characteristics            │
    │  • ONLY update offers table (price, stock)      │
    │  • ONLY insert into price_history               │
    └─────────────────────────────────────────────────┘

        Score<95%
           │
           ▼
    ┌─────────────────────────────────────────────────┐
    │              NEW PRODUCT                        │
    │  ─────────────────────────────────────────────  │
    │  • CREATE product record with ALL attributes    │
    │  • CREATE offer record with price               │
    │  • INSERT into price_history                    │
    │  • Index for future matching                    │
    └─────────────────────────────────────────────────┘
```

### SQL Implementation

```sql
-- Find existing product by GTIN (fastest, most reliable)
SELECT id FROM products WHERE ean = $1 LIMIT 1;

-- Find by retailer SKU mapping
SELECT product_id FROM sku_mappings
WHERE retailer_id = $1 AND retailer_sku = $2 LIMIT 1;

-- When product IS found: Update price only
INSERT INTO offers (product_id, retailer_id, price, currency_code, url, scraped_at)
VALUES ($1, $2, $3, $4, $5, NOW())
ON CONFLICT (product_id, retailer_id, condition)
DO UPDATE SET
    price = EXCLUDED.price,
    url = EXCLUDED.url,
    scraped_at = NOW();

-- Also record in price history (TimescaleDB)
INSERT INTO price_history (time, product_id, retailer_id, price, currency_code)
VALUES (NOW(), $1, $2, $3, $4);

-- When product is NOT found: Create new
INSERT INTO products (category_id, name, brand, ean, attributes)
VALUES ($1, $2, $3, $4, $5::jsonb)
RETURNING id;
```

### Why This Matters

| Scenario | Products Table | Offers Table | Price History |
|----------|----------------|--------------|---------------|
| **New iPhone scrape** | INSERT (once) | INSERT | INSERT |
| **Same iPhone, 4h later** | NO CHANGE | UPDATE price | INSERT |
| **Same iPhone, next day** | NO CHANGE | UPDATE price | INSERT |
| **Price drop alert** | NO CHANGE | UPDATE price | INSERT |

**Result**: Product characteristics are extracted **ONCE** and never reprocessed.

## Stage 4: Storage

### Database Tables

```sql
-- PRODUCTS: Immutable after creation (except manual corrections)
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES categories(id),
    name TEXT NOT NULL,
    brand TEXT,
    model TEXT,
    ean TEXT UNIQUE,                    -- EAN-13 for dedup

    -- ALL characteristics stored here
    attributes JSONB NOT NULL DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()  -- Only for manual fixes
);

-- OFFERS: Updated on every scrape
CREATE TABLE offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id),
    retailer_id UUID NOT NULL REFERENCES retailers(id),

    -- Price data (updates frequently)
    price DECIMAL(10,2) NOT NULL,
    currency_code CHAR(3) DEFAULT 'EUR',
    original_price DECIMAL(10,2),       -- Before discount
    condition TEXT DEFAULT 'new',
    availability TEXT DEFAULT 'in_stock',

    -- Links
    url TEXT NOT NULL,
    affiliate_url TEXT,

    -- Timestamp
    scraped_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(product_id, retailer_id, condition)
);

-- PRICE_HISTORY: TimescaleDB hypertable for analytics
CREATE TABLE price_history (
    time TIMESTAMPTZ NOT NULL,
    product_id UUID NOT NULL,
    retailer_id UUID NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    currency_code CHAR(3) NOT NULL
);

SELECT create_hypertable('price_history', 'time');

-- Automatic compression after 7 days
SELECT add_compression_policy('price_history', INTERVAL '7 days');

-- Keep 2 years of history
SELECT add_retention_policy('price_history', INTERVAL '2 years');
```

### JSONB Attribute Queries

```sql
-- Find phones with specific attributes
SELECT name, brand, attributes->>'storage' as storage
FROM products
WHERE category_id = 'smartphones'
  AND (attributes->>'storage')::int >= 256
  AND (attributes->>'5g')::boolean = true
  AND (attributes->>'ram')::int >= 8;

-- Get all unique CPU models in category
SELECT DISTINCT attributes->>'cpu' as cpu
FROM products
WHERE category_id = 'smartphones';

-- Full-text search on attributes
SELECT * FROM products
WHERE attributes::text ILIKE '%A18 Pro%';
```

## Stage 5: Comparison Engine

### Pareto Calculation Flow

```python
# apps/workers/src/pareto/calculator.py

def compare_products(
    product_ids: list[str],
    objectives: list[Objective]
) -> ComparisonResult:
    """
    Calculate Pareto frontier for given products.

    Args:
        product_ids: UUIDs of products to compare
        objectives: Criteria with sense (min/max) and weights

    Returns:
        ComparisonResult with pareto/dominated sets and scores
    """

    # 1. Fetch products with CURRENT prices
    products = db.query("""
        SELECT
            p.id,
            p.name,
            p.attributes,
            MIN(o.price) as best_price  -- Best current price
        FROM products p
        JOIN offers o ON o.product_id = p.id
        WHERE p.id = ANY($1)
          AND o.availability = 'in_stock'
        GROUP BY p.id
    """, [product_ids])

    # 2. Build attribute matrix
    matrix = []
    for product in products:
        row = []
        for obj in objectives:
            if obj.name == 'price':
                value = float(product['best_price'])
            else:
                value = float(product['attributes'].get(obj.name, 0))
            row.append(value)
        matrix.append(row)

    # 3. Calculate Pareto frontier
    sense = [obj.sense == 'max' for obj in objectives]
    pareto_mask = paretoset(np.array(matrix), sense=sense)

    # 4. Calculate weighted scores (Z-score normalization)
    normalized = zscore(matrix, axis=0)
    scores = {}
    for i, product in enumerate(products):
        weighted_sum = sum(
            normalized[i][j] * objectives[j].weight
            for j in range(len(objectives))
        )
        scores[product['id']] = weighted_sum

    return ComparisonResult(
        pareto_ids=[p['id'] for i, p in enumerate(products) if pareto_mask[i]],
        dominated_ids=[p['id'] for i, p in enumerate(products) if not pareto_mask[i]],
        scores=scores
    )
```

### Caching Strategy

```python
# Cache key includes product set AND objectives
def build_cache_key(product_ids: list, objectives: list) -> str:
    sorted_ids = sorted(product_ids)
    ids_hash = hashlib.md5('|'.join(sorted_ids).encode()).hexdigest()[:8]
    obj_hash = hashlib.md5(json.dumps(objectives).encode()).hexdigest()[:8]
    return f"pareto:{ids_hash}:{obj_hash}"

# Check cache before calculation
cache_key = build_cache_key(product_ids, objectives)
cached = redis.get(cache_key)
if cached:
    return json.loads(cached)  # Sub-10ms response

# Calculate and cache for 1 hour
result = compare_products(product_ids, objectives)
redis.setex(cache_key, 3600, json.dumps(result))
```

## Stage 6: API & Frontend

### API Endpoints

```go
// Product listing with filters
GET /api/products?category=smartphones&brand=Apple&min_storage=128

// Single product with all offers
GET /api/products/{id}
Response:
{
    "id": "uuid",
    "name": "iPhone 16 Pro",
    "brand": "Apple",
    "attributes": { /* ALL characteristics */ },
    "offers": [
        {"retailer": "Amazon", "price": 1229, "url": "..."},
        {"retailer": "Fnac", "price": 1249, "url": "..."}
    ]
}

// Price history
GET /api/products/{id}/prices/history?days=30
Response:
{
    "product_id": "uuid",
    "history": [
        {"date": "2025-11-01", "amazon_fr": 1299, "fnac": 1279},
        {"date": "2025-11-15", "amazon_fr": 1249, "fnac": 1269},
        {"date": "2025-12-01", "amazon_fr": 1229, "fnac": 1249}
    ]
}

// Pareto comparison
POST /api/compare
Body: {
    "product_ids": ["uuid1", "uuid2", "uuid3"],
    "objectives": [
        {"name": "price", "sense": "min", "weight": 2},
        {"name": "battery_mah", "sense": "max", "weight": 1},
        {"name": "storage", "sense": "max", "weight": 1}
    ]
}
Response: {
    "pareto_ids": ["uuid1", "uuid3"],
    "dominated_ids": ["uuid2"],
    "scores": {"uuid1": 85.5, "uuid2": 62.3, "uuid3": 91.0}
}
```

### Frontend Display

```typescript
// apps/web/components/ProductCard.tsx
export function ProductCard({ product }: { product: Product }) {
    return (
        <div className="product-card">
            <img src={product.attributes.image_url} />
            <h3>{product.name}</h3>
            <p className="brand">{product.brand}</p>

            {/* Dynamic attributes based on category */}
            <div className="specs">
                {product.category === 'smartphones' && (
                    <>
                        <Spec label="Storage" value={`${product.attributes.storage}GB`} />
                        <Spec label="RAM" value={`${product.attributes.ram}GB`} />
                        <Spec label="Battery" value={`${product.attributes.battery_mah}mAh`} />
                        <Spec label="Screen" value={`${product.attributes.screen_size}"`} />
                    </>
                )}
            </div>

            {/* Best price from all retailers */}
            <div className="price">
                <span className="best-price">€{product.bestPrice}</span>
                <span className="retailer">chez {product.bestRetailer}</span>
            </div>

            {/* All offers */}
            <div className="offers">
                {product.offers.map(offer => (
                    <OfferRow key={offer.retailer} offer={offer} />
                ))}
            </div>
        </div>
    );
}
```

## Summary: Your Questions Answered

### Q1: Will we scrape ALL hardware characteristics?

**YES** - The JSONB `attributes` field stores EVERYTHING:
- Every spec the retailer shows
- No predefined schema limits
- Category validation ensures key fields exist
- Extra fields preserved for future use

### Q2: Will we avoid reprocessing known products?

**YES** - Entity resolution ensures:
- GTIN/EAN match → Price update only
- SKU match → Price update only
- High-confidence fuzzy match → Price update only
- Product attributes are IMMUTABLE after creation
- Only `offers` and `price_history` tables are updated on subsequent scrapes

### Data Freshness

| Data Type | Update Frequency | Storage |
|-----------|------------------|---------|
| Product attributes | Once (at discovery) | `products.attributes` |
| Current prices | Every 4 hours | `offers.price` |
| Price history | Every price change | `price_history` (TimescaleDB) |
| Pareto calculations | Cached 1 hour | Redis |

---

**Last Updated**: 2025-12-01
