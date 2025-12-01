# Pareto Comparator - Documentation Hub

> **Navigation hub for the Pareto Comparator project documentation**

## Quick Links

| Section | Purpose | Key Files |
|---------|---------|-----------|
| [Domain](./domain/) | Business logic, Pareto algorithms, comparison rules | [Overview](./domain/README.md), [Pareto Logic](./domain/pareto-optimization.md) |
| [Development](./development/) | Setup, workflows, contribution | [Getting Started](./development/README.md) |
| [Implementation](./implementation/) | Technical specs, architecture, scaling | [Architecture](./implementation/README.md), [Scaling](./implementation/scaling/) |
| [Milestones](./milestones/) | Roadmap, initiatives, phases | [MASTERPLAN](./milestones/MASTERPLAN.md) |
| [Reference](./reference/) | Stack docs, API specs, original specs | [Stack](./reference/stack/README.md), [Specs](./reference/specs/) |

## Project Status

```
Phase: PRE-MVP
Status: Planning & Setup
Target: MVP Launch (Smartphones - France)
Stack: December 2025 (Go 1.24, Python 3.14, Next.js 16, Expo 53)
```

## Architecture Overview

```
                    [Users]
                       |
                  [Cloudflare]
                       |
              [Dokploy VPS - Traefik]
                       |
        +------+-------+-------+
        |      |               |
   [Next.js] [Go API]    [Python Workers]
   React 19   Chi          curl_cffi
   Tailwind   pgx          paretoset
        |      |               |
        +------+-------+-------+
                       |
              [PostgreSQL + Redis]
               TimescaleDB   8.4
```

## Module Map

| Module | Language | Responsibility |
|--------|----------|----------------|
| `apps/api/internal/catalog/` | Go | Products, prices, categories |
| `apps/api/internal/scraper/` | Go | Job orchestration, proxies |
| `apps/api/internal/compare/` | Go | Pareto API (delegates to Python) |
| `apps/api/internal/affiliate/` | Go | Link generation, click tracking |
| `apps/workers/src/normalizer/` | Python | HTML parsing, data extraction |
| `apps/workers/src/pareto/` | Python | Pareto calculation, z-scores |
| `apps/web/` | Next.js | SSR pages, comparison UI |
| `apps/mobile/` | Expo | iOS/Android app |

## Key Principles

1. **YAGNI First** - Build only what's needed for MVP validation
2. **Modular Monolith** - Clean boundaries, single deployment
3. **Pareto Value** - Multi-objective optimization as differentiator
4. **France First** - French retailers, French compliance, then expand
5. **Scale Ready** - Architecture designed for multi-dimensional growth
6. **Quality Enforced** - `make verify` with >90% coverage, strict types, security scanning

## Scaling Dimensions

```
GEOGRAPHIC          VERTICAL            PLATFORM            INFRASTRUCTURE
──────────          ────────            ────────            ──────────────
France (MVP)        Smartphones         Web/Mobile          Single VPS
     ↓                   ↓                  ↓                    ↓
EU Countries        Consumer Elec       Public API          Multi-VPS
     ↓                   ↓                  ↓                    ↓
Global              SaaS/Banking        White-Label         Kubernetes
```

See [implementation/scaling/](./implementation/scaling/) for complete scaling documentation.

## Getting Started

```bash
# 1. Read the business context
cat reference/specs/blueprint.md

# 2. Understand the architecture
cat reference/specs/architecture.md

# 3. Start with development setup
cat development/README.md

# 4. Follow the MVP roadmap
cat milestones/MASTERPLAN.md

# 5. Check stack documentation
cat reference/stack/README.md
```

## Original Specifications

The project started with detailed specification documents (now in `reference/specs/`):
- [blueprint.md](./reference/specs/blueprint.md) - Strategic vision, market analysis
- [architecture.md](./reference/specs/architecture.md) - Technical architecture decisions
- [scrapper-module.md](./reference/specs/scrapper-module.md) - Scraping module specification
- [normalizer-catalog.md](./reference/specs/normalizer-catalog.md) - Data processing pipeline
- [comparaison-catalog.md](./reference/specs/comparaison-catalog.md) - Pareto and affiliate logic
- [frontend.md](./reference/specs/frontend.md) - Frontend specification
- [infrastructure.md](./reference/specs/infrastructure.md) - DevOps and deployment

## Stack Documentation

Complete technology guides in `reference/stack/`:
- [Go 1.24](./reference/stack/go.md) - Chi router, pgx, go-redis
- [Python 3.14](./reference/stack/python.md) - Celery, curl_cffi, paretoset
- [Next.js 16](./reference/stack/nextjs.md) - Turbopack, PPR, Server Components
- [React 19.2](./reference/stack/react.md) - Actions, useOptimistic
- [Tailwind v4](./reference/stack/tailwind.md) - CSS-first configuration
- [Expo SDK 53](./reference/stack/expo.md) - Expo Router, NativeWind
- [PostgreSQL 18](./reference/stack/postgresql.md) - TimescaleDB, UUIDv7
- [Redis 8.4](./reference/stack/redis.md) - JSON, RediSearch, Pub/Sub
- [Docker 29](./reference/stack/docker.md) - Compose, multi-stage builds
- [Cloudflare](./reference/stack/cloudflare.md) - Tunnel, CDN, WAF

---

**Last Updated**: 2025-12-01
**Maintained By**: @clumineau
