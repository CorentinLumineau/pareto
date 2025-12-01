# Domain Section - Navigation

> Business logic, rules, and domain entities for Pareto Comparator

## Quick Reference

| File | Purpose |
|------|---------|
| [README.md](./README.md) | Domain overview and concepts |
| [pareto-optimization.md](./pareto-optimization.md) | Pareto algorithm details |
| [quality-enforcement.md](./quality-enforcement.md) | Quality standards and enforcement |

## Key Concepts

- **Pareto Frontier**: Set of products where no single product dominates all others
- **Multi-Objective Optimization**: Balancing trade-offs across criteria (price, performance, battery, etc.)
- **Entity Resolution**: Matching scraped products to canonical catalog entries
- **Affiliate Tracking**: Revenue generation via click-throughs

## Domain Entities

```
Category
  └── Product (canonical)
        ├── Attributes (JSONB)
        └── Offers[]
              ├── Retailer
              ├── Price
              ├── Condition
              └── AffiliateURL

PriceHistory (TimescaleDB)
  └── price per product/retailer over time

ComparisonResult
  ├── ProductIDs[]
  ├── Objectives[]
  ├── ParetoFrontier[]
  └── Scores{}
```

## Comparison Logic

```
1. User selects products (or category)
2. User sets objectives with weights:
   - price (minimize, weight: 2)
   - performance (maximize, weight: 1)
   - battery (maximize, weight: 1)
3. System normalizes values (z-scores)
4. paretoset calculates Pareto frontier
5. UI shows frontier vs dominated products
```

## Related Sections

- [Implementation](../implementation/) - Technical implementation
- [Milestones](../milestones/) - Development roadmap
- [Comparison Spec](../reference/specs/comparaison-catalog.md) - Full specification
