# Scaling Strategy - Master Document

> **Comprehensive scaling roadmap for Pareto Comparator**

## Overview

Pareto is designed from Day 1 for multi-dimensional scaling:
- **Geographic**: France → EU → Global
- **Vertical**: Smartphones → All consumer electronics → SaaS → Financial products
- **Platform**: Web/Mobile → API → B2B → White-label
- **Infrastructure**: Single VPS → Kubernetes cluster

## Scaling Dimensions

```
                         SCALING MATRIX
    ┌─────────────────────────────────────────────────────┐
    │                                                     │
    │   GEOGRAPHIC          VERTICAL         PLATFORM    │
    │   ───────────        ─────────         ─────────   │
    │   France (MVP)       Smartphones       Web App     │
    │        ↓                  ↓                ↓       │
    │   EU Countries       Laptops           Mobile App  │
    │        ↓             Tablets               ↓       │
    │   Global             Headphones        Public API  │
    │                      Smart Home            ↓       │
    │                          ↓             B2B Portal  │
    │                      SaaS Tools            ↓       │
    │                          ↓             White-label │
    │                      Banking/Finance               │
    │                                                     │
    └─────────────────────────────────────────────────────┘
```

## File Structure

| Document | Purpose | Priority |
|----------|---------|----------|
| [geographic-expansion.md](./geographic-expansion.md) | Multi-country architecture | HIGH |
| [vertical-expansion.md](./vertical-expansion.md) | Category schemas, vertical onboarding | HIGH |
| [platform-expansion.md](./platform-expansion.md) | API, B2B, white-label | MEDIUM |
| [infrastructure-scaling.md](./infrastructure-scaling.md) | VPS → K8s migration path | MEDIUM |
| [data-architecture.md](./data-architecture.md) | Multi-tenant data model | HIGH |

## Scaling Timeline

### Phase 1: MVP Foundation (Current)
```
Target: Validate product-market fit
Scope: France, Smartphones, Web + Mobile
Infrastructure: Single VPS (Dokploy)
Data: Single-tenant PostgreSQL
```

### Phase 2: Vertical Expansion
```
Trigger: 10K MAU on smartphones
Scope: Add laptops, tablets, headphones
Changes:
  - Flexible attribute schemas (JSONB)
  - Category-specific normalizers
  - Additional affiliate programs
```

### Phase 3: Geographic Expansion
```
Trigger: 50K MAU France
Scope: Germany, Spain, UK, Italy
Changes:
  - Multi-currency support
  - Localized retailers per country
  - i18n infrastructure
  - GDPR compliance per jurisdiction
```

### Phase 4: Platform Expansion
```
Trigger: 100K MAU EU
Scope: Public API, B2B partnerships
Changes:
  - Rate-limited public API
  - API key management
  - Usage-based billing
  - White-label theming
```

### Phase 5: Infrastructure Scale
```
Trigger: 500K MAU or performance bottleneck
Scope: Kubernetes migration
Changes:
  - Container orchestration
  - Horizontal auto-scaling
  - Database read replicas
  - CDN edge caching
```

## Architecture Principles for Scale

### 1. Loose Coupling
```
All modules communicate via:
- REST APIs (sync)
- Redis Pub/Sub (async)
- Celery tasks (background)

No direct database access between modules.
```

### 2. Schema Flexibility
```sql
-- Products use JSONB for category-specific attributes
CREATE TABLE products (
    id UUID PRIMARY KEY,
    category_id UUID NOT NULL,
    name TEXT NOT NULL,
    brand TEXT,
    attributes JSONB NOT NULL,  -- Flexible per category
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Category defines expected schema
CREATE TABLE categories (
    id UUID PRIMARY KEY,
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    attribute_schema JSONB NOT NULL,  -- JSON Schema validation
    comparison_objectives JSONB NOT NULL
);
```

### 3. Multi-Tenancy Ready
```
Current: Single-tenant (France, all users)
Future: Organization-based tenancy for B2B

Tenant isolation via:
- Row-level security (RLS)
- Organization ID on all tables
- Separate API keys per tenant
```

### 4. Stateless Services
```
All services are stateless:
- Go API: No session state, JWT auth
- Python Workers: No local state, Redis for queues
- Next.js: Server Components, no client state

State lives in:
- PostgreSQL (persistent)
- Redis (ephemeral + cache)
```

## Key Scaling Metrics

### Infrastructure Thresholds

| Metric | Current Capacity | Scale Trigger |
|--------|------------------|---------------|
| API Requests/sec | 100 | 80% sustained |
| Database Connections | 100 | 80 connections |
| Redis Memory | 1GB | 800MB used |
| Worker Queue Depth | 1000 | 800 pending |
| Response P95 | 200ms | >500ms |

### Business Thresholds

| Metric | Phase | Action |
|--------|-------|--------|
| MAU | 10K | Add verticals |
| MAU | 50K | EU expansion |
| MAU | 100K | API product |
| Revenue/mo | €10K | Dedicated ops |
| Revenue/mo | €50K | K8s migration |

## Quick Reference

### Adding a New Country
```bash
# See geographic-expansion.md
1. Add retailers to retailer registry
2. Configure currency and locale
3. Add country-specific scrapers
4. Update i18n strings
5. Enable in feature flags
```

### Adding a New Vertical
```bash
# See vertical-expansion.md
1. Define attribute schema
2. Define comparison objectives
3. Create category normalizers
4. Add to frontend category tree
5. Configure affiliate programs
```

### Enabling API Access
```bash
# See platform-expansion.md
1. Generate API key
2. Configure rate limits
3. Set usage quotas
4. Enable billing
```

## Related Documentation

- [Architecture](../README.md) - Core architecture decisions
- [Domain](../../domain/) - Business logic and Pareto algorithms
- [Infrastructure Spec](../../reference/specs/infrastructure.md) - Original infra spec

---

**Last Updated**: 2025-12-01
