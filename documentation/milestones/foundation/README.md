# Foundation Initiative

> **Development environment, monorepo setup, and infrastructure**

```
╔════════════════════════════════════════════════════════════════╗
║  Initiative: FOUNDATION                                         ║
║  Status:     ✅ COMPLETE                                        ║
║  Priority:   P0 - Critical (Blocker)                           ║
║  Effort:     1-2 days                                           ║
║  Owner:      @clumineau                                         ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Setup the complete development environment with Turborepo monorepo structure enabling:
- Consistent builds across Go, Python, and Next.js
- Shared configurations and types
- Docker-based local development
- CI/CD pipeline ready

## Milestones

| # | Milestone | Effort | Status | Phase File |
|---|-----------|--------|--------|------------|
| M1 | Infrastructure Setup | - | ✅ Complete | [01-infrastructure.md](./01-infrastructure.md) |
| M2 | Monorepo & Turborepo | 1 day | ✅ Complete | [02-monorepo.md](./02-monorepo.md) |
| M3 | Legal Setup | - | ⏳ Deferred | [03-legal.md](./03-legal.md) |

## Progress: 100% ✅

```
M1 Infrastructure  [██████████] 100% ✅
M2 Monorepo        [██████████] 100% ✅
M3 Legal           [░░░░░░░░░░]   0% (deferred to launch)
```

## Completed Deliverables

### Turborepo Structure

```
pareto/
├── apps/
│   ├── api/                    # Go modular monolith
│   │   ├── cmd/api/main.go
│   │   ├── internal/
│   │   │   ├── catalog/       # Product module
│   │   │   ├── scraper/       # Scraping orchestration
│   │   │   ├── compare/       # Pareto engine
│   │   │   └── affiliate/     # Revenue tracking
│   │   ├── go.mod
│   │   ├── go.sum
│   │   └── Dockerfile
│   │
│   ├── web/                    # Next.js 15 frontend
│   │   ├── src/
│   │   │   ├── app/           # App Router
│   │   │   ├── components/
│   │   │   └── lib/
│   │   ├── package.json
│   │   ├── next.config.ts
│   │   └── Dockerfile
│   │
│   └── workers/                # Python Celery workers
│       ├── src/
│       │   ├── normalizer/    # HTML parsing
│       │   ├── pareto/        # Pareto calculation
│       │   └── __init__.py
│       ├── pyproject.toml
│       ├── celeryconfig.py
│       └── Dockerfile
│
├── packages/
│   ├── eslint-config/          # Shared ESLint config
│   │   └── package.json
│   ├── typescript-config/      # Shared TS config
│   │   ├── base.json
│   │   └── package.json
│   └── ui/                     # Shared UI components (future)
│       └── package.json
│
├── docker/
│   ├── docker-compose.yml      # Local development
│   └── docker-compose.prod.yml # Production
│
├── scripts/
│   ├── dev.sh                  # Start dev environment
│   └── seed.sh                 # Seed database
│
├── turbo.json                  # Turborepo configuration
├── package.json                # Root package.json
├── pnpm-workspace.yaml         # PNPM workspaces
├── .gitignore
├── Makefile                    # Common commands
└── README.md
```

### Go Module Communication (Direct Imports)

```go
// apps/api/internal/scraper/service.go
package scraper

import (
    "github.com/clumineau/pareto/apps/api/internal/catalog"
)

type ScraperService struct {
    catalogRepo catalog.ProductRepository  // Direct import
}
```

## Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| Local PC | ✅ Ready | Dokploy installed |
| Domain | ✅ Ready | Cloudflare tunneling |
| PostgreSQL | ✅ Ready | Docker container |
| Redis | ✅ Ready | Docker container |

## Success Criteria

- [x] `pnpm install` works at root
- [x] `pnpm dev` starts all services
- [x] `pnpm build` builds all apps
- [x] `pnpm lint` passes
- [x] Docker compose starts all containers
- [ ] CI pipeline runs on push (deferred)

## Deliverables

All completed:
```
✅ Turborepo monorepo configured (turbo.json, pnpm-workspace.yaml)
✅ Go API skeleton with Chi router (apps/api/)
✅ Next.js 16 app with landing page (apps/web/)
✅ Expo SDK 53 app with landing page (apps/mobile/)
✅ Python workers with Celery + Pareto calculator (apps/workers/)
✅ Shared packages:
   ├── @pareto/types (Product, Offer, ComparisonResult)
   ├── @pareto/api-client (TanStack Query hooks)
   └── @pareto/utils (formatPrice, formatDate)
✅ Docker compose for local dev (PostgreSQL, Redis)
✅ Makefile with common commands
```

## What's Implemented

### Go API (`apps/api/`)
- Chi router with middleware
- CORS, logging, recovery middleware
- Health check endpoints
- Module structure (catalog, scraper, compare, affiliate)
- Handlers are skeleton (TODOs) - ready for implementation

### Python Workers (`apps/workers/`)
- Celery task queue configured
- **Pareto calculator FULLY IMPLEMENTED** (`src/pareto/calculator.py`)
- Amazon extractor exists (`src/normalizer/extractors/amazon.py`)
- Ready for brand extractors

### Next.js Web (`apps/web/`)
- Next.js 16 with App Router
- Tailwind CSS v4 configured
- Landing page with hero section
- Ready for product pages

### Expo Mobile (`apps/mobile/`)
- Expo SDK 53 configured
- Expo Router v4 (file-based navigation)
- NativeWind (Tailwind for React Native)
- Landing page exists
- Ready for product screens

---

**Next Initiative**: [Scraper](../scraper/) (Brand-First Approach)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
