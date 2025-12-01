# Pareto Comparator - Documentation Hub

> **Navigation hub for the Pareto Comparator project documentation**

## Quick Links

| Section | Purpose | Key Files |
|---------|---------|-----------|
| [Domain](./domain/) | Business logic, Pareto algorithms, comparison rules | [Overview](./domain/README.md), [Pareto Logic](./domain/pareto-optimization.md) |
| [Development](./development/) | Setup, workflows, contribution | [Getting Started](./development/README.md), [Local Setup](./development/local-setup.md) |
| [Implementation](./implementation/) | Technical specs, ADRs, modules | [Architecture](./implementation/README.md), [Modules](./implementation/modules/) |
| [Milestones](./milestones/) | Roadmap, initiatives, phases | [MASTERPLAN](./milestones/MASTERPLAN.md), [All Initiatives](./milestones/) |
| [Reference](./reference/) | Stack docs, API specs | [Stack Reference](./reference/README.md) |

## Project Status

```
Phase: PRE-MVP
Status: Planning & Setup
Target: MVP Launch (Hardware Vertical - France)
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
        |      |               |
        +------+-------+-------+
                       |
              [PostgreSQL + Redis]
```

## Module Map

| Module | Language | Responsibility |
|--------|----------|----------------|
| `internal/catalog/` | Go | Products, prices, categories |
| `internal/scraper/` | Go | Job orchestration, proxies |
| `internal/compare/` | Go | Pareto API (delegates to Python) |
| `internal/affiliate/` | Go | Link generation, click tracking |
| `workers/src/normalizer/` | Python | HTML parsing, data extraction |
| `workers/src/pareto/` | Python | Pareto calculation, z-scores |
| `frontend/` | Next.js | SSR pages, comparison UI |

## Key Principles

1. **YAGNI First** - Build only what's needed for MVP validation
2. **Modular Monolith** - Clean boundaries, single deployment
3. **Pareto Value** - Multi-objective optimization as differentiator
4. **France First** - French retailers, French compliance, then expand

## Getting Started

```bash
# 1. Read the business context
cat reference/specs/blueprint.md

# 2. Understand the architecture
cat reference/specs/architecture.md

# 3. Start with development setup
cat development/local-setup.md

# 4. Follow the MVP roadmap
cat milestones/MASTERPLAN.md
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

---

**Last Updated**: 2025-12-01
**Maintained By**: @clumineau
