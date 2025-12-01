# Implementation Section - Navigation

> Technical architecture, module specifications, and implementation details

## Quick Reference

| File | Purpose |
|------|---------|
| [README.md](./README.md) | Architecture overview |
| [modules/](./modules/) | Detailed module specs |
| [adrs/](./adrs/) | Architecture decisions |
| [api/](./api/) | API specifications |
| [database/](./database/) | Schema documentation |

## Architecture Pattern

**Modular Monolith** - 3 services:
1. Go Monolith (API + orchestration)
2. Python Workers (parsing + Pareto)
3. Next.js Frontend (SSR + UI)

## Module Map

```
Go Monolith           Python Workers        Frontend
-----------           --------------        --------
internal/catalog/     src/normalizer/       app/
internal/scraper/     src/pareto/           components/
internal/compare/     src/fetcher/          lib/
internal/affiliate/
```

## Key Technologies

| Component | Technology | Version |
|-----------|------------|---------|
| API | Go + Chi | 1.23.4 |
| Workers | Python + Celery | 3.13.1 |
| Frontend | Next.js | 15.1.0 |
| Database | PostgreSQL + TimescaleDB | 17.2 |
| Cache | Redis | 7.4.1 |

## Related Sections

- [Domain](../domain/) - Business rules
- [Development](../development/) - Setup guide
- [Milestones](../milestones/) - Roadmap

## Original Specifications

Located in `../reference/specs/`:
- [blueprint.md](../reference/specs/blueprint.md) - Strategic vision
- [architecture.md](../reference/specs/architecture.md) - Architecture design
- [scrapper-module.md](../reference/specs/scrapper-module.md) - Scraper spec
- [normalizer-catalog.md](../reference/specs/normalizer-catalog.md) - Normalizer spec
- [comparaison-catalog.md](../reference/specs/comparaison-catalog.md) - Comparison spec
- [frontend.md](../reference/specs/frontend.md) - Frontend spec
- [infrastructure.md](../reference/specs/infrastructure.md) - Infra spec
