# Phase 04: SEO & Performance

> **Meta tags, sitemap, Core Web Vitals**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      04 - SEO & Performance                            ║
║  Initiative: Frontend Web                                      ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     4 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Optimize for search engines and Core Web Vitals to achieve high Lighthouse scores.

## Tasks

- [ ] Dynamic meta tags
- [ ] Sitemap generation
- [ ] Structured data (JSON-LD)
- [ ] Image optimization
- [ ] Performance monitoring

## Meta Tags

```typescript
// apps/web/src/app/products/[id]/page.tsx
import { Metadata } from 'next'
import { fetchProduct } from '@/lib/api'
import { formatPrice } from '@pareto/utils'

interface Props {
    params: { id: string }
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
    const product = await fetchProduct(params.id)

    if (!product) {
        return {
            title: 'Produit non trouvé',
        }
    }

    const bestPrice = product.offers?.reduce(
        (min, o) => (o.price && o.price < min ? o.price : min),
        Infinity
    )

    const description = `Comparez les prix de ${product.title} à partir de ${formatPrice(bestPrice || 0)} sur ${product.offers?.length || 0} sites. Trouvez le meilleur rapport qualité-prix.`

    return {
        title: product.title,
        description,
        openGraph: {
            title: `${product.title} - Comparateur de prix`,
            description,
            type: 'product',
            images: product.imageUrl ? [
                {
                    url: product.imageUrl,
                    width: 800,
                    height: 800,
                    alt: product.title,
                }
            ] : [],
        },
        twitter: {
            card: 'summary_large_image',
            title: product.title,
            description,
            images: product.imageUrl ? [product.imageUrl] : [],
        },
        alternates: {
            canonical: `https://pareto.fr/products/${params.id}`,
        },
    }
}
```

## Structured Data (JSON-LD)

```typescript
// apps/web/src/components/seo/product-schema.tsx
import { Product } from '@pareto/types'

interface ProductSchemaProps {
    product: Product
}

export function ProductSchema({ product }: ProductSchemaProps) {
    const bestOffer = product.offers?.reduce(
        (best, o) => (!best || (o.price && o.price < best.price!) ? o : best),
        product.offers[0]
    )

    const schema = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        name: product.title,
        brand: {
            '@type': 'Brand',
            name: product.brand,
        },
        description: product.description,
        image: product.imageUrl,
        sku: product.ean || product.id,
        gtin13: product.ean,
        offers: {
            '@type': 'AggregateOffer',
            lowPrice: bestOffer?.price,
            highPrice: product.offers?.reduce(
                (max, o) => (o.price && o.price > max ? o.price : max),
                0
            ),
            priceCurrency: 'EUR',
            offerCount: product.offers?.length || 0,
            offers: product.offers?.map(offer => ({
                '@type': 'Offer',
                price: offer.price,
                priceCurrency: 'EUR',
                availability: offer.inStock
                    ? 'https://schema.org/InStock'
                    : 'https://schema.org/OutOfStock',
                url: offer.url,
                seller: {
                    '@type': 'Organization',
                    name: offer.retailerName,
                },
            })),
        },
        aggregateRating: product.score ? {
            '@type': 'AggregateRating',
            ratingValue: product.score / 20, // Convert 0-100 to 0-5
            bestRating: 5,
            worstRating: 0,
        } : undefined,
    }

    return (
        <script
            type="application/ld+json"
            dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
        />
    )
}

// Usage in page
export default async function ProductPage({ params }: Props) {
    const product = await fetchProduct(params.id)

    return (
        <>
            <ProductSchema product={product} />
            {/* Page content */}
        </>
    )
}
```

## Sitemap Generation

```typescript
// apps/web/src/app/sitemap.ts
import { MetadataRoute } from 'next'
import { fetchAllProductIds } from '@/lib/api'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
    const baseUrl = 'https://pareto.fr'

    // Static pages
    const staticPages: MetadataRoute.Sitemap = [
        {
            url: baseUrl,
            lastModified: new Date(),
            changeFrequency: 'daily',
            priority: 1,
        },
        {
            url: `${baseUrl}/products`,
            lastModified: new Date(),
            changeFrequency: 'daily',
            priority: 0.9,
        },
        {
            url: `${baseUrl}/compare`,
            lastModified: new Date(),
            changeFrequency: 'weekly',
            priority: 0.8,
        },
        {
            url: `${baseUrl}/about`,
            lastModified: new Date(),
            changeFrequency: 'monthly',
            priority: 0.5,
        },
    ]

    // Dynamic product pages
    const productIds = await fetchAllProductIds()
    const productPages: MetadataRoute.Sitemap = productIds.map((id) => ({
        url: `${baseUrl}/products/${id}`,
        lastModified: new Date(),
        changeFrequency: 'daily',
        priority: 0.7,
    }))

    return [...staticPages, ...productPages]
}
```

## Robots.txt

```typescript
// apps/web/src/app/robots.ts
import { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
    return {
        rules: {
            userAgent: '*',
            allow: '/',
            disallow: ['/api/', '/go/'],
        },
        sitemap: 'https://pareto.fr/sitemap.xml',
    }
}
```

## Image Optimization

```typescript
// apps/web/src/components/ui/optimized-image.tsx
import Image from 'next/image'

interface OptimizedImageProps {
    src: string
    alt: string
    width?: number
    height?: number
    priority?: boolean
    className?: string
}

export function OptimizedImage({
    src,
    alt,
    width = 400,
    height = 400,
    priority = false,
    className,
}: OptimizedImageProps) {
    // Handle external images
    if (src.startsWith('http')) {
        return (
            <Image
                src={src}
                alt={alt}
                width={width}
                height={height}
                priority={priority}
                className={className}
                loading={priority ? 'eager' : 'lazy'}
                placeholder="blur"
                blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDABQODxIPDRQSEBIXFRQYHjIhHhwcHj0sLiQySUBMS0dARkVQWnNiUFVtVkVGZIhlbXd7gYKBTmCNl4x9lnN+gXz/2wBDARUXFx4aHjshITt8U0ZTfHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHz/wAARCAAIAAoDASIAAhEBAxEB/8QAFgABAQEAAAAAAAAAAAAAAAAAAAUH/8QAIBAAAgEEAQUAAAAAAAAAAAAAAQIDAAQFERIhQVFhcf/EABQBAQAAAAAAAAAAAAAAAAAAAAD/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBEQCEAxEAPwCnxWXyCW8MFvGkjIgVmB0CQOp60PWiguOlKUH/2Q=="
            />
        )
    }

    return (
        <Image
            src={src}
            alt={alt}
            width={width}
            height={height}
            priority={priority}
            className={className}
        />
    )
}
```

## Performance Monitoring

```typescript
// apps/web/src/lib/analytics.ts
import { useReportWebVitals } from 'next/web-vitals'

export function WebVitalsReporter() {
    useReportWebVitals((metric) => {
        // Send to analytics
        console.log(metric)

        // Example: Send to custom endpoint
        if (process.env.NODE_ENV === 'production') {
            fetch('/api/analytics/vitals', {
                method: 'POST',
                body: JSON.stringify(metric),
                headers: { 'Content-Type': 'application/json' },
            })
        }
    })

    return null
}

// apps/web/src/app/layout.tsx
import { WebVitalsReporter } from '@/lib/analytics'

export default function RootLayout({ children }) {
    return (
        <html lang="fr">
            <body>
                <WebVitalsReporter />
                {children}
            </body>
        </html>
    )
}
```

## Performance Checklist

```typescript
// Performance optimizations applied:

// 1. Dynamic imports for heavy components
const ParetoChart = dynamic(
    () => import('@/components/comparison/pareto-chart'),
    { loading: () => <Skeleton className="h-96" /> }
)

// 2. Prefetch critical routes
<Link href="/products" prefetch>Tous les produits</Link>

// 3. Use Server Components by default
// Only add 'use client' when needed

// 4. Optimize fonts
import { Inter } from 'next/font/google'
const inter = Inter({
    subsets: ['latin'],
    display: 'swap',
})

// 5. Image optimization in next.config.ts
images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200],
}
```

## Deliverables

- [ ] Dynamic meta tags per page
- [ ] JSON-LD structured data
- [ ] Sitemap.xml generation
- [ ] Robots.txt
- [ ] Image optimization
- [ ] Lighthouse >90 all categories

---

**Previous Phase**: [03-comparison.md](./03-comparison.md)
**Next Phase**: [05-polish.md](./05-polish.md)
**Back to**: [Frontend README](./README.md)
