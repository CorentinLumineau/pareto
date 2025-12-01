# Domain - Business Logic Documentation

> **Core business rules, entities, and algorithms for the Pareto Comparator**

## Domain Overview

The Pareto Comparator solves a multi-dimensional optimization problem: helping users find products that best match their personal trade-offs across multiple criteria, not just price.

## Core Concepts

### 1. Pareto Efficiency

A product is **Pareto-optimal** if no other product is better in ALL criteria simultaneously. The set of all Pareto-optimal products forms the **Pareto Frontier**.

```
Traditional comparator: Sort by price
Pareto comparator: Show all "best compromises"
```

**Example**: For laptops comparing Price vs Performance:
- MacBook Pro (1800EUR, 95pts) - Pareto optimal
- ThinkPad X1 (1500EUR, 88pts) - Pareto optimal
- Dell XPS (1200EUR, 82pts) - Pareto optimal
- HP Pavilion (800EUR, 70pts) - Pareto optimal
- Random laptop (1400EUR, 75pts) - DOMINATED (ThinkPad is better on both)

### 2. Multi-Objective Comparison

Users can weight multiple objectives:
- **Minimization**: Price, Weight, Power consumption
- **Maximization**: Performance, Battery life, Screen quality

The system calculates weighted utility scores using **z-score normalization** for fair comparison across different units.

### 3. Affiliate Revenue Model

Revenue comes from affiliate commissions when users click through to retailers:
- **Amazon**: 1-5% CPA
- **Awin Network** (Fnac, Darty, Cdiscount): Variable CPA
- **Direct Programs**: UTM-tracked conversions

## Domain Entities

### Product
```
Product {
  id: UUID
  slug: string (URL-friendly)
  name: string
  gtin: string? (EAN-13/UPC for matching)
  brand: Brand
  category: Category
  attributes: JSONB (category-specific specs)
  image_url: string
}
```

### Price (Time-series)
```
Price {
  product_id: UUID
  retailer_id: UUID
  price: Decimal
  shipping: Decimal?
  in_stock: boolean
  url: string
  scraped_at: Timestamp
}
```

### Retailer
```
Retailer {
  id: UUID
  name: string (Amazon.fr, Fnac.com, etc.)
  scraper_config: JSONB
  affiliate_config: JSONB (network, tracking IDs)
}
```

### Category
```
Category {
  id: UUID
  name: string
  slug: string
  parent_id: UUID? (hierarchical)
  attribute_schema: JSONB (defines comparable attributes)
}
```

### Comparison Session
```
ComparisonSession {
  products: Product[]
  objectives: Objective[] (name, sense, weight)
  pareto_frontier: Product[] (computed)
  utility_scores: Map<ProductID, Score>
}
```

## Business Rules

### BR-001: Price Freshness
- Prices older than **24 hours** must be flagged as "possibly outdated"
- Display "Last updated: X hours ago" on all prices

### BR-002: Stock Availability
- Out-of-stock products shown but clearly marked
- Default sorting excludes out-of-stock unless explicitly included

### BR-003: Pareto Calculation
- Minimum 2 objectives required
- All objectives normalized via z-score before aggregation
- Products with missing attributes excluded from comparison

### BR-004: Affiliate Link Disclosure
- All affiliate links must be marked "Sponsorise" per Decree 2017-1434
- Transparency page must explain ranking methodology

### BR-005: Entity Resolution Priority
1. GTIN exact match (100% confidence)
2. Retailer SKU lookup (100% confidence)
3. Fuzzy title match >95% (auto-link)
4. Fuzzy match 85-95% (queue for review)
5. <85% = create new product

## Workflows

### User Comparison Flow
```
1. User selects category (laptops)
2. System loads products with latest prices
3. User adjusts objective weights (price: 2x, performance: 1x, battery: 1x)
4. System calculates Pareto frontier
5. Display: Frontier products highlighted, others grayed
6. User clicks "Voir l'offre" -> Affiliate redirect -> Commission tracked
```

### Scraping Pipeline Flow
```
1. Scheduler triggers scrape job (every 4 hours)
2. Go Orchestrator queues URLs per retailer
3. Python Worker fetches with anti-bot bypass
4. Raw HTML stored in Redis (24h TTL)
5. Normalizer extracts structured data
6. Entity Resolution matches to canonical product
7. Price entry added to TimescaleDB
8. Cache invalidated for affected products
```

## Files in this Section

- [Pareto Optimization](./pareto-optimization.md) - Algorithm details
- [Entity Resolution](./entity-resolution.md) - Product matching logic
- [Affiliate System](./affiliate-system.md) - Revenue tracking
- [Compliance Rules](./compliance.md) - Legal requirements (FR)
- [Glossary](./glossary.md) - Domain terminology

---

**See Also**: [Implementation](../implementation/) for technical details
