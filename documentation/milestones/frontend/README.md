# Frontend Web Initiative

> **Next.js 15 web application with App Router**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                         FRONTEND WEB INITIATIVE                               ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     ⏳ PENDING                                                       ║
║  Effort:     4 weeks (20 days)                                               ║
║  Depends:    Catalog, Comparison, Affiliate                                  ║
║  Unlocks:    Launch                                                          ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Objective

Build a performant, SEO-optimized web application for comparing smartphones with Pareto optimization visualization.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      FRONTEND WEB                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Next.js 15 (App Router)                                       │
│   ├── SSR for SEO                                               │
│   ├── RSC for performance                                       │
│   └── Client components for interactivity                       │
│                                                                 │
│   Data Fetching:                                                │
│   └── @pareto/api-client (shared with mobile)                  │
│       └── TanStack Query for caching                           │
│                                                                 │
│   Styling:                                                      │
│   └── Tailwind CSS + shadcn/ui                                 │
│                                                                 │
│   Charts:                                                       │
│   └── Recharts (Pareto visualization)                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Next.js 15 | SSR, App Router |
| Language | TypeScript | Type safety |
| Data | TanStack Query | Server state |
| Styling | Tailwind CSS | Utility-first CSS |
| Components | shadcn/ui | Accessible components |
| Charts | Recharts | Data visualization |
| Forms | React Hook Form + Zod | Form handling |

## Phases

| # | Phase | Effort | Description |
|---|-------|--------|-------------|
| 01 | [Project Setup](./01-setup.md) | 2d | Next.js, Tailwind, shadcn |
| 02 | [Core Pages](./02-core-pages.md) | 5d | Home, search, product detail |
| 03 | [Comparison UI](./03-comparison.md) | 5d | Pareto visualization |
| 04 | [SEO & Performance](./04-seo.md) | 4d | Meta tags, sitemap, Core Web Vitals |
| 05 | [Polish & Launch](./05-polish.md) | 4d | Responsive, i18n, analytics |

## Page Structure

```
apps/web/
├── app/
│   ├── layout.tsx              # Root layout
│   ├── page.tsx                # Home page
│   ├── (marketing)/
│   │   ├── about/page.tsx
│   │   └── contact/page.tsx
│   ├── products/
│   │   ├── page.tsx            # Product list
│   │   └── [id]/
│   │       └── page.tsx        # Product detail
│   ├── compare/
│   │   └── page.tsx            # Comparison page
│   ├── search/
│   │   └── page.tsx            # Search results
│   └── api/
│       └── [...]/route.ts      # API routes (if needed)
├── components/
│   ├── ui/                     # shadcn/ui components
│   ├── products/               # Product-specific
│   ├── comparison/             # Comparison-specific
│   └── layout/                 # Layout components
├── lib/
│   ├── api.ts                  # API client instance
│   └── utils.ts                # Utilities
└── styles/
    └── globals.css             # Global styles
```

## Key Features

### Home Page
- Hero with search
- Featured comparisons
- Trending products
- Category navigation

### Product List
- Filterable grid
- Sort by price, score, name
- Infinite scroll
- Quick compare button

### Product Detail
- Image gallery
- Price comparison table
- Price history chart
- Retailer links with affiliate tracking
- Related products

### Comparison Page
- Pareto frontier visualization
- Side-by-side comparison
- Score explanations
- "Best for" recommendations

## Shared Packages Usage

```typescript
// Using shared packages
import { useProducts, useComparison } from '@pareto/api-client'
import { Product, ComparisonResult } from '@pareto/types'
import { formatPrice, formatDate } from '@pareto/utils'

export function ProductCard({ product }: { product: Product }) {
    return (
        <div className="p-4 border rounded-lg">
            <h3>{product.title}</h3>
            <p className="text-lg font-bold">
                {formatPrice(product.best_price)}
            </p>
        </div>
    )
}
```

## API Integration

```typescript
// lib/api.ts
import { createApiClient } from '@pareto/api-client'

export const api = createApiClient({
    baseURL: process.env.NEXT_PUBLIC_API_URL,
})

// Server components can fetch directly
export async function getProduct(id: string) {
    return api.products.get(id)
}

// Client components use hooks
export function ProductList() {
    const { data, isLoading } = useProducts()
    // ...
}
```

## Success Metrics

| Metric | Target |
|--------|--------|
| Lighthouse Performance | >90 |
| First Contentful Paint | <1.5s |
| Time to Interactive | <3s |
| SEO Score | >90 |
| Accessibility Score | >90 |

## Deliverables

- [ ] Next.js 15 project setup
- [ ] Core pages (home, list, detail)
- [ ] Comparison page with Pareto chart
- [ ] SEO optimization
- [ ] Mobile responsive
- [ ] Analytics integration

---

**Depends on**: [Catalog](../catalog/), [Comparison](../comparison/), [Affiliate](../affiliate/)
**Parallel with**: [Mobile](../mobile/)
**Unlocks**: [Launch](../launch/)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
