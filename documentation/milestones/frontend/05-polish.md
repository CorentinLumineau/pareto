# Phase 05: Polish & Launch

> **Responsive design, analytics, final touches**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      05 - Polish & Launch                              ║
║  Initiative: Frontend Web                                      ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     4 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Final polish: responsive design, analytics integration, error handling, and launch preparation.

## Tasks

- [ ] Mobile responsive testing
- [ ] Analytics integration
- [ ] Error boundaries
- [ ] Loading states
- [ ] 404 and error pages
- [ ] Legal pages (CGU, mentions légales)

## Responsive Testing

```typescript
// Mobile-first responsive breakpoints in Tailwind
// sm: 640px, md: 768px, lg: 1024px, xl: 1280px

// Example responsive component
export function ProductGrid({ products }: { products: Product[] }) {
    return (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 md:gap-6">
            {products.map((product) => (
                <ProductCard key={product.id} product={product} />
            ))}
        </div>
    )
}

// Responsive navigation
export function Header() {
    return (
        <header className="border-b">
            <nav className="container flex items-center justify-between h-16">
                <Logo />

                {/* Desktop navigation */}
                <div className="hidden md:flex items-center gap-6">
                    <NavLinks />
                    <SearchInput />
                </div>

                {/* Mobile menu button */}
                <Sheet>
                    <SheetTrigger asChild className="md:hidden">
                        <Button variant="ghost" size="icon">
                            <Menu className="h-5 w-5" />
                        </Button>
                    </SheetTrigger>
                    <SheetContent side="right">
                        <MobileNav />
                    </SheetContent>
                </Sheet>
            </nav>
        </header>
    )
}
```

## Analytics Integration

```typescript
// apps/web/src/lib/analytics.ts
import { usePathname, useSearchParams } from 'next/navigation'
import { useEffect } from 'react'

// Google Analytics 4
export const GA_TRACKING_ID = process.env.NEXT_PUBLIC_GA_ID

export function pageview(url: string) {
    if (typeof window.gtag !== 'undefined') {
        window.gtag('config', GA_TRACKING_ID, {
            page_path: url,
        })
    }
}

export function event(action: string, params: Record<string, any>) {
    if (typeof window.gtag !== 'undefined') {
        window.gtag('event', action, params)
    }
}

// Track product views
export function trackProductView(product: Product) {
    event('view_item', {
        currency: 'EUR',
        value: product.bestPrice,
        items: [{
            item_id: product.id,
            item_name: product.title,
            item_brand: product.brand,
        }],
    })
}

// Track affiliate clicks
export function trackAffiliateClick(offer: Offer) {
    event('select_item', {
        item_list_name: 'offers',
        items: [{
            item_id: offer.id,
            item_name: offer.retailerName,
            price: offer.price,
        }],
    })
}

// Analytics provider component
export function AnalyticsProvider({ children }: { children: React.ReactNode }) {
    const pathname = usePathname()
    const searchParams = useSearchParams()

    useEffect(() => {
        const url = pathname + searchParams.toString()
        pageview(url)
    }, [pathname, searchParams])

    return <>{children}</>
}

// apps/web/src/app/layout.tsx
import Script from 'next/script'
import { AnalyticsProvider, GA_TRACKING_ID } from '@/lib/analytics'

export default function RootLayout({ children }) {
    return (
        <html lang="fr">
            <head>
                <Script
                    src={`https://www.googletagmanager.com/gtag/js?id=${GA_TRACKING_ID}`}
                    strategy="afterInteractive"
                />
                <Script id="google-analytics" strategy="afterInteractive">
                    {`
                        window.dataLayer = window.dataLayer || [];
                        function gtag(){dataLayer.push(arguments);}
                        gtag('js', new Date());
                        gtag('config', '${GA_TRACKING_ID}');
                    `}
                </Script>
            </head>
            <body>
                <AnalyticsProvider>
                    {children}
                </AnalyticsProvider>
            </body>
        </html>
    )
}
```

## Error Handling

```typescript
// apps/web/src/app/error.tsx
'use client'

import { useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { AlertCircle } from 'lucide-react'

export default function Error({
    error,
    reset,
}: {
    error: Error & { digest?: string }
    reset: () => void
}) {
    useEffect(() => {
        // Log error to analytics
        console.error(error)
    }, [error])

    return (
        <div className="container py-20 text-center">
            <AlertCircle className="h-12 w-12 text-destructive mx-auto mb-4" />
            <h1 className="text-2xl font-bold mb-2">Une erreur est survenue</h1>
            <p className="text-muted-foreground mb-6">
                Nous sommes désolés, quelque chose s'est mal passé.
            </p>
            <Button onClick={reset}>Réessayer</Button>
        </div>
    )
}

// apps/web/src/app/not-found.tsx
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Search } from 'lucide-react'

export default function NotFound() {
    return (
        <div className="container py-20 text-center">
            <h1 className="text-6xl font-bold text-muted-foreground mb-4">404</h1>
            <h2 className="text-2xl font-bold mb-2">Page non trouvée</h2>
            <p className="text-muted-foreground mb-6">
                La page que vous recherchez n'existe pas ou a été déplacée.
            </p>
            <div className="flex gap-4 justify-center">
                <Button asChild>
                    <Link href="/">Retour à l'accueil</Link>
                </Button>
                <Button variant="outline" asChild>
                    <Link href="/products">
                        <Search className="mr-2 h-4 w-4" />
                        Voir les produits
                    </Link>
                </Button>
            </div>
        </div>
    )
}
```

## Loading States

```typescript
// apps/web/src/app/products/loading.tsx
import { Skeleton } from '@/components/ui/skeleton'

export default function ProductsLoading() {
    return (
        <div className="container py-8">
            <Skeleton className="h-10 w-64 mb-8" />

            <div className="flex gap-8">
                {/* Filters skeleton */}
                <aside className="w-64 hidden lg:block">
                    <Skeleton className="h-96" />
                </aside>

                {/* Products grid skeleton */}
                <main className="flex-1">
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {Array.from({ length: 9 }).map((_, i) => (
                            <Skeleton key={i} className="h-64 rounded-lg" />
                        ))}
                    </div>
                </main>
            </div>
        </div>
    )
}
```

## Legal Pages

```typescript
// apps/web/src/app/(legal)/mentions-legales/page.tsx
import { Metadata } from 'next'

export const metadata: Metadata = {
    title: 'Mentions légales',
}

export default function MentionsLegales() {
    return (
        <div className="container py-12 prose prose-slate max-w-3xl mx-auto">
            <h1>Mentions légales</h1>

            <h2>Éditeur du site</h2>
            <p>
                Pareto Comparator<br />
                Entrepreneur individuel<br />
                Email: contact@pareto.fr
            </p>

            <h2>Hébergement</h2>
            <p>
                Ce site est hébergé par [Hébergeur]<br />
                Adresse: [Adresse hébergeur]
            </p>

            <h2>Propriété intellectuelle</h2>
            <p>
                L'ensemble du contenu de ce site (textes, images, logos) est
                protégé par le droit d'auteur.
            </p>

            <h2>Liens affiliés</h2>
            <p>
                Ce site utilise des liens affiliés. Lorsque vous effectuez un
                achat via ces liens, nous pouvons recevoir une commission sans
                surcoût pour vous.
            </p>

            <h2>Données personnelles</h2>
            <p>
                Consultez notre <a href="/politique-confidentialite">politique
                de confidentialité</a> pour en savoir plus sur le traitement de
                vos données.
            </p>
        </div>
    )
}

// apps/web/src/app/(legal)/politique-confidentialite/page.tsx
export default function PolitiqueConfidentialite() {
    return (
        <div className="container py-12 prose prose-slate max-w-3xl mx-auto">
            <h1>Politique de confidentialité</h1>

            <h2>Données collectées</h2>
            <p>
                Nous collectons les données suivantes de manière anonyme:
            </p>
            <ul>
                <li>Pages visitées (Google Analytics)</li>
                <li>Clics sur les liens marchands</li>
                <li>Recherches effectuées</li>
            </ul>

            <h2>Cookies</h2>
            <p>
                Nous utilisons des cookies pour:
            </p>
            <ul>
                <li>Analyser l'audience du site</li>
                <li>Assurer le suivi des commissions affiliées</li>
            </ul>

            <h2>Vos droits</h2>
            <p>
                Conformément au RGPD, vous disposez d'un droit d'accès, de
                rectification et de suppression de vos données.
            </p>
        </div>
    )
}
```

## Footer Component

```typescript
// apps/web/src/components/layout/footer.tsx
import Link from 'next/link'

export function Footer() {
    return (
        <footer className="border-t bg-muted/50">
            <div className="container py-12">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
                    <div>
                        <h3 className="font-semibold mb-3">Pareto</h3>
                        <p className="text-sm text-muted-foreground">
                            Le comparateur intelligent de smartphones.
                        </p>
                    </div>

                    <div>
                        <h3 className="font-semibold mb-3">Produits</h3>
                        <ul className="space-y-2 text-sm">
                            <li><Link href="/products" className="text-muted-foreground hover:text-foreground">Tous les smartphones</Link></li>
                            <li><Link href="/compare" className="text-muted-foreground hover:text-foreground">Comparer</Link></li>
                        </ul>
                    </div>

                    <div>
                        <h3 className="font-semibold mb-3">À propos</h3>
                        <ul className="space-y-2 text-sm">
                            <li><Link href="/about" className="text-muted-foreground hover:text-foreground">Qui sommes-nous</Link></li>
                            <li><Link href="/contact" className="text-muted-foreground hover:text-foreground">Contact</Link></li>
                        </ul>
                    </div>

                    <div>
                        <h3 className="font-semibold mb-3">Légal</h3>
                        <ul className="space-y-2 text-sm">
                            <li><Link href="/mentions-legales" className="text-muted-foreground hover:text-foreground">Mentions légales</Link></li>
                            <li><Link href="/politique-confidentialite" className="text-muted-foreground hover:text-foreground">Confidentialité</Link></li>
                        </ul>
                    </div>
                </div>

                <div className="border-t mt-8 pt-8 text-center text-sm text-muted-foreground">
                    <p>© {new Date().getFullYear()} Pareto. Tous droits réservés.</p>
                    <p className="mt-1">
                        Les prix affichés proviennent des sites marchands et peuvent varier.
                    </p>
                </div>
            </div>
        </footer>
    )
}
```

## Deliverables

- [ ] Mobile responsive on all pages
- [ ] Google Analytics 4 integrated
- [ ] Error boundaries and 404 page
- [ ] Loading states
- [ ] Legal pages (mentions légales, confidentialité)
- [ ] Footer with navigation

---

**Previous Phase**: [04-seo.md](./04-seo.md)
**Back to**: [Frontend README](./README.md)
