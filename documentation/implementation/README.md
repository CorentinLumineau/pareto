# Implementation - Technical Documentation

> **Architecture decisions, module specifications, and technical implementation details**

## Architecture Overview

The Pareto Comparator uses a **Modular Monolith** architecture - clean internal boundaries with single deployment. This is the right choice for a solo developer MVP.

```
                         [Internet]
                             |
                      [Cloudflare CDN]
                             |
                    [Dokploy VPS + Traefik]
                             |
        +------------+-------+-------+------------+
        |            |               |            |
   [Next.js]    [Go Monolith]   [Python Workers]  |
   Port 3000     Port 8000       (Celery)         |
        |            |               |            |
        +------------+-------+-------+------------+
                             |
              +------+-------+-------+------+
              |              |              |
         [PostgreSQL]    [Redis]    [TimescaleDB]
          Port 5432     Port 6379   (extension)
```

## Why Modular Monolith?

| Microservices Problem | Impact on Solo Dev |
|-----------------------|--------------------|
| 9 containers to deploy/monitor | Hours lost on ops |
| Inter-service network calls | Debugging nightmare |
| Distributed transactions | Complex saga patterns |
| Multiple repos/packages | Context switching |
| Service discovery | Unnecessary complexity |

**The Solution**: Clean internal boundaries that CAN become microservices later, but deployed as 2-3 services.

## Service Architecture

### Services (3 total)

| Service | Language | Port | Responsibility |
|---------|----------|------|----------------|
| **Go Monolith** | Go 1.23 | 8000 | All business logic, API, scraping orchestration |
| **Python Workers** | Python 3.13 | - | HTML parsing, Pareto calculation, heavy compute |
| **Next.js Frontend** | Node 22 | 3000 | SSR pages, React UI, SEO |

### Internal Modules (Go Monolith)

```
internal/
├── catalog/           # Products, prices, categories
│   ├── domain/        # Entities (Product, Price, Category)
│   ├── repository/    # Database access (PostgreSQL)
│   ├── service/       # Business logic
│   └── handler/       # HTTP handlers
├── scraper/           # Web scraping orchestration
│   ├── domain/        # Job, Retailer entities
│   ├── adapters/      # Retailer-specific scrapers
│   ├── service/       # Orchestrator, ProxyManager
│   └── handler/       # API endpoints
├── compare/           # Pareto comparison
│   ├── domain/        # Comparison entities
│   ├── service/       # Pareto service (delegates to Python)
│   └── handler/       # Compare API
├── affiliate/         # Revenue tracking
│   ├── domain/        # Link, Click entities
│   ├── service/       # Link generator, tracker
│   └── handler/       # Redirect endpoint
└── shared/            # Common infrastructure
    ├── database/      # PostgreSQL connection
    ├── cache/         # Redis client
    ├── queue/         # Job queue
    └── config/        # Configuration
```

### Python Workers

```
workers/src/
├── normalizer/        # HTML parsing pipeline
│   ├── base_extractor.py    # Abstract base class
│   ├── schemas.py           # Pydantic models
│   └── extractors/          # Retailer-specific
│       ├── amazon.py
│       ├── fnac.py
│       ├── cdiscount.py
│       ├── darty.py
│       ├── boulanger.py
│       └── ldlc.py
├── pareto/            # Pareto calculation
│   ├── calculator.py        # Pareto frontier
│   └── normalizer.py        # Z-score normalization
├── fetcher/           # Anti-bot bypass
│   └── fetcher.py           # curl_cffi with fingerprinting
└── tasks/             # Celery tasks
    └── celery_app.py
```

## Data Flow

### Scraping Pipeline

```
1. Scheduler triggers job (GitHub Actions cron / manual)
       |
2. Go Orchestrator queues URLs per retailer
       |
3. Python Worker fetches with curl_cffi (anti-bot)
       |
4. Raw HTML stored in Redis (24h TTL)
       |
5. Normalizer extracts structured data (BeautifulSoup)
       |
6. Entity Resolution matches to canonical product
       |
7. Price entry added to TimescaleDB
       |
8. Cache invalidated for affected products
```

### User Comparison Flow

```
1. User visits /compare/laptops
       |
2. Next.js SSR fetches from Go API
       |
3. Go API checks Redis cache
       |
4. Cache miss: Fetch products from PostgreSQL
       |
5. Go API calls Python worker for Pareto calculation
       |
6. Python returns Pareto frontier + scores
       |
7. Go caches result (1h TTL)
       |
8. Next.js renders with Pareto visualization
       |
9. User clicks "Voir l'offre" -> Affiliate redirect
```

## Database Schema

Database schema is managed declaratively with **Atlas** (Prisma-like DX).

**Source of Truth**: `apps/api/schema.sql`

### Quick Reference

```bash
# Edit schema, generate migration, apply
vim apps/api/schema.sql
make db-diff name=add_feature
make db-apply
```

See [Database Management](../development/database.md) for full documentation.

### Core Tables

| Table | Purpose |
|-------|---------|
| `products` | Canonical product data from brand websites |
| `variants` | Color/storage combinations with EAN |
| `offers` | Marketplace prices per retailer |
| `price_history` | Time-series for trends (TimescaleDB) |
| `retailers` | Store configuration + affiliate setup |
| `categories` | Hierarchical with JSONB attribute schema |
| `scrape_jobs` | Job queue with retry logic |
| `affiliate_clicks` | Revenue tracking (GDPR-compliant) |

### Key Features

- **JSONB Attributes** - 40+ product specs stored flexibly
- **GIN Indexes** - Fast JSONB and trigram search
- **Auto-triggers** - `updated_at` managed automatically
- **Seed Data** - Smartphones category + 6 French retailers

## API Design

### Public Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/products` | List products with filters |
| GET | `/api/products/:slug` | Get product detail |
| GET | `/api/products/:id/prices` | Get price history |
| GET | `/api/categories` | List categories |
| GET | `/api/search?q=...` | Full-text search |
| POST | `/api/compare` | Pareto comparison |
| GET | `/go/:retailer/:product` | Affiliate redirect |

### Internal Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/internal/products` | Create/update product |
| POST | `/internal/prices` | Add price entry |
| POST | `/internal/scrape/trigger` | Trigger scrape job |
| GET | `/internal/jobs/:id` | Get job status |

## Architecture Decision Records

### ADR-001: Modular Monolith over Microservices
- **Context**: Solo developer building MVP
- **Decision**: Use modular monolith with clean package boundaries
- **Rationale**: Faster development, simpler deployment, easier debugging
- **Consequences**: Must refactor if team grows or scale demands it

### ADR-002: Go + Python Hybrid
- **Context**: Need both performance (API) and ecosystem (ML/parsing)
- **Decision**: Go for API/orchestration, Python for heavy compute
- **Rationale**: Best of both worlds
- **Consequences**: Inter-process communication overhead (Redis pub/sub)

### ADR-003: TimescaleDB for Price History
- **Context**: Millions of price entries over time
- **Decision**: Use TimescaleDB extension on PostgreSQL
- **Rationale**: Automatic partitioning, compression, retention policies
- **Consequences**: Slightly more complex setup

### ADR-004: curl_cffi for Anti-Bot Bypass
- **Context**: Major retailers use DataDome/Cloudflare
- **Decision**: Use curl_cffi with TLS fingerprint impersonation
- **Rationale**: 90%+ success rate on protected sites
- **Consequences**: Requires residential proxies (~$7/GB)

### ADR-005: Next.js 15 with App Router
- **Context**: SEO is critical for organic traffic
- **Decision**: Use Next.js 15 with React Server Components
- **Rationale**: Best-in-class SSR, Schema.org support, fast
- **Consequences**: Learning curve for RSC patterns

## Files in this Section

- [data-flow.md](./data-flow.md) - Complete scraping → UI data pipeline
- [scraping-strategy.md](./scraping-strategy.md) - Brand-first scraping approach
- [Scaling](./scaling/) - Multi-dimensional scaling strategy
  - [README.md](./scaling/README.md) - Master scaling overview
  - [vertical-expansion.md](./scaling/vertical-expansion.md) - Category scaling
  - [geographic-expansion.md](./scaling/geographic-expansion.md) - Multi-country
  - [platform-expansion.md](./scaling/platform-expansion.md) - API, B2B, white-label
  - [infrastructure-scaling.md](./scaling/infrastructure-scaling.md) - VPS → Kubernetes
  - [data-architecture.md](./scaling/data-architecture.md) - Multi-tenant data
- Database schema: [`apps/api/schema.sql`](../../apps/api/schema.sql) (source of truth)
- Database docs: [../development/database.md](../development/database.md)

---

**See Also**:
- Original specs: [blueprint.md](../reference/specs/blueprint.md), [architecture.md](../reference/specs/architecture.md)
- [Domain](../domain/) for business rules
- [Milestones](../milestones/) for implementation roadmap
