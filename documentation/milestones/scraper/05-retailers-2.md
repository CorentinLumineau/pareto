# Phase 05: Remaining 3 Retailers

> **Darty.com, Boulanger.com, LDLC.com adapters**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      05 - Remaining 3 Retailers                        ║
║  Initiative: Scraper                                           ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     4 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Implement scrapers for the remaining 3 retailers to complete the MVP retailer coverage.

## Retailers

### 1. Darty.com (~1.5 days)
- URL: `darty.com/nav/achat/`, `darty.com/nav/codic/`
- Extract: CODIC, title, price, stock status
- Challenge: PerimeterX protection
- Anti-Bot: Requires 2s delay, rotating fingerprints

### 2. Boulanger.com (~1 day)
- URL: `boulanger.com/ref/`, `boulanger.com/c/`
- Extract: SKU, title, price, eco-part
- Challenge: Light protection
- Anti-Bot: 1s delay sufficient

### 3. LDLC.com (~1.5 days)
- URL: `ldlc.com/fiche/`, `ldlc.com/fr-fr/`
- Extract: Reference, title, price, availability
- Challenge: Light protection
- Anti-Bot: 1s delay sufficient

## Tasks

- [ ] Darty.com adapter with PerimeterX handling
- [ ] Boulanger.com adapter
- [ ] LDLC.com adapter
- [ ] Integration tests for all 3
- [ ] E2E test: complete pipeline for each

## Anti-Bot Configuration

| Retailer | Protection | Rate Limit | Fingerprint |
|----------|------------|------------|-------------|
| Darty.com | PerimeterX | 2s | chrome136 |
| Boulanger | Light | 1s | chrome136 |
| LDLC.com | Light | 1s | chrome136 |

## URL Pattern Matching

```go
// apps/api/internal/scraper/retailers/patterns.go

var retailerPatterns = map[string]*regexp.Regexp{
    "darty":     regexp.MustCompile(`darty\.com/nav/(achat|codic)/`),
    "boulanger": regexp.MustCompile(`boulanger\.com/(ref|c)/`),
    "ldlc":      regexp.MustCompile(`ldlc\.com/(fiche|fr-fr)/`),
}
```

## Deliverables

- [ ] 3 additional retailers scraping
- [ ] >90% success rate each
- [ ] URL patterns working
- [ ] Full pipeline E2E tested

---

**Previous**: [04-retailers-1.md](./04-retailers-1.md)
**Back to**: [Scraper README](./README.md)
