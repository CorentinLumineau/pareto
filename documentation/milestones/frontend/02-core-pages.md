# Phase 02: Core Pages

> **Home, product list, product detail, search**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      02 - Core Pages                                   ║
║  Initiative: Frontend Web                                      ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     5 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Build the core pages: home, product list, product detail, and search.

## Tasks

- [ ] Home page with hero and search
- [ ] Product list with filters
- [ ] Product detail page
- [ ] Search page
- [ ] Layout components

## Home Page

```typescript
// apps/web/src/app/page.tsx
import { Suspense } from 'react'
import { HeroSection } from '@/components/home/hero-section'
import { FeaturedProducts } from '@/components/home/featured-products'
import { CategoryGrid } from '@/components/home/category-grid'
import { HowItWorks } from '@/components/home/how-it-works'
import { Skeleton } from '@/components/ui/skeleton'

export default function HomePage() {
    return (
        <>
            <HeroSection />

            <section className="container py-12">
                <h2 className="text-2xl font-bold mb-6">
                    Produits populaires
                </h2>
                <Suspense fallback={<ProductGridSkeleton />}>
                    <FeaturedProducts />
                </Suspense>
            </section>

            <section className="bg-muted py-12">
                <div className="container">
                    <CategoryGrid />
                </div>
            </section>

            <section className="container py-12">
                <HowItWorks />
            </section>
        </>
    )
}

function ProductGridSkeleton() {
    return (
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-6">
            {Array.from({ length: 8 }).map((_, i) => (
                <Skeleton key={i} className="h-64 rounded-lg" />
            ))}
        </div>
    )
}
```

## Hero Section

```typescript
// apps/web/src/components/home/hero-section.tsx
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Search } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'

export function HeroSection() {
    const [query, setQuery] = useState('')
    const router = useRouter()

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault()
        if (query.trim()) {
            router.push(`/search?q=${encodeURIComponent(query)}`)
        }
    }

    return (
        <section className="bg-gradient-to-b from-primary/10 to-background py-20">
            <div className="container text-center">
                <h1 className="text-4xl md:text-5xl font-bold mb-4">
                    Trouvez le smartphone parfait
                </h1>
                <p className="text-lg text-muted-foreground mb-8 max-w-2xl mx-auto">
                    Comparez les prix et les caractéristiques grâce à
                    l'optimisation Pareto pour trouver le meilleur rapport qualité-prix.
                </p>

                <form onSubmit={handleSearch} className="max-w-xl mx-auto">
                    <div className="flex gap-2">
                        <div className="relative flex-1">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Rechercher un smartphone..."
                                value={query}
                                onChange={(e) => setQuery(e.target.value)}
                                className="pl-10"
                            />
                        </div>
                        <Button type="submit">Rechercher</Button>
                    </div>
                </form>
            </div>
        </section>
    )
}
```

## Product List Page

```typescript
// apps/web/src/app/products/page.tsx
import { Suspense } from 'react'
import { ProductFilters } from '@/components/products/product-filters'
import { ProductGrid } from '@/components/products/product-grid'
import { fetchProducts } from '@/lib/api'

interface ProductsPageProps {
    searchParams: { [key: string]: string | string[] | undefined }
}

export default async function ProductsPage({ searchParams }: ProductsPageProps) {
    const page = Number(searchParams.page) || 1
    const brand = searchParams.brand as string | undefined
    const sort = searchParams.sort as string | undefined

    const { products, total, totalPages } = await fetchProducts({
        page,
        brand,
        sort,
    })

    return (
        <div className="container py-8">
            <h1 className="text-3xl font-bold mb-8">Tous les smartphones</h1>

            <div className="flex flex-col lg:flex-row gap-8">
                <aside className="w-full lg:w-64 flex-shrink-0">
                    <ProductFilters />
                </aside>

                <main className="flex-1">
                    <div className="flex justify-between items-center mb-6">
                        <p className="text-muted-foreground">
                            {total} produits trouvés
                        </p>
                        <SortSelect defaultValue={sort} />
                    </div>

                    <Suspense fallback={<ProductGridSkeleton />}>
                        <ProductGrid products={products} />
                    </Suspense>

                    <Pagination
                        currentPage={page}
                        totalPages={totalPages}
                    />
                </main>
            </div>
        </div>
    )
}
```

## Product Card Component

```typescript
// apps/web/src/components/products/product-card.tsx
import Link from 'next/link'
import Image from 'next/image'
import { Product } from '@pareto/types'
import { formatPrice } from '@pareto/utils'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Star, Plus } from 'lucide-react'

interface ProductCardProps {
    product: Product
    onCompare?: (id: string) => void
}

export function ProductCard({ product, onCompare }: ProductCardProps) {
    const bestOffer = product.offers?.reduce((best, offer) =>
        (!best || (offer.price && offer.price < best.price!)) ? offer : best
    , product.offers[0])

    return (
        <Card className="group hover:shadow-lg transition-shadow">
            <Link href={`/products/${product.id}`}>
                <div className="relative aspect-square overflow-hidden rounded-t-lg bg-muted">
                    {product.imageUrl && (
                        <Image
                            src={product.imageUrl}
                            alt={product.title}
                            fill
                            className="object-contain p-4 group-hover:scale-105 transition-transform"
                        />
                    )}
                    {product.score && product.score > 80 && (
                        <Badge className="absolute top-2 left-2" variant="secondary">
                            <Star className="h-3 w-3 mr-1" />
                            Top choix
                        </Badge>
                    )}
                </div>
            </Link>

            <CardContent className="p-4">
                <Link href={`/products/${product.id}`}>
                    <p className="text-sm text-muted-foreground mb-1">
                        {product.brand}
                    </p>
                    <h3 className="font-semibold line-clamp-2 mb-2 group-hover:text-primary">
                        {product.title}
                    </h3>
                </Link>

                <div className="flex items-center justify-between">
                    <div>
                        {bestOffer?.price && (
                            <p className="text-lg font-bold">
                                {formatPrice(bestOffer.price)}
                            </p>
                        )}
                        <p className="text-xs text-muted-foreground">
                            {product.offers?.length || 0} offres
                        </p>
                    </div>

                    {onCompare && (
                        <Button
                            variant="outline"
                            size="icon"
                            onClick={(e) => {
                                e.preventDefault()
                                onCompare(product.id)
                            }}
                        >
                            <Plus className="h-4 w-4" />
                        </Button>
                    )}
                </div>
            </CardContent>
        </Card>
    )
}
```

## Product Detail Page

```typescript
// apps/web/src/app/products/[id]/page.tsx
import { notFound } from 'next/navigation'
import { Metadata } from 'next'
import { fetchProduct } from '@/lib/api'
import { ProductGallery } from '@/components/products/product-gallery'
import { ProductInfo } from '@/components/products/product-info'
import { OffersTable } from '@/components/products/offers-table'
import { PriceHistoryChart } from '@/components/products/price-history-chart'
import { RelatedProducts } from '@/components/products/related-products'

interface ProductPageProps {
    params: { id: string }
}

export async function generateMetadata({ params }: ProductPageProps): Promise<Metadata> {
    const product = await fetchProduct(params.id)
    if (!product) return { title: 'Produit non trouvé' }

    return {
        title: product.title,
        description: `Comparez les prix de ${product.title} sur ${product.offers?.length || 0} sites`,
    }
}

export default async function ProductPage({ params }: ProductPageProps) {
    const product = await fetchProduct(params.id)

    if (!product) {
        notFound()
    }

    return (
        <div className="container py-8">
            {/* Breadcrumb */}
            <nav className="text-sm text-muted-foreground mb-6">
                <a href="/" className="hover:text-foreground">Accueil</a>
                {' / '}
                <a href="/products" className="hover:text-foreground">Smartphones</a>
                {' / '}
                <span>{product.brand}</span>
            </nav>

            {/* Main content */}
            <div className="grid lg:grid-cols-2 gap-8 mb-12">
                <ProductGallery images={product.images} />
                <ProductInfo product={product} />
            </div>

            {/* Offers comparison */}
            <section className="mb-12">
                <h2 className="text-2xl font-bold mb-4">
                    Comparer les offres
                </h2>
                <OffersTable offers={product.offers || []} />
            </section>

            {/* Price history */}
            <section className="mb-12">
                <h2 className="text-2xl font-bold mb-4">
                    Historique des prix
                </h2>
                <PriceHistoryChart productId={product.id} />
            </section>

            {/* Related products */}
            <section>
                <h2 className="text-2xl font-bold mb-4">
                    Produits similaires
                </h2>
                <RelatedProducts productId={product.id} />
            </section>
        </div>
    )
}
```

## Offers Table

```typescript
// apps/web/src/components/products/offers-table.tsx
'use client'

import { Offer } from '@pareto/types'
import { formatPrice } from '@pareto/utils'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ExternalLink, Check, X } from 'lucide-react'

interface OffersTableProps {
    offers: Offer[]
}

const retailerLogos: Record<string, string> = {
    amazon_fr: '/retailers/amazon.svg',
    fnac: '/retailers/fnac.svg',
    cdiscount: '/retailers/cdiscount.svg',
    darty: '/retailers/darty.svg',
    boulanger: '/retailers/boulanger.svg',
    ldlc: '/retailers/ldlc.svg',
}

export function OffersTable({ offers }: OffersTableProps) {
    // Sort by price
    const sortedOffers = [...offers].sort((a, b) => (a.price || 0) - (b.price || 0))
    const bestPrice = sortedOffers[0]?.price

    return (
        <Table>
            <TableHeader>
                <TableRow>
                    <TableHead>Vendeur</TableHead>
                    <TableHead>Prix</TableHead>
                    <TableHead>Stock</TableHead>
                    <TableHead className="text-right">Action</TableHead>
                </TableRow>
            </TableHeader>
            <TableBody>
                {sortedOffers.map((offer) => (
                    <TableRow key={offer.id}>
                        <TableCell>
                            <div className="flex items-center gap-2">
                                <img
                                    src={retailerLogos[offer.retailerId] || '/retailers/default.svg'}
                                    alt={offer.retailerName}
                                    className="h-6 w-6 object-contain"
                                />
                                <span>{offer.retailerName}</span>
                            </div>
                        </TableCell>
                        <TableCell>
                            <div className="flex items-center gap-2">
                                <span className="font-bold">
                                    {formatPrice(offer.price || 0)}
                                </span>
                                {offer.price === bestPrice && (
                                    <Badge variant="secondary">Meilleur prix</Badge>
                                )}
                            </div>
                        </TableCell>
                        <TableCell>
                            {offer.inStock ? (
                                <span className="flex items-center gap-1 text-green-600">
                                    <Check className="h-4 w-4" /> En stock
                                </span>
                            ) : (
                                <span className="flex items-center gap-1 text-red-600">
                                    <X className="h-4 w-4" /> Rupture
                                </span>
                            )}
                        </TableCell>
                        <TableCell className="text-right">
                            <Button asChild>
                                <a
                                    href={`/go/${offer.id}`}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                >
                                    Voir l'offre
                                    <ExternalLink className="ml-2 h-4 w-4" />
                                </a>
                            </Button>
                        </TableCell>
                    </TableRow>
                ))}
            </TableBody>
        </Table>
    )
}
```

## Search Page

```typescript
// apps/web/src/app/search/page.tsx
import { Suspense } from 'react'
import { SearchResults } from '@/components/search/search-results'
import { searchProducts } from '@/lib/api'

interface SearchPageProps {
    searchParams: { q?: string }
}

export default async function SearchPage({ searchParams }: SearchPageProps) {
    const query = searchParams.q || ''

    if (!query) {
        return (
            <div className="container py-12 text-center">
                <p className="text-muted-foreground">
                    Entrez un terme de recherche
                </p>
            </div>
        )
    }

    const results = await searchProducts(query)

    return (
        <div className="container py-8">
            <h1 className="text-2xl font-bold mb-2">
                Résultats pour "{query}"
            </h1>
            <p className="text-muted-foreground mb-8">
                {results.length} produit{results.length !== 1 ? 's' : ''} trouvé{results.length !== 1 ? 's' : ''}
            </p>

            <Suspense fallback={<div>Chargement...</div>}>
                <SearchResults results={results} />
            </Suspense>
        </div>
    )
}
```

## Deliverables

- [ ] Home page with hero and search
- [ ] Product list with filtering
- [ ] Product detail page
- [ ] Offers comparison table
- [ ] Search page
- [ ] Responsive design

---

**Previous Phase**: [01-setup.md](./01-setup.md)
**Next Phase**: [03-comparison.md](./03-comparison.md)
**Back to**: [Frontend README](./README.md)
