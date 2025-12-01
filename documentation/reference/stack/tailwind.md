# Tailwind CSS v4 - Styling

> **CSS-first configuration with Lightning CSS**

## Version Info

| Attribute | Value |
|-----------|-------|
| **Version** | 4.1.17 |
| **Release** | January 2025 |
| **Context7** | `/websites/tailwindcss` |

## Tailwind v4 Key Changes

### CSS-Based Configuration

```css
/* app/globals.css */
@import "tailwindcss";

/* Theme configuration in CSS */
@theme {
  /* Colors - Pareto brand */
  --color-pareto-50: oklch(0.97 0.01 145);
  --color-pareto-100: oklch(0.93 0.02 145);
  --color-pareto-500: oklch(0.65 0.15 145);
  --color-pareto-600: oklch(0.55 0.15 145);
  --color-pareto-700: oklch(0.45 0.12 145);

  /* Semantic colors */
  --color-primary: var(--color-pareto-600);
  --color-primary-hover: var(--color-pareto-700);

  /* French retailer colors */
  --color-amazon: #ff9900;
  --color-fnac: #e5a100;
  --color-darty: #c30a1c;
  --color-boulanger: #0066cc;
  --color-cdiscount: #00a0e3;

  /* Fonts */
  --font-sans: "Inter Variable", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;

  /* Spacing scale */
  --spacing-18: 4.5rem;
  --spacing-22: 5.5rem;

  /* Border radius */
  --radius-card: 0.75rem;
  --radius-button: 0.5rem;

  /* Shadows */
  --shadow-card: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
  --shadow-card-hover: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);

  /* Animation */
  --animate-fade-in: fade-in 0.3s ease-out;
  --animate-slide-up: slide-up 0.3s ease-out;
}

@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slide-up {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
```

### Dark Mode

```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  /* Light mode colors (default) */
  --color-background: white;
  --color-foreground: oklch(0.15 0 0);
  --color-muted: oklch(0.95 0 0);
  --color-border: oklch(0.9 0 0);
}

/* Dark mode overrides */
@media (prefers-color-scheme: dark) {
  @theme {
    --color-background: oklch(0.15 0 0);
    --color-foreground: oklch(0.95 0 0);
    --color-muted: oklch(0.25 0 0);
    --color-border: oklch(0.3 0 0);
  }
}

/* Class-based dark mode */
.dark {
  @theme {
    --color-background: oklch(0.15 0 0);
    --color-foreground: oklch(0.95 0 0);
    --color-muted: oklch(0.25 0 0);
    --color-border: oklch(0.3 0 0);
  }
}
```

### Custom Utilities

```css
/* app/globals.css */

/* Custom utility for Pareto optimal badge */
@utility pareto-badge {
  @apply inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium;
  @apply bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200;
}

/* Custom utility for retailer badge */
@utility retailer-badge {
  @apply inline-flex items-center px-2 py-1 rounded text-xs font-semibold;
}

/* Container queries utility */
@utility container-card {
  container-type: inline-size;
}
```

### Variants

```css
/* app/globals.css */

/* Custom variant for Pareto optimal items */
@variant pareto-optimal (&:where([data-pareto-optimal="true"]));

/* Usage: pareto-optimal:border-green-500 */
```

## Component Styling

### Product Card

```tsx
// components/product/product-card.tsx
export function ProductCard({
  product,
  isPareto = false,
}: {
  product: Product
  isPareto?: boolean
}) {
  return (
    <article
      className={`
        group relative rounded-card bg-white p-4
        shadow-card hover:shadow-card-hover
        transition-shadow duration-200
        ${isPareto ? 'ring-2 ring-pareto-500' : ''}
      `}
      data-pareto-optimal={isPareto}
    >
      {/* Pareto badge */}
      {isPareto && (
        <span className="pareto-badge absolute -top-2 -right-2 z-10">
          Pareto Optimal
        </span>
      )}

      {/* Image */}
      <div className="relative aspect-square mb-4 overflow-hidden rounded-lg bg-gray-100">
        <img
          src={product.imageUrl}
          alt={product.name}
          className="object-contain p-4 transition-transform group-hover:scale-105"
        />
      </div>

      {/* Content */}
      <div className="space-y-2">
        <p className="text-sm text-gray-500">{product.brand}</p>
        <h3 className="font-semibold line-clamp-2">{product.name}</h3>

        <div className="flex items-baseline gap-2">
          <span className="text-xl font-bold text-pareto-600">
            {formatPrice(product.minPrice)}
          </span>
          {product.maxPrice > product.minPrice && (
            <span className="text-sm text-gray-400 line-through">
              {formatPrice(product.maxPrice)}
            </span>
          )}
        </div>

        <p className="text-xs text-gray-500">
          {product.offers.length} offres
        </p>
      </div>
    </article>
  )
}
```

### Comparison Table

```tsx
// components/comparison/comparison-table.tsx
export function ComparisonTable({ results }: { results: ParetoResult[] }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse">
        <thead>
          <tr className="border-b border-border bg-muted/50">
            <th className="px-4 py-3 text-left font-semibold">Produit</th>
            <th className="px-4 py-3 text-left font-semibold">Prix</th>
            <th className="px-4 py-3 text-left font-semibold">Score</th>
            <th className="px-4 py-3 text-left font-semibold">Retailer</th>
            <th className="px-4 py-3 text-center font-semibold">Pareto</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {results.map((result) => (
            <tr
              key={result.id}
              className={`
                hover:bg-muted/30 transition-colors
                ${result.isParetoOptimal ? 'bg-green-50 dark:bg-green-950/30' : ''}
              `}
            >
              <td className="px-4 py-3">
                <div className="flex items-center gap-3">
                  <img
                    src={result.imageUrl}
                    alt=""
                    className="h-12 w-12 rounded object-contain bg-white"
                  />
                  <span className="font-medium">{result.name}</span>
                </div>
              </td>
              <td className="px-4 py-3 font-semibold text-pareto-600">
                {formatPrice(result.price)}
              </td>
              <td className="px-4 py-3">
                <ScoreBadge score={result.score} />
              </td>
              <td className="px-4 py-3">
                <RetailerBadge retailer={result.retailer} />
              </td>
              <td className="px-4 py-3 text-center">
                {result.isParetoOptimal ? (
                  <span className="text-green-500">
                    <CheckCircleIcon className="h-5 w-5 mx-auto" />
                  </span>
                ) : (
                  <span className="text-gray-300">
                    <MinusCircleIcon className="h-5 w-5 mx-auto" />
                  </span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
```

### Retailer Badge

```tsx
// components/ui/retailer-badge.tsx
const RETAILER_STYLES: Record<string, string> = {
  amazon: 'bg-[#ff9900] text-white',
  fnac: 'bg-[#e5a100] text-white',
  darty: 'bg-[#c30a1c] text-white',
  boulanger: 'bg-[#0066cc] text-white',
  cdiscount: 'bg-[#00a0e3] text-white',
  default: 'bg-gray-500 text-white',
}

export function RetailerBadge({ retailer }: { retailer: string }) {
  const style = RETAILER_STYLES[retailer.toLowerCase()] || RETAILER_STYLES.default

  return (
    <span className={`retailer-badge ${style}`}>
      {retailer}
    </span>
  )
}
```

## Responsive Design

### Container Queries

```tsx
// components/product/product-grid.tsx
export function ProductGrid({ products }: { products: Product[] }) {
  return (
    <div className="container-card">
      <div
        className="
          grid gap-4
          grid-cols-1
          @sm:grid-cols-2
          @md:grid-cols-3
          @lg:grid-cols-4
        "
      >
        {products.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </div>
  )
}
```

### Responsive Patterns

```tsx
// components/layout/header.tsx
export function Header() {
  return (
    <header className="sticky top-0 z-50 bg-background/80 backdrop-blur-sm border-b border-border">
      <div className="container mx-auto px-4">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2">
            <Logo className="h-8 w-8" />
            <span className="font-bold text-xl hidden sm:inline">
              Pareto
            </span>
          </Link>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-6">
            <NavLink href="/categories">Catégories</NavLink>
            <NavLink href="/compare">Comparer</NavLink>
            <NavLink href="/deals">Bons plans</NavLink>
          </nav>

          {/* Search - hidden on mobile, shown on tablet+ */}
          <div className="hidden sm:block flex-1 max-w-md mx-4">
            <SearchInput />
          </div>

          {/* Mobile menu button */}
          <button className="md:hidden p-2 hover:bg-muted rounded-lg">
            <MenuIcon className="h-6 w-6" />
          </button>
        </div>
      </div>
    </header>
  )
}
```

## Animation

### Page Transitions

```tsx
// components/ui/page-transition.tsx
'use client'

import { motion } from 'framer-motion'

export function PageTransition({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.3 }}
    >
      {children}
    </motion.div>
  )
}
```

### CSS Animations

```css
/* app/globals.css */
@theme {
  --animate-spin-slow: spin 3s linear infinite;
  --animate-pulse-slow: pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite;
  --animate-bounce-subtle: bounce-subtle 2s infinite;
}

@keyframes bounce-subtle {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-5px); }
}
```

```tsx
// Loading spinner
<div className="animate-spin-slow">
  <LoaderIcon />
</div>

// Subtle bounce for CTA
<Button className="animate-bounce-subtle">
  Comparer maintenant
</Button>
```

### Hover States

```tsx
// components/product/offer-card.tsx
export function OfferCard({ offer }: { offer: Offer }) {
  return (
    <a
      href={offer.affiliateUrl}
      target="_blank"
      rel="noopener noreferrer sponsored"
      className="
        block p-4 rounded-lg border border-border
        hover:border-pareto-500 hover:shadow-md
        transition-all duration-200
        group
      "
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <RetailerBadge retailer={offer.retailer} />
          <span className="text-sm text-gray-500">
            {offer.condition}
          </span>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xl font-bold text-pareto-600">
            {formatPrice(offer.price)}
          </span>
          <ExternalLinkIcon
            className="
              h-4 w-4 text-gray-400
              group-hover:text-pareto-600
              transition-colors
            "
          />
        </div>
      </div>
    </a>
  )
}
```

## Utility Patterns

### clsx/cn Helper

```tsx
// lib/utils.ts
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Usage
<div className={cn(
  'base-classes',
  condition && 'conditional-classes',
  className
)} />
```

### Variants with cva

```tsx
// components/ui/button.tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  // Base styles
  'inline-flex items-center justify-center rounded-button font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-primary text-white hover:bg-primary-hover',
        secondary: 'bg-muted text-foreground hover:bg-muted/80',
        outline: 'border border-border bg-transparent hover:bg-muted',
        ghost: 'hover:bg-muted',
        link: 'text-primary underline-offset-4 hover:underline',
        pareto: 'bg-pareto-600 text-white hover:bg-pareto-700',
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        default: 'h-10 px-4',
        lg: 'h-12 px-6 text-lg',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

export function Button({
  className,
  variant,
  size,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  )
}
```

## Typography

```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  /* Type scale */
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 1.875rem;
  --font-size-4xl: 2.25rem;

  /* Line heights */
  --line-height-tight: 1.25;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.75;
}

/* Prose styles for product descriptions */
.prose-product {
  @apply text-base leading-relaxed text-gray-700 dark:text-gray-300;

  & h2 {
    @apply text-xl font-semibold mt-6 mb-3;
  }

  & h3 {
    @apply text-lg font-medium mt-4 mb-2;
  }

  & p {
    @apply mb-4;
  }

  & ul {
    @apply list-disc list-inside mb-4 space-y-1;
  }
}
```

## shadcn/ui Integration

```bash
# Initialize shadcn/ui
npx shadcn@latest init

# Add components
npx shadcn@latest add button card input table skeleton
```

```tsx
// components/ui/card.tsx (shadcn)
import { cn } from '@/lib/utils'

const Card = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      'rounded-card border border-border bg-background shadow-card',
      className
    )}
    {...props}
  />
))
Card.displayName = 'Card'
```

## PostCSS Configuration

```javascript
// postcss.config.mjs
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
}
```

## VS Code Setup

```json
// .vscode/settings.json
{
  "css.customData": [".vscode/tailwind.json"],
  "tailwindCSS.experimental.classRegex": [
    ["cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]"],
    ["cn\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]"]
  ]
}
```

---

**See Also**:
- [Next.js 16](./nextjs.md)
- [React 19](./react.md)
- [shadcn/ui](https://ui.shadcn.com/)
