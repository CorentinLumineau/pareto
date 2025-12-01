# Next.js 16 - Frontend Framework

> **App Router with Turbopack and Cache Components**

## Version Info

| Attribute | Value |
|-----------|-------|
| **Version** | 16.0.3 |
| **Release** | October 2025 |
| **Node.js** | 24.x LTS |
| **Context7** | `/vercel/next.js/v16.0.3` |

## Project Structure

```
apps/web/
├── app/
│   ├── layout.tsx              # Root layout
│   ├── page.tsx                # Homepage
│   ├── (marketing)/            # Marketing routes group
│   │   ├── page.tsx            # Landing page
│   │   └── about/page.tsx
│   ├── (app)/                   # App routes group
│   │   ├── layout.tsx          # App layout with nav
│   │   ├── categories/
│   │   │   └── [slug]/page.tsx
│   │   ├── products/
│   │   │   └── [slug]/page.tsx
│   │   └── compare/page.tsx
│   └── api/                    # API routes (proxy)
├── components/
│   ├── ui/                     # shadcn/ui components
│   ├── comparison/             # Pareto comparison components
│   └── product/                # Product display components
├── lib/
│   ├── api.ts                  # API client
│   └── utils.ts                # Utilities
├── next.config.ts
├── tailwind.config.ts
└── package.json
```

## Next.js 16 Key Features

### Turbopack (Default)

```typescript
// next.config.ts - Turbopack is now default
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  // Turbopack is enabled by default in Next.js 16
  // No explicit turbo: true needed

  images: {
    remotePatterns: [
      { protocol: 'https', hostname: 'images.amazon.fr' },
      { protocol: 'https', hostname: 'fnac-static.com' },
    ],
  },

  experimental: {
    typedRoutes: true,
    ppr: true, // Partial Prerendering
  },
}

export default nextConfig
```

### Cache Components

```tsx
// app/categories/[slug]/page.tsx
import { cache } from 'react'
import { getCategory, getProducts } from '@/lib/api'

// Cached data fetching - deduped across requests
const getCategoryData = cache(async (slug: string) => {
  const [category, products] = await Promise.all([
    getCategory(slug),
    getProducts({ category: slug, limit: 50 }),
  ])
  return { category, products }
})

export default async function CategoryPage({
  params,
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params
  const { category, products } = await getCategoryData(slug)

  return (
    <main>
      <h1>{category.name}</h1>
      <ProductGrid products={products} />
    </main>
  )
}

// Generate static params for ISR
export async function generateStaticParams() {
  const categories = await getCategories()
  return categories.map((c) => ({ slug: c.slug }))
}

// Revalidate every hour
export const revalidate = 3600
```

### Partial Prerendering (PPR)

```tsx
// app/products/[slug]/page.tsx
import { Suspense } from 'react'
import { ProductHeader } from '@/components/product/product-header'
import { PriceHistory } from '@/components/product/price-history'
import { Offers } from '@/components/product/offers'
import { Skeleton } from '@/components/ui/skeleton'

export default async function ProductPage({
  params,
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params
  const product = await getProduct(slug)

  return (
    <main>
      {/* Static shell - prerendered */}
      <ProductHeader product={product} />

      {/* Dynamic - streamed on request */}
      <Suspense fallback={<Skeleton className="h-64" />}>
        <PriceHistory productId={product.id} />
      </Suspense>

      <Suspense fallback={<Skeleton className="h-96" />}>
        <Offers productId={product.id} />
      </Suspense>
    </main>
  )
}
```

## Server Components

### Data Fetching Pattern

```tsx
// app/compare/page.tsx
import { Suspense } from 'react'
import { ComparisonForm } from '@/components/comparison/form'
import { ComparisonResults } from '@/components/comparison/results'

interface SearchParams {
  ids?: string
}

export default async function ComparePage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>
}) {
  const { ids } = await searchParams

  return (
    <main className="container py-8">
      <h1 className="text-3xl font-bold mb-8">
        Comparateur Pareto
      </h1>

      <ComparisonForm />

      {ids && (
        <Suspense fallback={<ComparisonSkeleton />}>
          <ComparisonResults productIds={ids.split(',')} />
        </Suspense>
      )}
    </main>
  )
}

// Server Component - fetches data directly
async function ComparisonResults({ productIds }: { productIds: string[] }) {
  const results = await compareProducts(productIds)

  return (
    <div className="mt-8">
      <ParetoChart data={results.paretoFrontier} />
      <OfferTable offers={results.offers} />
    </div>
  )
}
```

### Server Actions

```tsx
// app/actions/compare.ts
'use server'

import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'

export async function addToComparison(productId: string) {
  const comparison = await getComparison()

  if (comparison.products.length >= 5) {
    return { error: 'Maximum 5 produits' }
  }

  await saveComparison([...comparison.products, productId])
  revalidatePath('/compare')
}

export async function runComparison(formData: FormData) {
  const productIds = formData.getAll('productId') as string[]
  const objectives = JSON.parse(formData.get('objectives') as string)

  const result = await fetch(`${API_URL}/compare`, {
    method: 'POST',
    body: JSON.stringify({ product_ids: productIds, objectives }),
  })

  if (!result.ok) {
    return { error: 'Erreur de comparaison' }
  }

  const data = await result.json()
  redirect(`/compare/results/${data.id}`)
}
```

## Client Components

### Interactive UI

```tsx
// components/comparison/form.tsx
'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Slider } from '@/components/ui/slider'

interface Objective {
  name: string
  sense: 'min' | 'max'
  weight: number
}

const DEFAULT_OBJECTIVES: Objective[] = [
  { name: 'price', sense: 'min', weight: 2 },
  { name: 'performance', sense: 'max', weight: 1 },
  { name: 'battery', sense: 'max', weight: 1 },
]

export function ComparisonForm() {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [objectives, setObjectives] = useState(DEFAULT_OBJECTIVES)

  const updateWeight = (index: number, weight: number) => {
    setObjectives((prev) =>
      prev.map((obj, i) => (i === index ? { ...obj, weight } : obj))
    )
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const formData = new FormData(e.target as HTMLFormElement)
    const ids = formData.getAll('productId').join(',')

    startTransition(() => {
      router.push(`/compare?ids=${ids}&objectives=${JSON.stringify(objectives)}`)
    })
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <ProductSelector />

      <div className="space-y-4">
        <h3 className="font-semibold">Pondération des critères</h3>
        {objectives.map((obj, i) => (
          <div key={obj.name} className="flex items-center gap-4">
            <span className="w-32">{obj.name}</span>
            <Slider
              value={[obj.weight]}
              onValueChange={([v]) => updateWeight(i, v)}
              min={0}
              max={5}
              step={1}
            />
            <span className="w-8">{obj.weight}</span>
          </div>
        ))}
      </div>

      <Button type="submit" disabled={isPending}>
        {isPending ? 'Analyse...' : 'Comparer'}
      </Button>
    </form>
  )
}
```

### TanStack Query Integration

```tsx
// lib/queries.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from './api'

export function useProducts(category?: string) {
  return useQuery({
    queryKey: ['products', { category }],
    queryFn: () => api.products.list({ category }),
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

export function useProduct(slug: string) {
  return useQuery({
    queryKey: ['product', slug],
    queryFn: () => api.products.getBySlug(slug),
  })
}

export function usePriceHistory(productId: string) {
  return useQuery({
    queryKey: ['priceHistory', productId],
    queryFn: () => api.prices.history(productId),
    staleTime: 30 * 60 * 1000, // 30 minutes
  })
}

export function useCompare() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: api.compare,
    onSuccess: (data) => {
      queryClient.setQueryData(['comparison', data.id], data)
    },
  })
}
```

### Query Provider

```tsx
// app/providers.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000, // 1 minute default
            gcTime: 10 * 60 * 1000, // 10 minutes
          },
        },
      })
  )

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}

// app/layout.tsx
import { Providers } from './providers'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="fr">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
```

## API Routes

```tsx
// app/api/products/route.ts
import { NextRequest, NextResponse } from 'next/server'

const API_URL = process.env.API_URL || 'http://localhost:8080'

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams
  const category = searchParams.get('category')
  const limit = searchParams.get('limit') || '20'

  const response = await fetch(
    `${API_URL}/products?category=${category}&limit=${limit}`,
    { next: { revalidate: 300 } } // Cache for 5 minutes
  )

  const data = await response.json()
  return NextResponse.json(data)
}

// app/api/compare/route.ts
export async function POST(request: NextRequest) {
  const body = await request.json()

  const response = await fetch(`${API_URL}/compare`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })

  const data = await response.json()
  return NextResponse.json(data)
}
```

## Metadata & SEO

```tsx
// app/products/[slug]/page.tsx
import type { Metadata, ResolvingMetadata } from 'next'

type Props = {
  params: Promise<{ slug: string }>
}

export async function generateMetadata(
  { params }: Props,
  parent: ResolvingMetadata
): Promise<Metadata> {
  const { slug } = await params
  const product = await getProduct(slug)

  return {
    title: `${product.name} - Comparateur de prix | Pareto`,
    description: `Comparez les prix du ${product.name}. ${product.offers.length} offres de ${product.minPrice}€ à ${product.maxPrice}€.`,
    openGraph: {
      title: product.name,
      description: `Meilleur prix: ${product.minPrice}€`,
      images: [product.imageUrl],
    },
    alternates: {
      canonical: `https://pareto.fr/products/${slug}`,
    },
  }
}
```

### JSON-LD Structured Data

```tsx
// components/product/product-schema.tsx
import type { Product, Offer } from '@pareto/types'

export function ProductSchema({ product }: { product: Product }) {
  const schema = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    image: product.imageUrl,
    description: product.description,
    brand: {
      '@type': 'Brand',
      name: product.brand,
    },
    offers: {
      '@type': 'AggregateOffer',
      lowPrice: product.minPrice,
      highPrice: product.maxPrice,
      priceCurrency: 'EUR',
      offerCount: product.offers.length,
    },
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  )
}
```

## Image Optimization

```tsx
// components/product/product-image.tsx
import Image from 'next/image'

export function ProductImage({
  src,
  alt,
  priority = false,
}: {
  src: string
  alt: string
  priority?: boolean
}) {
  return (
    <div className="relative aspect-square">
      <Image
        src={src}
        alt={alt}
        fill
        priority={priority}
        sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
        className="object-contain"
      />
    </div>
  )
}
```

## Environment Variables

```bash
# .env.local
NEXT_PUBLIC_APP_URL=http://localhost:3000
API_URL=http://localhost:8080

# .env.production
NEXT_PUBLIC_APP_URL=https://pareto.fr
API_URL=http://api:8080
```

## Docker Configuration

```dockerfile
# apps/web/Dockerfile
FROM node:24-alpine AS base

# Dependencies
FROM base AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile

# Builder
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN corepack enable pnpm && pnpm build

# Runner
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT=3000

CMD ["node", "server.js"]
```

## Commands

```bash
# Development
pnpm dev          # Start with Turbopack (default)
pnpm dev --port 3001

# Build
pnpm build        # Production build
pnpm start        # Start production server

# Analysis
pnpm build && pnpm analyze  # Bundle analysis

# Type checking
pnpm type-check   # tsc --noEmit

# Lint
pnpm lint         # ESLint
pnpm lint:fix     # ESLint with auto-fix
```

---

**See Also**:
- [React 19](./react.md)
- [Tailwind CSS](./tailwind.md)
- [TanStack Query](./tanstack-query.md)
