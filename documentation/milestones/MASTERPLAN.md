# MASTERPLAN - Pareto Comparator MVP

> **The single source of truth orchestrating all initiatives**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                      PARETO COMPARATOR - MVP MASTERPLAN                       ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     PRE-MVP                                                          ║
║  Target:     MVP Launch (Smartphones - France)                                ║
║  Platforms:  Web (Next.js) + Mobile (Expo iOS/Android)                       ║
║  Developer:  Solo (@clumineau)                                                ║
║  Budget:     <30EUR/month                                                     ║
║  Timeline:   14-16 weeks                                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Vision

Build the **best product comparison platform in France** using Pareto optimization to help users find optimal trade-offs, not just the cheapest price.

**MVP Scope**:
- **Category**: Smartphones from 6 French retailers
- **Platforms**: Web + iOS + Android (via Expo)
- **Differentiator**: Multi-objective Pareto optimization

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

| # | Initiative | Effort | Status | Dependencies |
|---|------------|--------|--------|--------------|
| 1 | [Foundation](./foundation/) | 1 day | ⏳ Active | None |
| 2 | [Scraper](./scraper/) | 3-4 weeks | ⏳ Pending | Foundation |
| 3 | [Normalizer](./normalizer/) | 2 weeks | ⏳ Pending | Scraper |
| 4 | [Catalog](./catalog/) | 2 weeks | ⏳ Pending | Normalizer |
| 5 | [Comparison](./comparison/) | 1.5 weeks | ⏳ Pending | Catalog |
| 6 | [Affiliate](./affiliate/) | 1 week | ⏳ Pending | Catalog |
| 7 | [Frontend Web](./frontend/) | 4 weeks | ⏳ Pending | Catalog, Comparison, Affiliate |
| 8 | [Frontend Mobile](./mobile/) | 4 weeks | ⏳ Pending | Catalog, Comparison, Affiliate |
| 9 | [Launch](./launch/) | 2 weeks | ⏳ Pending | All |

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

### Active: Foundation Initiative

```
Initiative: FOUNDATION
Status:     IN PROGRESS
Progress:   33% (1/3 milestones complete)

Milestones:
  ✅ M1: Infrastructure Setup (local PC + Dokploy)
  ⏳ M2: Monorepo & Turborepo Setup (ACTIVE)
  ⏳ M3: Legal Setup (DEFERRED)
```

**Next Action**: Setup Turborepo with shared packages

→ [View Foundation Details](./foundation/)

---

## Progress Tracking

### Overall Progress: ~2%

```
Foundation   [▓▓▓░░░░░░░]  33%  ← ACTIVE
Scraper      [░░░░░░░░░░]   0%
Normalizer   [░░░░░░░░░░]   0%
Catalog      [░░░░░░░░░░]   0%
Comparison   [░░░░░░░░░░]   0%
Affiliate    [░░░░░░░░░░]   0%
Frontend Web [░░░░░░░░░░]   0%
Mobile       [░░░░░░░░░░]   0%
Launch       [░░░░░░░░░░]   0%
─────────────────────────────
TOTAL        [░░░░░░░░░░]   2%
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

---

## Post-MVP

1. **v1.1**: More categories (laptops, tablets)
2. **v1.2**: User accounts, price alerts
3. **v2.0**: VPS migration, scale
4. **v3.0**: International expansion

---

**Last Updated**: 2025-12-01
**Next Review**: After Foundation complete
