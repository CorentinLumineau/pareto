# Pareto Comparator

> **Multi-objective comparison SaaS platform for the French market**

## Project Overview

**Pareto Comparator** is a next-generation price comparison platform that uses **Pareto optimization** to help users find the best trade-offs across multiple criteria (price, performance, battery life, etc.) - not just the cheapest option.

| Attribute | Value |
|-----------|-------|
| **Target Market** | France (initially) |
| **MVP Vertical** | Smartphones (single focus) |
| **Retailers** | Amazon.fr, Fnac.com, Cdiscount.com, Darty.com, Boulanger.com, LDLC.com |
| **Budget** | <50EUR/month |
| **Goal** | Validate business model |

## Quick Start

```bash
# 1. Read the strategic blueprint
cat blueprint.md

# 2. Understand the architecture
cat architecture.md

# 3. Follow the development setup
cat documentation/development/README.md

# 4. Start the MVP initiative
cat documentation/milestones/initiatives/001-mvp-launch/README.md
```

## Documentation Structure

```
pareto/
├── CLAUDE.md                  # This file - project entry point
├── blueprint.md               # Strategic vision, market analysis
├── architecture.md            # Technical architecture (modular monolith)
├── scrapper-module.md         # Scraping specification
├── normalizer-catalog.md      # Data processing pipeline
├── comparaison-catalog.md     # Pareto engine + affiliate
├── frontend.md                # Next.js frontend spec
├── infrastructure.md          # DevOps specification
└── documentation/             # Structured documentation
    ├── config.yaml            # Stack configuration (VALIDATED)
    ├── CLAUDE.md              # Documentation hub
    ├── domain/                # Business logic
    ├── development/           # Setup guides
    ├── implementation/        # Technical specs
    ├── milestones/            # Roadmap & initiatives
    └── reference/             # Stack docs
```

## Validated Technology Stack (Dec 2025)

### Backend
| Technology | Version | Purpose |
|------------|---------|---------|
| **Go** | 1.23.4 | Modular Monolith API |
| **Gin** | 1.10.0 | HTTP router |
| **GORM** | 1.25+ | ORM for PostgreSQL |
| **Python** | 3.13.1 | Workers |
| **Celery** | 5.4+ | Task queue |

### Frontend
| Technology | Version | Purpose |
|------------|---------|---------|
| **Next.js** | 15.1.0 | SSR/RSC App Router |
| **React** | 19.0.0 | UI library |
| **Tailwind CSS** | 4.0.0 | Styling |
| **TanStack Query** | 5.62+ | Data fetching |
| **TanStack Table** | 8.20+ | Product tables |
| **TanStack Form** | 0.34+ | Forms |
| **shadcn/ui** | latest | UI components |
| **Recharts** | 2.14+ | Pareto visualization |
| **Zod** | 3.24+ | Validation |

### Infrastructure
| Technology | Version | Purpose |
|------------|---------|---------|
| **PostgreSQL** | 17.2 | Primary database |
| **TimescaleDB** | 2.17 | Price history |
| **Redis** | 7.4.1 | Cache + Celery broker |
| **Dokploy** | latest | Self-hosted deployment |
| **Hetzner** | CPX21 | VPS (~8EUR/month) |

## Architecture

```
                    [Users]
                       |
                  [Cloudflare]
                       |
              [Dokploy VPS - Traefik]
                       |
        +------+-------+-------+
        |      |               |
   [Next.js] [Go/Gin]    [Python/Celery]
   TanStack   GORM         curl_cffi
        |      |               |
        +------+-------+-------+
                       |
              [PostgreSQL + Redis]
```

**Pattern**: Modular Monolith (YAGNI-first)
**Services**: 3 (Go API, Python Workers, Next.js)
**Rationale**: Solo developer, MVP validation, simplicity

## Key Differentiator

Traditional comparators: Sort by price
**Pareto Comparator**: Find Pareto-optimal products

A product is **Pareto-optimal** if no other product beats it on ALL criteria. Users adjust weights for their priorities, and the system shows only the mathematically optimal choices.

## Budget-Conscious MVP Approach

| Item | Cost | Status |
|------|------|--------|
| VPS (Hetzner CPX21) | ~8EUR/month | Pending |
| Domain | ~12EUR/year | Pending |
| Proxies | 0-15EUR/month | Start datacenter |
| Affiliates | 0EUR | Apply after traffic |
| Legal (SASU) | 0EUR | Defer until launch |
| **Total** | **<30EUR/month** | |

## Key Files for Development

| Task | Read |
|------|------|
| Understand the vision | `blueprint.md` |
| Understand architecture | `architecture.md` |
| Stack configuration | `documentation/config.yaml` |
| Setup development env | `documentation/development/README.md` |
| Start building | `documentation/milestones/initiatives/001-mvp-launch/README.md` |
| Domain rules | `documentation/domain/README.md` |
| Technical specs | `documentation/implementation/README.md` |

## Commands

```bash
# Development
make dev           # Start all services
make test          # Run all tests
make lint          # Lint code

# Database
make migrate-up    # Run migrations
make seed          # Seed test data

# Deployment
make build         # Build Docker images
make deploy        # Deploy to production
```

## Legal Requirements (France)

- **Decree 2017-1434**: Transparency page required
- **GDPR**: IP hashing, no raw personal data
- **Affiliate Disclosure**: "Sponsorise" labels mandatory

---

**Status**: Pre-MVP | **Owner**: @clumineau | **Updated**: 2025-12-01 | **Stack**: Validated
