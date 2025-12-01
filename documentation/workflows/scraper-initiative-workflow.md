# Scraper Initiative Workflow

> **Implementation plan for brand-first scraping strategy**

```
╔════════════════════════════════════════════════════════════════════════════╗
║  EPIC: Scraper Initiative (Brand-First)                                     ║
║  Total Effort: 12-14 days                                                   ║
║  Status: Ready for Implementation                                           ║
║  Dependencies: Foundation ✅                                                ║
╚════════════════════════════════════════════════════════════════════════════╝
```

## Overview

Implement the **brand-first scraping strategy**:
1. **Primary**: Scrape brand websites (Apple, Samsung, etc.) for complete product specs
2. **Secondary**: Scrape marketplaces (Amazon, Fnac, etc.) for prices only using EAN matching

## Existing Code

| Component | Status | Location |
|-----------|--------|----------|
| BaseExtractor | ✅ Exists | `apps/workers/src/normalizer/extractors/base.py` |
| AmazonExtractor | ✅ Exists | `apps/workers/src/normalizer/extractors/amazon.py` |
| Product domain | ✅ Exists | `apps/api/internal/catalog/domain/product.go` |
| Pareto calculator | ✅ Complete | `apps/workers/src/pareto/calculator.py` |
| Celery tasks | ✅ Configured | `apps/workers/src/tasks/` |

---

## Milestone 1: Database Schema + Fetcher (2 days)

### Phase 1: Database Schema (4h)

**Task 1.1: PostgreSQL migrations**
```bash
/x:implement "Create PostgreSQL migrations for products table with JSONB attributes, variants table with EAN/SKU, offers table for marketplace prices, and price_history hypertable. Use UUIDv7 for IDs. Location: apps/api/internal/shared/database/migrations/"
```

**Deliverables:**
- `apps/api/internal/shared/database/migrations/001_products.sql`
- `apps/api/internal/shared/database/migrations/002_variants.sql`
- `apps/api/internal/shared/database/migrations/003_offers.sql`
- `apps/api/internal/shared/database/migrations/004_price_history.sql`

**Task 1.2: Go repository implementation**
```bash
/x:implement "Create PostgreSQL repository for products with CRUD operations, JSONB attribute queries, and GTIN/EAN lookup. Use pgx for database driver. Include comprehensive tests. Location: apps/api/internal/catalog/repository/"
```

**Deliverables:**
- `apps/api/internal/catalog/repository/postgres.go`
- `apps/api/internal/catalog/repository/postgres_test.go`

### Phase 2: Python Fetcher (6h)

**Task 2.1: curl_cffi anti-bot client**
```bash
/x:implement "Create Python HTTP client using curl_cffi with chrome136 browser impersonation for anti-bot bypass. Include rate limiting per domain, retry with exponential backoff, and proxy support. Location: apps/workers/src/fetcher/"
```

**Deliverables:**
- `apps/workers/src/fetcher/__init__.py`
- `apps/workers/src/fetcher/client.py`
- `apps/workers/src/fetcher/rate_limiter.py`
- `tests/workers/test_fetcher.py`

---

## Milestone 2: Brand Extractors (5 days)

### Phase 1: Brand Extractor Base (4h)

**Task 1.1: Brand extractor interface**
```bash
/x:implement "Create BrandExtractor base class extending BaseExtractor for brand websites. Add BrandProduct dataclass with 40+ attributes, ProductVariant dataclass for color/storage/EAN combinations, and catalog extraction interface. Location: apps/workers/src/normalizer/extractors/"
```

**Deliverables:**
- `apps/workers/src/normalizer/extractors/brand_base.py`
- Updated `apps/workers/src/normalizer/extractors/__init__.py`

**Task 1.2: Product storage service**
```bash
/x:implement "Create Python service to store BrandProduct data via Go API. Include variant handling, EAN validation, and attribute normalization. Add Celery task for async product storage. Location: apps/workers/src/normalizer/"
```

**Deliverables:**
- `apps/workers/src/normalizer/storage.py`
- `apps/workers/src/normalizer/tasks.py`

### Phase 2: Apple Extractor (8h)

**Task 2.1: Apple catalog scraping**
```bash
/x:implement "Create AppleExtractor for apple.com/fr to scrape iPhone catalog. Extract product list from /shop/buy-iphone, parse JSON-LD structured data, and discover all product URLs. Include tests with fixture HTML. Location: apps/workers/src/normalizer/extractors/"
```

**Deliverables:**
- `apps/workers/src/normalizer/extractors/apple.py`
- `tests/workers/extractors/test_apple.py`
- `tests/workers/extractors/fixtures/apple_catalog.html`

**Task 2.2: Apple product detail extraction**
```bash
/x:implement "Extend AppleExtractor to extract full product specs from individual product pages. Parse tech specs section for 40+ attributes (screen, cpu, camera, battery, connectivity, dimensions). Extract all variants with EAN codes. Location: apps/workers/src/normalizer/extractors/apple.py"
```

**Deliverables:**
- Updated `apps/workers/src/normalizer/extractors/apple.py`
- `tests/workers/extractors/fixtures/apple_product.html`

### Phase 3: Samsung Extractor (6h)

**Task 3.1: Samsung extractor implementation**
```bash
/x:implement "Create SamsungExtractor for samsung.com/fr to scrape Galaxy smartphones. Extract catalog from /smartphones/tous-les-smartphones/, parse embedded JSON product data, and extract all variants with EAN. Include comprehensive attribute mapping. Location: apps/workers/src/normalizer/extractors/"
```

**Deliverables:**
- `apps/workers/src/normalizer/extractors/samsung.py`
- `tests/workers/extractors/test_samsung.py`

### Phase 4: Other Brand Extractors (8h)

**Task 4.1: Xiaomi extractor**
```bash
/x:implement "Create XiaomiExtractor for mi.com/fr to scrape Xiaomi/Redmi/Poco phones. Parse HTML product pages, extract specs from product detail sections. Location: apps/workers/src/normalizer/extractors/"
```

**Task 4.2: Google & OnePlus extractors**
```bash
/x:implement "Create GoogleExtractor for store.google.com/fr (Pixel phones) and OnePlusExtractor for oneplus.com/fr. Both use JSON-LD data. Keep implementation simple as these have fewer products. Location: apps/workers/src/normalizer/extractors/"
```

**Deliverables:**
- `apps/workers/src/normalizer/extractors/xiaomi.py`
- `apps/workers/src/normalizer/extractors/google.py`
- `apps/workers/src/normalizer/extractors/oneplus.py`
- Tests for each

---

## Milestone 3: Price Scrapers (4 days)

### Phase 1: Price Scraper Base (4h)

**Task 1.1: Price scraper interface**
```bash
/x:implement "Create PriceScraper base class for marketplace price-only scraping. Add PriceResult dataclass (retailer, price, url, stock, scraped_at). Implement EAN-based search interface and batch search for efficiency. Location: apps/workers/src/scraper/"
```

**Deliverables:**
- `apps/workers/src/scraper/__init__.py`
- `apps/workers/src/scraper/base.py`
- `apps/workers/src/scraper/models.py`

### Phase 2: Amazon Price Scraper (8h)

**Task 2.1: Amazon EAN search**
```bash
/x:implement "Create AmazonPriceScraper to search amazon.fr by EAN barcode. Use curl_cffi for anti-bot bypass. Extract price, stock status, and product URL from search results. Handle sponsored results and price variations. Location: apps/workers/src/scraper/"
```

**Deliverables:**
- `apps/workers/src/scraper/amazon.py`
- `tests/workers/scraper/test_amazon.py`

### Phase 3: Fnac + Darty Scrapers (8h)

**Task 3.1: Fnac price scraper**
```bash
/x:implement "Create FnacPriceScraper to search fnac.com by EAN. Handle DataDome anti-bot with appropriate rate limiting. Distinguish marketplace vs direct Fnac offers. Location: apps/workers/src/scraper/"
```

**Task 3.2: Darty price scraper**
```bash
/x:implement "Create DartyPriceScraper to search darty.com by EAN. Include stock status and store availability parsing. Location: apps/workers/src/scraper/"
```

**Deliverables:**
- `apps/workers/src/scraper/fnac.py`
- `apps/workers/src/scraper/darty.py`

### Phase 4: Remaining Scrapers (8h)

**Task 4.1: Boulanger, Cdiscount, LDLC**
```bash
/x:implement "Create price scrapers for Boulanger.com, Cdiscount.com, and LDLC.com. All use EAN search. Boulanger and LDLC have light protection. Cdiscount may have flash sale handling. Location: apps/workers/src/scraper/"
```

**Deliverables:**
- `apps/workers/src/scraper/boulanger.py`
- `apps/workers/src/scraper/cdiscount.py`
- `apps/workers/src/scraper/ldlc.py`

---

## Milestone 4: Job Queue & Scheduling (3 days)

### Phase 1: Redis Job Queue (6h)

**Task 1.1: Job queue infrastructure**
```bash
/x:implement "Create Redis-based job queue for scraping jobs. Implement Job entity with priority, retries, status tracking. Use go-redis for Go side. Jobs should be picked up by Python Celery workers. Location: apps/api/internal/scraper/"
```

**Deliverables:**
- `apps/api/internal/scraper/domain/job.go`
- `apps/api/internal/scraper/repository/redis.go`
- `apps/api/internal/scraper/service/queue.go`

### Phase 2: Go Scheduler (6h)

**Task 2.1: Periodic job scheduler**
```bash
/x:implement "Create Go scheduler service for periodic scraping jobs. Brand catalog scrape: weekly. Price scrape: every 4 hours for all products, hourly for popular products. Use cron-like scheduling. Location: apps/api/internal/scraper/"
```

**Deliverables:**
- `apps/api/internal/scraper/service/scheduler.go`
- `apps/api/cmd/scheduler/main.go`

### Phase 3: Retry + Monitoring (6h)

**Task 3.1: Retry logic with backoff**
```bash
/x:implement "Add exponential backoff retry logic to job queue. Track failure reasons, ban detection. Implement dead letter queue for persistently failing jobs. Add prometheus metrics for monitoring. Location: apps/api/internal/scraper/"
```

**Deliverables:**
- Updated `apps/api/internal/scraper/service/queue.go`
- `apps/api/internal/scraper/metrics.go`

---

## Dependency Graph

```
                    DATABASE SCHEMA
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    GO REPOSITORY    PYTHON FETCHER    JOB QUEUE
          │               │               │
          │               ▼               │
          │       BRAND EXTRACTOR BASE   │
          │               │               │
          │    ┌──────────┼──────────┐    │
          │    ▼          ▼          ▼    │
          │  APPLE    SAMSUNG    OTHERS   │
          │    │          │          │    │
          │    └──────────┼──────────┘    │
          │               │               │
          │               ▼               │
          │      PRICE SCRAPER BASE       │
          │               │               │
          │    ┌──────────┼──────────┐    │
          │    ▼          ▼          ▼    │
          │  AMAZON     FNAC     OTHERS   │
          │    │          │          │    │
          │    └──────────┼──────────┘    │
          │               │               │
          └───────────────┴───────────────┘
                          │
                          ▼
                     SCHEDULER
```

---

## Success Criteria

| Metric | Target |
|--------|--------|
| Brand extractors working | 5/5 |
| Price scrapers working | 6/6 |
| Scrape success rate | >85% |
| EAN match accuracy | >95% |
| Price freshness | <4 hours |
| Products in DB | >100 smartphones |

---

## Execution Order

Start with these commands in sequence:

```bash
# Day 1-2: Database + Fetcher
/x:implement "Create PostgreSQL migrations for products, variants, offers, price_history..."
/x:implement "Create PostgreSQL repository for products..."
/x:implement "Create Python HTTP client using curl_cffi..."

# Day 3-4: Brand Extractor Base + Apple
/x:implement "Create BrandExtractor base class..."
/x:implement "Create AppleExtractor for apple.com/fr..."

# Day 5-6: Samsung + Other Brands
/x:implement "Create SamsungExtractor for samsung.com/fr..."
/x:implement "Create XiaomiExtractor, GoogleExtractor, OnePlusExtractor..."

# Day 7-8: Price Scraper Base + Amazon
/x:implement "Create PriceScraper base class..."
/x:implement "Create AmazonPriceScraper..."

# Day 9-10: Other Price Scrapers
/x:implement "Create FnacPriceScraper, DartyPriceScraper..."
/x:implement "Create BoulangerPriceScraper, CdiscountPriceScraper, LdlcPriceScraper..."

# Day 11-12: Job Queue + Scheduler
/x:implement "Create Redis-based job queue..."
/x:implement "Create Go scheduler service..."

# Day 13-14: Polish + Testing
/x:implement "Add exponential backoff retry logic..."
/x:verify "Run full integration test of scraping pipeline"
```

---

## Verification Checkpoints

After each milestone:

```bash
# After M1: Database works
/x:verify "Verify database migrations run successfully and repository tests pass"

# After M2: Brand scraping works
/x:verify "Run Apple extractor against live site and verify product data quality"

# After M3: Price scraping works
/x:verify "Run Amazon price scraper for known EANs and verify price accuracy"

# After M4: Full pipeline works
/x:verify "Run end-to-end scraping pipeline: brand discovery → price collection → API query"
```

---

**Created**: 2025-12-01
**Initiative**: [Scraper](../milestones/scraper/)
**Back to**: [MASTERPLAN](../milestones/MASTERPLAN.md)
