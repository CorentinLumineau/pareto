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
cat documentation/reference/specs/blueprint.md

# 2. Understand the architecture
cat documentation/reference/specs/architecture.md

# 3. Follow the development setup
cat documentation/development/README.md

# 4. Check the roadmap
cat documentation/milestones/MASTERPLAN.md
```

## Documentation Structure

```
pareto/
├── CLAUDE.md                           # This file - project entry point
├── Makefile                            # Main entry (includes make/*.mk)
├── make/                               # Modular Makefile (SOLID)
│   ├── dev.mk                          # Development commands
│   ├── quality.mk                      # Lint, test, verify
│   ├── docker.mk                       # Docker management
│   ├── devcontainer.mk                 # VS Code devcontainer
│   └── db.mk                           # Atlas database commands
├── apps/api/
│   ├── schema.sql                      # Database schema (source of truth)
│   ├── atlas.hcl                       # Atlas configuration
│   └── migrations/                     # Auto-generated migrations
└── documentation/
    ├── CLAUDE.md                       # Documentation hub
    ├── config.yaml                     # Stack configuration
    ├── domain/                         # Business logic
    │   ├── README.md                   # Domain overview
    │   ├── pareto-optimization.md      # Pareto algorithm
    │   └── quality-enforcement.md      # Quality standards
    ├── development/                    # Setup guides
    │   ├── README.md                   # Local development setup
    │   ├── database.md                 # Atlas migrations guide
    │   └── devcontainer.md             # Devcontainer setup
    ├── implementation/                 # Technical specs
    │   ├── README.md                   # Architecture details
    │   ├── data-flow.md                # Scraping → UI pipeline
    │   ├── scraping-strategy.md        # Brand-first approach
    │   └── scaling/                    # Scaling documentation
    ├── milestones/                     # Roadmap & initiatives
    │   ├── MASTERPLAN.md               # Overall roadmap
    │   ├── quality-enforcement/        # Quality initiative
    │   └── ...                         # Other initiatives
    └── reference/                      # Stack docs & specs
        ├── specs/                      # Original specifications
        └── stack/                      # Technology documentation
```

## Technology Stack (December 2025)

### Backend

| Technology | Version | Purpose |
|------------|---------|---------|
| **Go** | 1.24.10 | API server (Chi router) |
| **Python** | 3.14.0 | Workers (Celery, curl_cffi, paretoset) |
| **PostgreSQL** | 18.1 | Primary database + TimescaleDB |
| **Redis** | 8.4.0 | Cache + message queue |

### Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| **Next.js** | 16.0.3 | SSR/RSC with Turbopack |
| **React** | 19.2.0 | UI library |
| **Tailwind CSS** | 4.1.17 | Styling |
| **TanStack Query** | 5.84+ | Data fetching |
| **shadcn/ui** | latest | UI components |
| **Recharts** | 2.14+ | Pareto visualization |

### Mobile

| Technology | Version | Purpose |
|------------|---------|---------|
| **Expo SDK** | 53 | Cross-platform framework |
| **React Native** | 0.79.0 | Mobile runtime |
| **NativeWind** | 4.x | Tailwind for mobile |

### Infrastructure

| Technology | Version | Purpose |
|------------|---------|---------|
| **Docker** | 29.1.1 | Containerization |
| **Cloudflare** | - | CDN + Tunnel |
| **Dokploy** | latest | Self-hosted PaaS |
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
   [Next.js] [Go API]    [Python Workers]
   React 19   Chi          curl_cffi
   Tailwind   pgx          paretoset
        |      |               |
        +------+-------+-------+
                       |
              [PostgreSQL + Redis]
               TimescaleDB
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
| Understand the vision | `documentation/reference/specs/blueprint.md` |
| Understand architecture | `documentation/reference/specs/architecture.md` |
| Stack configuration | `documentation/config.yaml` |
| Setup development env | `documentation/development/README.md` |
| Database management | `documentation/development/database.md` |
| Database schema | `apps/api/schema.sql` |
| View roadmap | `documentation/milestones/MASTERPLAN.md` |
| Domain rules | `documentation/domain/README.md` |
| Technical specs | `documentation/implementation/README.md` |
| Stack reference | `documentation/reference/stack/README.md` |

## Commands

Makefile is modular (SOLID) - see `make/` directory.

```bash
# Development (make/dev.mk)
make install       # Install dependencies + hooks
make dev           # Start all services
make verify        # Run ALL quality checks

# Quality (make/quality.mk)
make lint          # Run linters
make test          # Run all tests
make typecheck     # Type checking

# Database (make/db.mk) - Atlas (Prisma-like DX)
make db-diff name=add_feature  # Generate migration
make db-apply                  # Apply migrations
make db-status                 # Check status

# Devcontainer (make/devcontainer.mk)
make devcontainer-up      # Start devcontainer
make devcontainer-shell   # Open shell

# Docker (make/docker.mk)
make docker-up     # Start containers
make build         # Build images
```

## Legal Requirements (France)

- **Decree 2017-1434**: Transparency page required
- **GDPR**: IP hashing, no raw personal data
- **Affiliate Disclosure**: "Sponsorise" labels mandatory

---

**Status**: Pre-MVP | **Owner**: @clumineau | **Updated**: 2025-12-01 | **Stack**: December 2025
