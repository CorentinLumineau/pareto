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
└── documentation/
    ├── CLAUDE.md                       # Documentation hub
    ├── config.yaml                     # Stack configuration
    ├── domain/                         # Business logic
    │   ├── README.md                   # Domain overview
    │   └── pareto-optimization.md      # Pareto algorithm explained
    ├── development/                    # Setup guides
    │   └── README.md                   # Local development setup
    ├── implementation/                 # Technical specs
    │   └── README.md                   # Architecture details
    ├── milestones/                     # Roadmap & initiatives
    │   ├── MASTERPLAN.md               # Overall roadmap
    │   ├── foundation/                 # Infrastructure setup
    │   ├── scraper/                    # Web scraping module
    │   ├── normalizer/                 # Data normalization
    │   ├── catalog/                    # Product catalog
    │   ├── comparison/                 # Pareto engine
    │   ├── affiliate/                  # Revenue tracking
    │   ├── frontend/                   # Web application
    │   ├── mobile/                     # Mobile app
    │   └── launch/                     # Go-live checklist
    └── reference/                      # Stack docs & specs
        ├── specs/                      # Original specifications
        │   ├── blueprint.md            # Strategic vision
        │   ├── architecture.md         # Technical architecture
        │   ├── scrapper-module.md      # Scraping specification
        │   ├── normalizer-catalog.md   # Data processing
        │   ├── comparaison-catalog.md  # Pareto + affiliate
        │   ├── frontend.md             # Frontend specification
        │   └── infrastructure.md       # DevOps specification
        └── stack/                      # Technology documentation
            ├── README.md               # Stack overview
            ├── go.md                   # Go 1.24 + Chi router
            ├── python.md               # Python 3.14 + Celery
            ├── nextjs.md               # Next.js 16
            ├── react.md                # React 19.2
            ├── tailwind.md             # Tailwind CSS v4
            ├── expo.md                 # Expo SDK 53
            ├── react-native.md         # React Native 0.79
            ├── postgresql.md           # PostgreSQL 18
            ├── redis.md                # Redis 8.4
            ├── docker.md               # Docker 29
            └── cloudflare.md           # Cloudflare Tunnel
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
| View roadmap | `documentation/milestones/MASTERPLAN.md` |
| Domain rules | `documentation/domain/README.md` |
| Technical specs | `documentation/implementation/README.md` |
| Stack reference | `documentation/reference/stack/README.md` |

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

**Status**: Pre-MVP | **Owner**: @clumineau | **Updated**: 2025-12-01 | **Stack**: December 2025
