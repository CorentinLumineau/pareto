# Foundation Initiative - Implementation Workflow

> **Complete plan for Turborepo monorepo setup (Go + Python + Next.js + Expo)**

```
Created: 2025-12-01
Status:  Ready for Implementation
Effort:  13-14 hours (~1.5-2 days)
```

## Overview

This workflow implements **Phase 2: Monorepo & Turborepo Setup** from the Foundation initiative. Phase 1 (Infrastructure) is already complete, and Phase 3 (Legal) is deferred.

### Prerequisites

- [x] Local PC with Dokploy installed
- [x] PostgreSQL 17 + TimescaleDB running
- [x] Redis 7.4 running
- [x] Domain with Cloudflare tunneling
- [ ] pnpm 9.14+ installed (`npm install -g pnpm`)
- [ ] Go 1.24+ installed
- [ ] Python 3.14+ installed
- [ ] Node.js 24.x installed

---

## Task Hierarchy

```
Epic: Foundation - Monorepo Setup
├─ Milestone 1: Root Configuration (~1h)
│  ├─ Task 1.1: Initialize pnpm root project
│  ├─ Task 1.2: Configure Turborepo
│  └─ Task 1.3: Setup global config files
├─ Milestone 2: Shared Packages (~2.5h)
│  ├─ Task 2.1: Create typescript-config package
│  ├─ Task 2.2: Create eslint-config package
│  ├─ Task 2.3: Create @pareto/types package
│  ├─ Task 2.4: Create @pareto/api-client package
│  └─ Task 2.5: Create @pareto/utils package
├─ Milestone 3: Backend Services (~4h)
│  ├─ Task 3.1: Create Go API skeleton
│  └─ Task 3.2: Create Python workers skeleton
├─ Milestone 4: Frontend Applications (~4h)
│  ├─ Task 4.1: Create Next.js web application
│  └─ Task 4.2: Create Expo mobile application
├─ Milestone 5: DevOps & Infrastructure (~1.5h)
│  ├─ Task 5.1: Create Docker compose configuration
│  ├─ Task 5.2: Create Makefile
│  └─ Task 5.3: Setup GitHub Actions CI/CD
└─ Milestone 6: Verification (~1h)
   ├─ Task 6.1: Test pnpm install
   ├─ Task 6.2: Test pnpm dev (all services)
   ├─ Task 6.3: Test pnpm build
   └─ Task 6.4: Verify health endpoints
```

---

## Dependency Graph

```
M1: Root Config
    │
    ├───────────────────────┐
    ▼                       ▼
M2: Shared Packages     M3: Backend Services
    │                       │
    │   ┌───────────────────┤
    │   │                   │
    ▼   ▼                   ▼
M4: Frontend Apps      (continues)
    │                       │
    └───────────────────────┤
                            ▼
                    M5: DevOps & Infra
                            │
                            ▼
                    M6: Verification
```

---

## Milestone 1: Root Configuration

### Task 1.1: Initialize pnpm Root Project

**Command:**
```bash
/x:implement "Initialize pnpm root project with package.json for Turborepo monorepo - name 'pareto', private true, with dev scripts (dev, build, lint, test) using turbo, add turbo 2.3.0 as devDependency, set packageManager to pnpm@9.14.2"
```

**Deliverables:**
- `package.json` with turbo scripts and packageManager field

**Acceptance Criteria:**
- `pnpm install` runs without errors

---

### Task 1.2: Configure Turborepo

**Command:**
```bash
/x:implement "Create pnpm-workspace.yaml with packages 'apps/*' and 'packages/*', and turbo.json with tasks for build (dependsOn ^build, outputs .next/**, dist/**, bin/**), dev (cache false, persistent true), lint, and test"
```

**Deliverables:**
- `pnpm-workspace.yaml`
- `turbo.json`

**Acceptance Criteria:**
- Turborepo recognizes all workspace packages

---

### Task 1.3: Setup Global Config Files

**Command:**
```bash
/x:implement "Create .gitignore for Turborepo monorepo (node_modules, .turbo, dist, .next, __pycache__, .venv, bin/, *.exe, .env*, .DS_Store), .editorconfig (indent 2 spaces, utf-8, lf line endings), and .nvmrc with Node 24"
```

**Deliverables:**
- `.gitignore`
- `.editorconfig`
- `.nvmrc`

---

## Milestone 2: Shared Packages

### Task 2.1: Create typescript-config Package

**Command:**
```bash
/x:implement "Create packages/typescript-config/ with package.json (name @pareto/typescript-config), and JSON configs: base.json (strict, ES2024, module bundler, composite true), nextjs.json (extends base, JSX preserve, paths @/*), expo.json (extends base for React Native with JSX react-native)"
```

**Deliverables:**
- `packages/typescript-config/package.json`
- `packages/typescript-config/base.json`
- `packages/typescript-config/nextjs.json`
- `packages/typescript-config/expo.json`
- `packages/typescript-config/node.json`

---

### Task 2.2: Create eslint-config Package

**Command:**
```bash
/x:implement "Create packages/eslint-config/ with flat ESLint config for TypeScript, React, and Next.js - package.json name @pareto/eslint-config, index.js exporting flat configs array with TypeScript ESLint and React plugin rules"
```

**Deliverables:**
- `packages/eslint-config/package.json`
- `packages/eslint-config/index.js`

---

### Task 2.3: Create @pareto/types Package

**Command:**
```bash
/x:implement "Create packages/types/ with shared TypeScript types for the Pareto Comparator: Product interface (id, slug, name, gtin, categoryId, brandId, attributes as Record), Price interface (id, productId, retailerId, price, shipping, inStock, affiliateUrl, scrapedAt), Retailer interface (id, name, slug, active), Category interface (id, name, slug, parentId), ComparisonResult interface with paretoFrontier array and rankings, and barrel export index.ts"
```

**Deliverables:**
- `packages/types/package.json`
- `packages/types/src/product.ts`
- `packages/types/src/price.ts`
- `packages/types/src/retailer.ts`
- `packages/types/src/category.ts`
- `packages/types/src/comparison.ts`
- `packages/types/src/index.ts`
- `packages/types/tsconfig.json`

---

### Task 2.4: Create @pareto/api-client Package

**Command:**
```bash
/x:implement "Create packages/api-client/ with API client for Pareto Comparator: client.ts with typed fetch wrapper (createApiClient function with baseUrl, methods for get/post/put/delete), hooks.ts with TanStack Query hooks (useProducts, useProduct, useComparison, usePrices), types.ts re-exporting from @pareto/types, package.json with @tanstack/react-query 5.84+ peer dependency"
```

**Deliverables:**
- `packages/api-client/package.json`
- `packages/api-client/src/client.ts`
- `packages/api-client/src/hooks.ts`
- `packages/api-client/src/types.ts`
- `packages/api-client/src/index.ts`
- `packages/api-client/tsconfig.json`

---

### Task 2.5: Create @pareto/utils Package

**Command:**
```bash
/x:implement "Create packages/utils/ with shared utilities: format.ts with formatPrice(amount, locale='fr-FR', currency='EUR'), formatDate, formatPercentage functions, validation.ts with Zod schemas for Product, Price, ComparisonRequest, pareto.ts with isParetoOptimal helper function, package.json with zod 3.24+ dependency"
```

**Deliverables:**
- `packages/utils/package.json`
- `packages/utils/src/format.ts`
- `packages/utils/src/validation.ts`
- `packages/utils/src/pareto.ts`
- `packages/utils/src/index.ts`
- `packages/utils/tsconfig.json`

---

## Milestone 3: Backend Services

### Task 3.1: Create Go API Skeleton

**Command:**
```bash
/x:implement "Create apps/api/ Go modular monolith with Chi router: cmd/api/main.go entry point with Chi router, /health endpoint, /api/v1 group. Internal modules structure: internal/catalog/ (domain/product.go, repository/interface.go, service/catalog.go, handler/http.go), internal/scraper/, internal/compare/, internal/affiliate/ with same structure. internal/shared/ with database/postgres.go, cache/redis.go, config/config.go. go.mod with module github.com/clumineau/pareto/apps/api, dependencies chi/v5 5.2.0, pgx/v5 5.7.0, go-redis/v9, zerolog. Dockerfile multi-stage build"
```

**Deliverables:**
- `apps/api/go.mod`
- `apps/api/go.sum`
- `apps/api/cmd/api/main.go`
- `apps/api/internal/catalog/domain/product.go`
- `apps/api/internal/catalog/repository/interface.go`
- `apps/api/internal/catalog/service/catalog.go`
- `apps/api/internal/catalog/handler/http.go`
- `apps/api/internal/scraper/` (skeleton)
- `apps/api/internal/compare/` (skeleton)
- `apps/api/internal/affiliate/` (skeleton)
- `apps/api/internal/shared/database/postgres.go`
- `apps/api/internal/shared/cache/redis.go`
- `apps/api/internal/shared/config/config.go`
- `apps/api/Dockerfile`
- `apps/api/package.json` (for Turborepo integration)

**Acceptance Criteria:**
- `go build ./cmd/api` succeeds
- Running binary responds to `/health` with 200 OK

---

### Task 3.2: Create Python Workers Skeleton

**Command:**
```bash
/x:implement "Create apps/workers/ Python Celery workers: pyproject.toml with name pareto-workers, Python >=3.13, dependencies celery 5.4+, redis 5.2+, curl-cffi 0.7+, beautifulsoup4 4.12+, pydantic 2.10+, paretoset 1.2+, lxml 5.3+. src/normalizer/ with __init__.py, parser.py (BeautifulSoup HTML parsing), extractors/ directory with amazon.py and base.py. src/pareto/ with __init__.py, calculator.py (paretoset integration), normalizer.py (z-score). src/tasks/ with __init__.py and celery_app.py (Celery app config with Redis broker). celeryconfig.py. Dockerfile with Python 3.14 slim base"
```

**Deliverables:**
- `apps/workers/pyproject.toml`
- `apps/workers/celeryconfig.py`
- `apps/workers/src/__init__.py`
- `apps/workers/src/normalizer/__init__.py`
- `apps/workers/src/normalizer/parser.py`
- `apps/workers/src/normalizer/extractors/__init__.py`
- `apps/workers/src/normalizer/extractors/base.py`
- `apps/workers/src/normalizer/extractors/amazon.py`
- `apps/workers/src/pareto/__init__.py`
- `apps/workers/src/pareto/calculator.py`
- `apps/workers/src/pareto/normalizer.py`
- `apps/workers/src/tasks/__init__.py`
- `apps/workers/src/tasks/celery_app.py`
- `apps/workers/Dockerfile`
- `apps/workers/package.json` (for Turborepo integration)

**Acceptance Criteria:**
- `pip install -e .` succeeds
- `celery -A src.tasks.celery_app worker --loglevel=info` starts without errors

---

## Milestone 4: Frontend Applications

### Task 4.1: Create Next.js Web Application

**Command:**
```bash
/x:implement "Create apps/web/ Next.js 16 application with App Router: package.json with next 16.0.3, react 19.2.0, @tanstack/react-query 5.84+, recharts 2.14+, zod 3.24+, @pareto/types, @pareto/api-client, @pareto/utils workspace dependencies. next.config.ts with Turbopack enabled. tailwind.config.ts for Tailwind v4 (CSS-first config). src/app/layout.tsx with TanStack QueryClientProvider. src/app/page.tsx homepage. src/app/api/health/route.ts health check. src/components/ directory. src/lib/query-client.ts. tsconfig.json extending @pareto/typescript-config/nextjs.json. Dockerfile multi-stage build with pnpm"
```

**Deliverables:**
- `apps/web/package.json`
- `apps/web/next.config.ts`
- `apps/web/tailwind.config.ts`
- `apps/web/postcss.config.js`
- `apps/web/tsconfig.json`
- `apps/web/src/app/layout.tsx`
- `apps/web/src/app/page.tsx`
- `apps/web/src/app/globals.css`
- `apps/web/src/app/api/health/route.ts`
- `apps/web/src/components/.gitkeep`
- `apps/web/src/lib/query-client.ts`
- `apps/web/Dockerfile`

**Acceptance Criteria:**
- `pnpm dev` in apps/web starts on port 3000
- Homepage renders without errors
- `/api/health` returns 200 OK

---

### Task 4.2: Create Expo Mobile Application

**Command:**
```bash
/x:implement "Create apps/mobile/ Expo SDK 53 application with Expo Router: package.json with expo 53, react-native 0.79, expo-router, nativewind 4.x, @tanstack/react-query, @pareto/types, @pareto/api-client, @pareto/utils. app.json with Expo config (name Pareto, slug pareto, scheme pareto, iOS/Android config). app/ directory with _layout.tsx (QueryClientProvider, NativeWind setup), index.tsx home screen, compare.tsx comparison screen. tailwind.config.js for NativeWind. tsconfig.json extending @pareto/typescript-config/expo.json. metro.config.js for monorepo support"
```

**Deliverables:**
- `apps/mobile/package.json`
- `apps/mobile/app.json`
- `apps/mobile/tsconfig.json`
- `apps/mobile/tailwind.config.js`
- `apps/mobile/metro.config.js`
- `apps/mobile/babel.config.js`
- `apps/mobile/app/_layout.tsx`
- `apps/mobile/app/index.tsx`
- `apps/mobile/app/compare.tsx`
- `apps/mobile/global.css`

**Acceptance Criteria:**
- `pnpm start` in apps/mobile launches Expo dev server
- App loads in Expo Go without errors

---

## Milestone 5: DevOps & Infrastructure

### Task 5.1: Create Docker Compose Configuration

**Command:**
```bash
/x:implement "Create docker/docker-compose.yml for local development: services postgres (timescale/timescaledb:2.23.0-pg18, port 5432, env POSTGRES_USER/PASSWORD/DB pareto), redis (redis:8.4-alpine, port 6379), api (build ../apps/api, port 8080, depends_on postgres redis, env vars), web (build ../apps/web, port 3000), workers (build ../apps/workers, depends_on redis postgres). Create docker/docker-compose.prod.yml variant. Volumes for postgres data persistence"
```

**Deliverables:**
- `docker/docker-compose.yml`
- `docker/docker-compose.prod.yml`
- `docker/.env.example`

**Acceptance Criteria:**
- `docker compose up -d` starts all containers
- All services healthy and communicating

---

### Task 5.2: Create Makefile

**Command:**
```bash
/x:implement "Create root Makefile with targets: install (pnpm install, go mod download, pip install), dev (pnpm dev), build (pnpm build), lint (pnpm lint), test (pnpm test), docker-up (docker compose -f docker/docker-compose.yml up -d), docker-down (docker compose down), docker-logs (docker compose logs -f), migrate-up (run migrations), seed (seed database), clean (remove node_modules, dist, .turbo, __pycache__). Include .PHONY declarations and help target"
```

**Deliverables:**
- `Makefile`

**Acceptance Criteria:**
- `make help` shows all available targets
- `make dev` starts development environment

---

### Task 5.3: Setup GitHub Actions CI/CD

**Command:**
```bash
/x:implement "Create .github/workflows/ci.yml GitHub Actions workflow: trigger on push/PR to main. Jobs: lint (pnpm lint), typecheck (pnpm typecheck), test (pnpm test with PostgreSQL and Redis services), build (pnpm build). Use pnpm cache, Node 24, Go 1.24, Python 3.14. Matrix for different apps if needed. Add .github/dependabot.yml for dependency updates"
```

**Deliverables:**
- `.github/workflows/ci.yml`
- `.github/dependabot.yml`

**Acceptance Criteria:**
- CI pipeline passes on push
- All jobs complete successfully

---

## Milestone 6: Verification

### Task 6.1: Test pnpm Install

**Command:**
```bash
pnpm install
```

**Acceptance Criteria:**
- All workspace packages recognized
- No dependency errors
- Lock file generated

---

### Task 6.2: Test Development Mode

**Command:**
```bash
make dev
# or: pnpm dev
```

**Acceptance Criteria:**
- Turborepo starts all services in parallel
- Go API running on :8080
- Next.js running on :3000
- Expo dev server running on :8081
- No startup errors

---

### Task 6.3: Test Build

**Command:**
```bash
make build
# or: pnpm build
```

**Acceptance Criteria:**
- All packages build successfully
- Go binary produced in apps/api/bin/
- Next.js production build in apps/web/.next/
- No TypeScript errors

---

### Task 6.4: Verify Health Endpoints

**Commands:**
```bash
# Go API
curl http://localhost:8080/health
# Expected: {"status": "ok"}

# Next.js
curl http://localhost:3000/api/health
# Expected: {"status": "ok"}
```

**Acceptance Criteria:**
- Both endpoints return 200 OK with JSON response
- Response time < 100ms

---

## Implementation Order (Recommended)

```bash
# Day 1 Morning (~4 hours)
/x:implement "Task 1.1: Initialize pnpm root project..."
/x:implement "Task 1.2: Configure Turborepo..."
/x:implement "Task 1.3: Setup global config files..."
/x:implement "Task 2.1: Create typescript-config..."
/x:implement "Task 2.2: Create eslint-config..."

# Day 1 Afternoon (~4 hours)
/x:implement "Task 2.3: Create @pareto/types..."
/x:implement "Task 2.4: Create @pareto/api-client..."
/x:implement "Task 2.5: Create @pareto/utils..."
/x:implement "Task 3.1: Create Go API skeleton..."

# Day 2 Morning (~4 hours)
/x:implement "Task 3.2: Create Python workers..."
/x:implement "Task 4.1: Create Next.js web app..."
/x:implement "Task 4.2: Create Expo mobile app..."

# Day 2 Afternoon (~2 hours)
/x:implement "Task 5.1: Docker compose..."
/x:implement "Task 5.2: Makefile..."
/x:implement "Task 5.3: GitHub Actions..."

# Verification (~1 hour)
make install
make dev
make build
```

---

## Success Criteria Checklist

After completing all tasks:

- [ ] `pnpm install` works at root
- [ ] `pnpm dev` starts all services
- [ ] `pnpm build` builds all apps
- [ ] `pnpm lint` passes
- [ ] `make docker-up` starts containers
- [ ] Go API responds at localhost:8080/health
- [ ] Next.js loads at localhost:3000
- [ ] Expo dev server starts without errors
- [ ] CI pipeline runs on push
- [ ] All shared packages (@pareto/*) importable

---

## Final Monorepo Structure

```
pareto/
├── apps/
│   ├── api/                    # Go modular monolith
│   │   ├── cmd/api/main.go
│   │   ├── internal/
│   │   │   ├── catalog/
│   │   │   ├── scraper/
│   │   │   ├── compare/
│   │   │   ├── affiliate/
│   │   │   └── shared/
│   │   ├── go.mod
│   │   └── Dockerfile
│   ├── web/                    # Next.js 16
│   │   ├── src/app/
│   │   ├── next.config.ts
│   │   └── Dockerfile
│   ├── mobile/                 # Expo SDK 53
│   │   ├── app/
│   │   ├── app.json
│   │   └── metro.config.js
│   └── workers/                # Python Celery
│       ├── src/
│       ├── pyproject.toml
│       └── Dockerfile
├── packages/
│   ├── api-client/             # @pareto/api-client
│   ├── eslint-config/          # @pareto/eslint-config
│   ├── types/                  # @pareto/types
│   ├── typescript-config/      # @pareto/typescript-config
│   └── utils/                  # @pareto/utils
├── docker/
│   ├── docker-compose.yml
│   └── docker-compose.prod.yml
├── .github/
│   ├── workflows/ci.yml
│   └── dependabot.yml
├── turbo.json
├── package.json
├── pnpm-workspace.yaml
├── Makefile
├── .gitignore
├── .editorconfig
└── .nvmrc
```

---

## Post-Implementation

After Foundation is complete:

1. **Update MASTERPLAN.md**: Mark Foundation as 100% complete
2. **Update foundation/README.md**: Mark M2 as complete
3. **Begin next initiative**: [Scraper](../milestones/scraper/)

---

**Next Initiative**: [Scraper Module](../milestones/scraper/)
**Back to**: [MASTERPLAN](../milestones/MASTERPLAN.md)
