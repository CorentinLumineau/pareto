# Phase 04: First 3 Retailers

> **Amazon.fr, Fnac.com, Cdiscount.com adapters**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      04 - First 3 Retailers                             ║
║  Initiative: Scraper                                            ║
║  Status:     ⏳ PENDING                                         ║
║  Effort:     5 days                                             ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Implement scrapers for the first 3 retailers.

## Retailers

### 1. Amazon.fr (~2 days)
- URL: `amazon.fr/dp/`, `amazon.fr/gp/product/`
- Extract: ASIN, title, price, attributes
- Challenge: Captcha on high volume

### 2. Fnac.com (~1.5 days)
- URL: `fnac.com/a`, `fnac.com/Smartphone-`
- Extract: EAN, title, price
- Challenge: Marketplace handling

### 3. Cdiscount.com (~1.5 days)
- URL: `cdiscount.com/f-`, `cdiscount.com/telephonie/`
- Extract: SKU, title, price
- Challenge: Flash sales

## Tasks

- [ ] Amazon.fr adapter with URL pattern matching
- [ ] Fnac.com adapter
- [ ] Cdiscount.com adapter
- [ ] Integration tests
- [ ] E2E test: queue → fetch → store

## Deliverables

- [ ] 3 retailers scraping
- [ ] >90% success rate each
- [ ] URL patterns working

---

**Previous**: [03-queue.md](./03-queue.md)
**Next**: [05-retailers-2.md](./05-retailers-2.md)
**Back to**: [Scraper README](./README.md)
