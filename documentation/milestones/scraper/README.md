# Scraper Initiative

> **Brand-first scraping: Complete specs from brands, prices from marketplaces**

```
╔════════════════════════════════════════════════════════════════╗
║  Initiative: SCRAPER                                            ║
║  Status:     ⏳ IN PROGRESS                                     ║
║  Priority:   P0 - Critical                                      ║
║  Effort:     2-3 weeks                                          ║
║  Depends:    Foundation ✅                                      ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Implement the **brand-first scraping strategy**:
1. **Primary**: Scrape brand websites for complete product specifications (40+ attributes)
2. **Secondary**: Scrape marketplaces for real prices and availability
3. **Matching**: Use EAN/GTIN to link brand products to marketplace offers

See [implementation/scraping-strategy.md](../../implementation/scraping-strategy.md) for complete strategy.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        BRAND-FIRST SCRAPING FLOW                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   PHASE 1: BRAND SCRAPING (Complete Product Data)                           │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                                                                     │   │
│   │   [Scheduler] ──▶ [Brand Extractor] ──▶ [Product + 40+ Specs]      │   │
│   │       │               (Python)              │                       │   │
│   │       │                                     ▼                       │   │
│   │   Brands:                             [Catalog DB]                  │   │
│   │   ├── Apple.com/fr                    (with EAN)                    │   │
│   │   ├── Samsung.com/fr                                                │   │
│   │   ├── Xiaomi.com                                                    │   │
│   │   ├── Google Store                                                  │   │
│   │   └── OnePlus.com                                                   │   │
│   │                                                                     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   PHASE 2: PRICE SCRAPING (Prices Only)                                     │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                                                                     │   │
│   │   [EAN List] ──▶ [Marketplace Search] ──▶ [Price + URL]            │   │
│   │       │             (Python)                  │                     │   │
│   │       │                                       ▼                     │   │
│   │   Marketplaces:                         [Offers Table]              │   │
│   │   ├── Amazon.fr (EAN search)            (linked to product)         │   │
│   │   ├── Fnac.com                                                      │   │
│   │   ├── Cdiscount.com                                                 │   │
│   │   ├── Darty.com                                                     │   │
│   │   ├── Boulanger.com                                                 │   │
│   │   └── LDLC.com                                                      │   │
│   │                                                                     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Milestones

| # | Milestone | Effort | Status | File |
|---|-----------|--------|--------|------|
| M1 | Scraper Skeleton (Go) | 2 days | ✅ Done | [01-skeleton.md](./01-skeleton.md) |
| M2 | Brand Extractors | 5 days | ⏳ Active | [02-brand-extractors.md](./02-brand-extractors.md) |
| M3 | Price Scrapers | 4 days | ⏳ Pending | [03-price-scrapers.md](./03-price-scrapers.md) |
| M4 | Job Queue & Scheduling | 3 days | ⏳ Pending | [04-queue.md](./04-queue.md) |

## Progress: 10%

```
M1 Skeleton        [██████████] 100% ✅
M2 Brand Extract   [░░░░░░░░░░]   0% ← ACTIVE
M3 Price Scrapers  [░░░░░░░░░░]   0%
M4 Queue           [░░░░░░░░░░]   0%
```

## Brand Extractors (M2)

| Brand | Website | Products | EAN Available | Difficulty |
|-------|---------|----------|---------------|------------|
| Apple | apple.com/fr | ~20 iPhones | Yes (in specs) | Medium |
| Samsung | samsung.com/fr | ~30 Galaxy | Yes (specs page) | Medium |
| Xiaomi | mi.com | ~25 Mi/Redmi | Yes (usually) | Easy |
| Google | store.google.com | ~5 Pixel | Yes | Easy |
| OnePlus | oneplus.com | ~8 models | Yes | Easy |

### Brand Extractor Interface

```python
# apps/workers/src/scraper/brands/base.py
from dataclasses import dataclass
from abc import ABC, abstractmethod

@dataclass
class BrandProduct:
    name: str             # "iPhone 16 Pro"
    brand: str            # "Apple"
    model: str            # "iPhone 16 Pro"
    ean: str | None       # "0194253715214"
    sku: str              # Brand's internal SKU
    image_url: str        # High-quality official image
    attributes: dict      # 40+ official specs
    variants: list        # All color/storage combinations
    msrp: float | None    # Official price (reference only)

class BrandExtractor(ABC):
    @abstractmethod
    def get_product_list_url(self) -> str:
        """URL to scrape for product catalog"""
        pass

    @abstractmethod
    def extract_products(self, html: str) -> list[BrandProduct]:
        """Parse product page HTML into structured data"""
        pass
```

## Price Scrapers (M3)

| Marketplace | Method | Challenges | Priority |
|-------------|--------|------------|----------|
| Amazon.fr | EAN search API | Anti-bot (curl_cffi) | P0 |
| Fnac.com | EAN search | Marketplace vs direct | P0 |
| Cdiscount | EAN search | Flash sales | P1 |
| Darty.com | EAN search | Stock status | P1 |
| Boulanger | EAN search | Eco-part | P1 |
| LDLC.com | EAN search | Variants | P2 |

### Price Scraper Interface

```python
# apps/workers/src/scraper/prices/base.py
from dataclasses import dataclass
from abc import ABC, abstractmethod

@dataclass
class PriceResult:
    ean: str              # Product identifier
    retailer_id: str      # "amazon_fr"
    price: float          # 1199.00
    currency: str         # "EUR"
    url: str              # Product page URL
    in_stock: bool        # Availability
    was_price: float | None  # Original price if on sale
    scraped_at: datetime

class PriceScraper(ABC):
    @abstractmethod
    def search_by_ean(self, ean: str) -> PriceResult | None:
        """Search marketplace by EAN and extract price"""
        pass

    @abstractmethod
    def search_batch(self, eans: list[str]) -> list[PriceResult]:
        """Batch search for efficiency"""
        pass
```

## Key Technical Decisions

- **Go** for orchestration (job management, scheduling, API)
- **Python** for fetching (curl_cffi for anti-bot bypass)
- **Redis** for job queue
- **EAN/GTIN** as universal product identifier
- **curl_cffi** with browser impersonation for anti-bot

## Data Flow

```
1. Brand Scheduler triggers daily
   └── For each brand: fetch product catalog

2. Brand Extractor runs
   └── Outputs: BrandProduct with EAN, 40+ attributes

3. Product stored in Catalog
   └── Products table with attributes JSONB

4. Price Scheduler triggers (hourly for hot products)
   └── For each EAN: search all marketplaces

5. Price Scraper runs
   └── Outputs: PriceResult per retailer

6. Offer linked to Product via EAN
   └── Offers table with current price
```

## Success Criteria

- [ ] 5 brand extractors working (Apple, Samsung, Xiaomi, Google, OnePlus)
- [ ] 6 price scrapers working
- [ ] >85% scrape success rate
- [ ] EAN matching >95% accuracy
- [ ] Price freshness <4 hours for popular products
- [ ] Retry logic with exponential backoff

## What's Already Done

From Foundation:
- Go API skeleton with scraper module structure
- Python workers with Celery
- curl_cffi for browser impersonation
- Amazon extractor exists (needs update for EAN search)

---

**Previous**: [Foundation](../foundation/) ✅
**Next**: [Normalizer](../normalizer/)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
