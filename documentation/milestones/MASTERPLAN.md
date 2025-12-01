# MASTERPLAN - Pareto Comparator MVP

> **The single source of truth orchestrating all initiatives**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                      PARETO COMPARATOR - MVP MASTERPLAN                       ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     IN PROGRESS (~25% complete)                                     ║
║  Target:     MVP Launch (Smartphones - France)                                ║
║  Platforms:  Web (Next.js) + Mobile (Expo iOS/Android)                       ║
║  Developer:  Solo (@clumineau)                                                ║
║  Budget:     <30EUR/month                                                     ║
║  Timeline:   10-12 weeks remaining                                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Vision

Build the **best product comparison platform in France** using Pareto optimization to help users find optimal trade-offs, not just the cheapest price.

**MVP Scope**:
- **Category**: Smartphones from 5 brand websites + 6 marketplaces
- **Platforms**: Web + iOS + Android (via Expo)
- **Differentiator**: Multi-objective Pareto optimization

## Data Strategy: Brand-First Approach

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          BRAND-FIRST SCRAPING                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   PRIMARY: Brand Websites (Complete Specs)                                  │
│   ├── Apple.com/fr     → iPhone models, EAN, all specs                     │
│   ├── Samsung.com/fr   → Galaxy models, EAN, all specs                     │
│   ├── Xiaomi.com       → Mi/Redmi models, EAN, all specs                   │
│   ├── Google Store     → Pixel models, EAN, all specs                      │
│   └── OnePlus.com      → OnePlus models, EAN, all specs                    │
│                                                                             │
│   SECONDARY: Marketplaces (Prices Only)                                     │
│   ├── Amazon.fr        → Search by EAN → price, stock, URL                 │
│   ├── Fnac.com         → Search by EAN → price, stock, URL                 │
│   ├── Cdiscount.com    → Search by EAN → price, stock, URL                 │
│   ├── Darty.com        → Search by EAN → price, stock, URL                 │
│   ├── Boulanger.com    → Search by EAN → price, stock, URL                 │
│   └── LDLC.com         → Search by EAN → price, stock, URL                 │
│                                                                             │
│   DATA FLOW:                                                                │
│   Brand Site → Product (40+ specs) → EAN → Marketplace Search → Prices     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

See [implementation/scraping-strategy.md](../implementation/scraping-strategy.md) for complete details.

---

## Initiative Orchestration

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              INITIATIVE FLOW                                   ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   [FOUNDATION] ──────────────────────────────────────────────────────────┐    ║
║        │                                                                 │    ║
║        ▼                                                                 │    ║
║   [SCRAPER] ─────────────────────────────────────────────────────┐       │    ║
║        │                                                         │       │    ║
║        ▼                                                         │       │    ║
║   [NORMALIZER]                                                   │       │    ║
║        │                                                         │       │    ║
║        ▼                                                         │       │    ║
║   [CATALOG] ◄────────────────────────────────────────────────────┤       │    ║
║        │                                                         │       │    ║
║        ├──────────────┐                                          │       │    ║
║        ▼              ▼                                          │       │    ║
║   [COMPARISON]   [AFFILIATE]                                     │       │    ║
║        │              │                                          │       │    ║
║        └──────┬───────┘                                          │       │    ║
║               ▼                                                  │       │    ║
║   ┌───────────┴───────────┐                                      │       │    ║
║   ▼                       ▼                                      │       │    ║
║ [FRONTEND-WEB]      [FRONTEND-MOBILE]  ◄─────────────────────────┘       │    ║
║   │                       │                                              │    ║
║   └───────────┬───────────┘                                              │    ║
║               ▼                                                          │    ║
║          [LAUNCH] ◄──────────────────────────────────────────────────────┘    ║
║               │                                                               ║
║               ▼                                                               ║
║          🎉 MVP COMPLETE                                                      ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

---

## Timeline Overview

```
Week  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16
      │───│───│───│───│───│───│───│───│───│───│───│───│───│───│───│
FOUND [█]
SCRAP     [███████]
NORM              [█████]
CATAL                   [█████]
COMP                          [███]
AFFIL                              [██]
WEB                                    [███████████]
MOBILE                                 [███████████]  (parallel)
LAUNC                                              [█████]
```

---

## Initiatives Summary

### MVP Pipeline

| # | Initiative | Effort | Status | Progress | Dependencies |
|---|------------|--------|--------|----------|--------------|
| 1 | [Foundation](./foundation/) | 1 day | ✅ Complete | 100% | None |
| 2 | [Scraper](./scraper/) | 2-3 weeks | ⏳ Active | 10% | Foundation |
| 3 | [Normalizer](./normalizer/) | 1.5 weeks | ⏳ Pending | 20% | Scraper |
| 4 | [Catalog](./catalog/) | 2 weeks | ⏳ Pending | 5% | Normalizer |
| 5 | [Comparison](./comparison/) | 1 week | ⏳ Pending | 60% | Catalog |
| 6 | [Affiliate](./affiliate/) | 1 week | ⏳ Pending | 0% | Catalog |
| 7 | [Frontend Web](./frontend/) | 3 weeks | ⏳ Pending | 10% | Catalog, Comparison, Affiliate |
| 8 | [Frontend Mobile](./mobile/) | 3 weeks | ⏳ Pending | 10% | Catalog, Comparison, Affiliate |
| 9 | [Launch](./launch/) | 2 weeks | ⏳ Pending | 0% | All |

### Cross-Cutting Initiatives

| # | Initiative | Effort | Status | Progress | Dependencies |
|---|------------|--------|--------|----------|--------------|
| 10 | [Quality Enforcement](./quality-enforcement/) | 1.5 weeks | ✅ Complete | 100% | Foundation |

**Key Progress Notes:**
- Foundation: Turborepo, shared packages, Docker all configured
- Comparison: Pareto calculator fully implemented in Python
- Normalizer: Amazon extractor exists, needs brand extractors
- Frontend/Mobile: Landing pages exist, need API integration
- Quality Enforcement: ✅ Complete - `make verify` with coverage, type safety, SOLID checks, security scanning, pre-commit hooks, CI/CD

---

## Monorepo Architecture (Turborepo + pnpm)

### Full Structure with Shared Packages

```
pareto/
├── apps/
│   ├── api/                        # Go modular monolith
│   │   ├── cmd/api/
│   │   ├── internal/
│   │   │   ├── catalog/           # Product module
│   │   │   ├── scraper/           # Scraping orchestration
│   │   │   ├── compare/           # Pareto engine
│   │   │   └── affiliate/         # Revenue tracking
│   │   ├── go.mod
│   │   └── Dockerfile
│   │
│   ├── web/                        # Next.js 15 (Web)
│   │   ├── src/app/               # App Router
│   │   ├── package.json
│   │   └── Dockerfile
│   │
│   ├── mobile/                     # Expo (iOS + Android)
│   │   ├── app/                   # Expo Router
│   │   ├── components/
│   │   ├── app.json
│   │   └── package.json
│   │
│   └── workers/                    # Python Celery workers
│       ├── src/
│       │   ├── normalizer/
│       │   └── pareto/
│       ├── pyproject.toml
│       └── Dockerfile
│
├── packages/                       # Shared across web + mobile
│   ├── api-client/                # TypeScript API client
│   │   ├── src/
│   │   │   ├── client.ts         # Fetch wrapper
│   │   │   ├── hooks.ts          # TanStack Query hooks
│   │   │   └── types.ts          # API types
│   │   └── package.json
│   │
│   ├── types/                     # Shared TypeScript types
│   │   ├── src/
│   │   │   ├── product.ts
│   │   │   ├── price.ts
│   │   │   ├── comparison.ts
│   │   │   └── index.ts
│   │   └── package.json
│   │
│   ├── utils/                     # Shared utilities
│   │   ├── src/
│   │   │   ├── format.ts         # Price formatting
│   │   │   ├── pareto.ts         # Pareto helpers
│   │   │   └── validation.ts     # Zod schemas
│   │   └── package.json
│   │
│   ├── ui/                        # Shared UI (future)
│   │   └── package.json
│   │
│   ├── eslint-config/
│   │   └── package.json
│   │
│   └── typescript-config/
│       ├── base.json
│       ├── nextjs.json
│       ├── expo.json
│       └── package.json
│
├── docker/
│   └── docker-compose.yml
│
├── turbo.json
├── package.json
├── pnpm-workspace.yaml
└── Makefile
```

### Shared Package Usage

```typescript
// In apps/web or apps/mobile
import { useProducts, useComparison } from '@pareto/api-client'
import { Product, ComparisonResult } from '@pareto/types'
import { formatPrice, calculateParetoScore } from '@pareto/utils'

export function ProductList() {
  const { data: products } = useProducts()

  return products?.map(p => (
    <div key={p.id}>
      {p.title} - {formatPrice(p.best_price)}
    </div>
  ))
}
```

---

## Current Focus

### Active: Scraper Initiative (Brand-First)

```
Initiative: SCRAPER
Status:     IN PROGRESS
Progress:   10% (skeleton exists, needs brand extractors)

Milestones:
  ✅ M1: Scraper Skeleton (Go orchestrator exists)
  ⏳ M2: Brand Extractors (Apple, Samsung, etc.) ← ACTIVE
  ⏳ M3: Price Scrapers (Amazon, Fnac, etc.)
  ⏳ M4: Job Queue & Scheduling
```

**Next Action**: Implement Apple brand extractor

→ [View Scraper Details](./scraper/)

### Completed: Foundation Initiative

```
Initiative: FOUNDATION
Status:     ✅ COMPLETE
Progress:   100%

Deliverables:
  ✅ Turborepo monorepo configured
  ✅ Shared packages (@pareto/types, @pareto/api-client, @pareto/utils)
  ✅ Go API skeleton with Chi router
  ✅ Python workers with Celery
  ✅ Next.js 16 app with landing page
  ✅ Expo mobile app with landing page
  ✅ Docker Compose for local dev
```

→ [View Foundation Details](./foundation/)

---

## Progress Tracking

### Overall Progress: ~25%

```
Foundation   [██████████] 100%  ✅ COMPLETE
Scraper      [█░░░░░░░░░]  10%  ← ACTIVE
Normalizer   [██░░░░░░░░]  20%  (Amazon extractor exists)
Catalog      [░░░░░░░░░░]   5%  (Schema designed)
Comparison   [██████░░░░]  60%  (Pareto calculator done)
Affiliate    [░░░░░░░░░░]   0%
Frontend Web [█░░░░░░░░░]  10%  (Landing page exists)
Mobile       [█░░░░░░░░░]  10%  (Landing page exists)
Launch       [░░░░░░░░░░]   0%
─────────────────────────────────────────────
TOTAL        [██▓░░░░░░░]  25%
```

### Success Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Products in DB | >500 | 0 |
| Scrape success | >85% | - |
| API response | <200ms | - |
| Lighthouse (Web) | >90 | - |
| App Store rating | >4.0 | - |
| Organic visitor | 1 | 0 |

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Anti-bot blocks | High | High | Multiple fingerprints, proxies |
| Affiliate rejection | Medium | Medium | Build traffic first |
| Scope creep | High | Medium | Strict YAGNI, smartphones only |
| App Store rejection | Low | High | Follow guidelines, simple first version |
| Solo burnout | Medium | High | Realistic pace |

---

## Budget

| Item | Monthly | Status |
|------|---------|--------|
| Hosting (local) | 0€ | ✅ |
| Domain | ~1€ | ✅ |
| Apple Developer | ~8€ | ⏳ When ready |
| Proxies | 0-15€ | ⏳ |
| **Total** | **<25€** | ✅ |

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-12-01 | Smartphones only | Focus for MVP |
| 2025-12-01 | Local hosting | Budget, Dokploy ready |
| 2025-12-01 | Turborepo + pnpm | Caching, consistency |
| 2025-12-01 | Expo for mobile | Cross-platform, shared packages |
| 2025-12-01 | Web + Mobile parallel | Same API, shared code |
| 2025-12-01 | Defer legal | Validate first |
| 2025-12-01 | **Brand-first scraping** | Complete specs from source, easier to scrape |
| 2025-12-01 | EAN-based matching | Universal product identifier for cross-retailer matching |
| 2025-12-01 | December 2025 stack | Go 1.24, Python 3.14, Next.js 16, Expo 53, PostgreSQL 18 |

---

## Post-MVP

1. **v1.1**: More categories (laptops, tablets)
2. **v1.2**: User accounts, price alerts
3. **v2.0**: VPS migration, scale
4. **v3.0**: International expansion

---

**Last Updated**: 2025-12-01
**Next Review**: After Foundation complete
