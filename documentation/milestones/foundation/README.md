# Foundation Initiative

> **Development environment, monorepo setup, and infrastructure**

```
╔════════════════════════════════════════════════════════════════╗
║  Initiative: FOUNDATION                                         ║
║  Status:     IN PROGRESS                                        ║
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
| M2 | Monorepo & Turborepo | 1 day | ⏳ Active | [02-monorepo.md](./02-monorepo.md) |
| M3 | Legal Setup | - | ⏳ Deferred | [03-legal.md](./03-legal.md) |

## Progress: 33%

```
M1 Infrastructure  [██████████] 100% ✅
M2 Monorepo        [░░░░░░░░░░]   0% ← ACTIVE
M3 Legal           [░░░░░░░░░░]   0% (deferred)
```

## Current Focus: M2 Monorepo Setup

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

- [ ] `pnpm install` works at root
- [ ] `pnpm dev` starts all services
- [ ] `pnpm build` builds all apps
- [ ] `pnpm lint` passes
- [ ] Docker compose starts all containers
- [ ] CI pipeline runs on push

## Deliverables

After this initiative:
```
✅ Turborepo monorepo configured
✅ Go API skeleton with internal modules
✅ Next.js app with TanStack Query
✅ Python workers with Celery
✅ Docker compose for local dev
✅ CI/CD pipeline (GitHub Actions)
✅ Makefile with common commands
```

---

**Next Initiative**: [Scraper](../scraper/)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
