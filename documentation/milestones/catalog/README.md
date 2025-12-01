# Catalog Initiative

> **Product database with JSONB attributes, price history, and EAN-based matching**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                           CATALOG INITIATIVE                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     ⏳ PENDING (5% pre-done)                                        ║
║  Effort:     2 weeks (10 days)                                               ║
║  Depends:    Normalizer                                                      ║
║  Unlocks:    Comparison, Affiliate, Frontend                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Objective

Build the central product catalog with:
- **Products**: From brand websites with 40+ attributes in JSONB
- **Offers**: Marketplace prices linked via EAN
- **Price History**: TimescaleDB hypertables for time-series data
- **REST API**: Internal (for workers) + Public (for frontend)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       CATALOG MODULE                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Normalizer ─────► Internal API ─────► PostgreSQL              │
│   (Python)            (Go)             + TimescaleDB            │
│                                              │                  │
│                                              ▼                  │
│   Frontend ◄──────── Public API ◄────── Redis Cache             │
│   (Next.js)           (Go)              (hot data)              │
│                                                                 │
│                          │                                      │
│                          ▼                                      │
│                    Product Entity                               │
│                          │                                      │
│           ┌──────────────┼──────────────┐                       │
│           ▼              ▼              ▼                       │
│        Offers        Prices         Attributes                  │
│     (per retailer)  (history)     (specs, EAN)                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Database | PostgreSQL 18.1 | Product storage |
| Time-series | TimescaleDB 2.23 | Price history |
| Cache | Redis 8.4 | Query caching |
| API | Go + Chi | REST endpoints |
| Database | pgx | Direct SQL (no ORM) |

## Phases

| # | Phase | Effort | Description |
|---|-------|--------|-------------|
| 01 | [Database Schema](./01-schema.md) | 2d | Tables, indexes, TimescaleDB |
| 02 | [Repository Layer](./02-repository.md) | 3d | GORM models, queries |
| 03 | [Internal API](./03-internal-api.md) | 2d | Normalizer integration |
| 04 | [Public API](./04-public-api.md) | 3d | Frontend endpoints |

## Data Model

### Product Entity

```
┌────────────────────────────────────────────────────────────┐
│                        PRODUCT                             │
├────────────────────────────────────────────────────────────┤
│ id              UUID            Primary Key                │
│ ean             VARCHAR(13)     Unique (nullable)          │
│ brand           VARCHAR(100)    Indexed                    │
│ model           VARCHAR(200)    Indexed                    │
│ title           VARCHAR(500)    Search indexed             │
│ category_id     UUID            FK → categories            │
│ attributes      JSONB           Technical specs            │
│ created_at      TIMESTAMPTZ                                │
│ updated_at      TIMESTAMPTZ                                │
└────────────────────────────────────────────────────────────┘
                              │
                              │ 1:N
                              ▼
┌────────────────────────────────────────────────────────────┐
│                         OFFER                              │
├────────────────────────────────────────────────────────────┤
│ id              UUID            Primary Key                │
│ product_id      UUID            FK → products              │
│ retailer_id     VARCHAR(50)     Indexed                    │
│ external_id     VARCHAR(100)    Retailer's SKU             │
│ url             VARCHAR(2000)   Product page               │
│ affiliate_url   VARCHAR(2000)   Tracked link               │
│ in_stock        BOOLEAN                                    │
│ last_seen_at    TIMESTAMPTZ                                │
│ created_at      TIMESTAMPTZ                                │
└────────────────────────────────────────────────────────────┘
                              │
                              │ 1:N (TimescaleDB hypertable)
                              ▼
┌────────────────────────────────────────────────────────────┐
│                         PRICE                              │
├────────────────────────────────────────────────────────────┤
│ time            TIMESTAMPTZ     Partition key              │
│ offer_id        UUID            FK → offers                │
│ price           DECIMAL(10,2)   Current price              │
│ currency        VARCHAR(3)      EUR                        │
│ was_price       DECIMAL(10,2)   Original price (nullable)  │
└────────────────────────────────────────────────────────────┘
```

## API Endpoints

### Public API (Frontend)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/products` | List products (paginated) |
| GET | `/api/v1/products/:id` | Product details |
| GET | `/api/v1/products/:id/offers` | Product offers |
| GET | `/api/v1/products/:id/prices` | Price history |
| GET | `/api/v1/products/search` | Full-text search |
| GET | `/api/v1/categories` | Category tree |

### Internal API (Normalizer)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/internal/products` | Create/update product |
| POST | `/internal/offers` | Add offer |
| POST | `/internal/prices` | Record price |
| GET | `/internal/products/by-ean/:ean` | Lookup by EAN |
| POST | `/internal/products/match` | Entity matching |

## Caching Strategy

```
Cache Layers:
├── L1: In-memory (10s TTL)
│   └── Hot products, search results
├── L2: Redis (5min TTL)
│   └── Product details, category tree
└── L3: PostgreSQL
    └── Source of truth
```

## Success Metrics

| Metric | Target |
|--------|--------|
| Products stored | >500 smartphones |
| API latency (p95) | <100ms |
| Cache hit rate | >80% |
| Price history retention | 1 year |

## Deliverables

- [ ] PostgreSQL schema with TimescaleDB
- [ ] GORM models and migrations
- [ ] Internal API for normalizer
- [ ] Public API for frontend
- [ ] Redis caching layer
- [ ] Full-text search
- [ ] Price history queries

---

**Depends on**: [Normalizer](../normalizer/)
**Unlocks**: [Comparison](../comparison/), [Affiliate](../affiliate/), [Frontend](../frontend/)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
