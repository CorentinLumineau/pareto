# Normalizer Initiative

> **HTML parsing, data extraction, and product normalization**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                          NORMALIZER INITIATIVE                                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     ⏳ PENDING                                                       ║
║  Effort:     2 weeks (10 days)                                               ║
║  Depends:    Scraper                                                         ║
║  Unlocks:    Catalog                                                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Objective

Transform raw HTML from scraped pages into structured, normalized product data. Handle retailer-specific extraction logic and ensure data quality before storage.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      NORMALIZER FLOW                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Raw HTML ─────► Retailer ─────► Normalized ─────► Validation  │
│   (Redis)        Extractor        Product          (Quality)    │
│                                                                 │
│                      │                │                │        │
│                      ▼                ▼                ▼        │
│                  BeautifulSoup    Pydantic         Schema       │
│                  + Selectolax     Models           Checks       │
│                                                                 │
│                                                    │            │
│                                                    ▼            │
│                                              Entity Resolution  │
│                                              (Deduplication)    │
│                                                    │            │
│                                                    ▼            │
│                                              Catalog API        │
│                                              (Go service)       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Runtime | Python 3.11+ | Main processing |
| Task Queue | Celery | Job processing |
| HTML Parser | selectolax | Fast HTML parsing |
| Validation | Pydantic v2 | Data validation |
| HTTP Client | httpx | Catalog API calls |

## Phases

| # | Phase | Effort | Description |
|---|-------|--------|-------------|
| 01 | [Core Framework](./01-core.md) | 2d | Celery setup, base extractor |
| 02 | [Retailer Extractors](./02-extractors.md) | 4d | 6 retailer-specific extractors |
| 03 | [Validation Pipeline](./03-validation.md) | 2d | Quality checks, schema validation |
| 04 | [Entity Resolution](./04-entity-resolution.md) | 2d | Product deduplication |

## Data Flow

```python
# Input: Raw scrape result from Redis
{
    "job_id": "abc123",
    "url": "https://amazon.fr/dp/B0ABC123",
    "html": "<html>...",
    "retailer_id": "amazon_fr"
}

# Output: Normalized product
{
    "external_id": "B0ABC123",
    "retailer_id": "amazon_fr",
    "title": "iPhone 15 Pro 256GB Noir",
    "price": 1229.00,
    "currency": "EUR",
    "brand": "Apple",
    "model": "iPhone 15 Pro",
    "attributes": {
        "storage": "256GB",
        "color": "Noir",
        "ean": "1234567890123"
    },
    "scraped_at": "2025-01-15T10:30:00Z"
}
```

## Retailer Extractors

Each retailer has specific extraction logic:

| Retailer | ID Field | Price Selector | Challenges |
|----------|----------|----------------|------------|
| Amazon.fr | ASIN | `#priceblock_ourprice` | Multiple price locations |
| Fnac.com | EAN | `.f-priceBox-price` | Marketplace vs direct |
| Cdiscount | SKU | `.fpPrice` | Flash sales markup |
| Darty.com | CODIC | `.product-price__amount` | Stock status |
| Boulanger | Ref | `.price__amount` | Eco-part included |
| LDLC.com | Ref | `.price` | Multiple variants |

## Quality Metrics

| Metric | Target |
|--------|--------|
| Extraction success rate | >95% |
| Price accuracy | 100% |
| Title extraction | >99% |
| Attribute extraction | >80% |
| Processing latency | <500ms |

## Deliverables

- [ ] Celery worker processing jobs
- [ ] 6 retailer extractors
- [ ] Pydantic validation schemas
- [ ] Entity resolution for duplicates
- [ ] Catalog API integration
- [ ] Monitoring and alerting

---

**Depends on**: [Scraper](../scraper/)
**Unlocks**: [Catalog](../catalog/)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
