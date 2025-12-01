# Implementation Section - Navigation

> Technical architecture, module specifications, and implementation details

## Quick Reference

| File | Purpose |
|------|---------|
| [README.md](./README.md) | Architecture overview |
| [data-flow.md](./data-flow.md) | Complete scraping → UI data pipeline |
| [scaling/](./scaling/) | Scaling strategy and architecture |

## Architecture Pattern

**Modular Monolith** - 4 services:
1. Go API (REST + orchestration)
2. Python Workers (parsing + Pareto)
3. Next.js Frontend (SSR + UI)
4. Expo Mobile (iOS + Android)

## Module Map

```
Go API (apps/api/)         Python Workers (apps/workers/)
------------------         ----------------------------
internal/catalog/          src/normalizer/
internal/scraper/          src/pareto/
internal/compare/          src/fetcher/
internal/affiliate/
internal/shared/

Frontend (apps/web/)       Mobile (apps/mobile/)
--------------------       ---------------------
app/                       app/
components/                components/
lib/                       lib/

Shared Packages (packages/)
---------------------------
@pareto/api-client
@pareto/types
@pareto/utils
```

## Key Technologies (December 2025)

| Component | Technology | Version |
|-----------|------------|---------|
| API | Go + Chi | 1.24.10 |
| Workers | Python + Celery | 3.14.0 |
| Frontend | Next.js | 16.0.3 |
| Mobile | Expo SDK | 53 |
| Database | PostgreSQL + TimescaleDB | 18.1 |
| Cache | Redis | 8.4.0 |

## Scaling Documentation

Comprehensive scaling strategy in `scaling/`:
- [README.md](./scaling/README.md) - Master scaling strategy
- [vertical-expansion.md](./scaling/vertical-expansion.md) - Category scaling (smartphones → SaaS → banking)
- [geographic-expansion.md](./scaling/geographic-expansion.md) - Multi-country (France → EU → Global)
- [platform-expansion.md](./scaling/platform-expansion.md) - API, B2B, white-label
- [infrastructure-scaling.md](./scaling/infrastructure-scaling.md) - VPS → Kubernetes
- [data-architecture.md](./scaling/data-architecture.md) - Multi-tenant data model

## Related Sections

- [Domain](../domain/) - Business rules
- [Development](../development/) - Setup guide
- [Milestones](../milestones/) - Roadmap
- [Stack Reference](../reference/stack/) - Technology documentation

## Original Specifications

Located in `../reference/specs/`:
- [blueprint.md](../reference/specs/blueprint.md) - Strategic vision
- [architecture.md](../reference/specs/architecture.md) - Architecture design
- [scrapper-module.md](../reference/specs/scrapper-module.md) - Scraper spec
- [normalizer-catalog.md](../reference/specs/normalizer-catalog.md) - Normalizer spec
- [comparaison-catalog.md](../reference/specs/comparaison-catalog.md) - Comparison spec
- [frontend.md](../reference/specs/frontend.md) - Frontend spec
- [infrastructure.md](../reference/specs/infrastructure.md) - Infra spec
