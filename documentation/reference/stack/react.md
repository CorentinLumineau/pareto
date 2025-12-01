# React 19.2 - UI Library

> **Modern React patterns with Server Components and Actions**

## Version Info

| Attribute | Value |
|-----------|-------|
| **Version** | 19.2.0 |
| **Release** | October 2025 |
| **Context7** | `/facebook/react/v19_2_0` |

## React 19 Key Features

### Actions & useActionState

```tsx
// components/comparison/add-to-compare.tsx
'use client'

import { useActionState } from 'react'
import { addToComparison } from '@/app/actions/compare'
import { Button } from '@/components/ui/button'

export function AddToCompare({ productId }: { productId: string }) {
  const [state, formAction, isPending] = useActionState(
    async (prevState: { error?: string } | null, formData: FormData) => {
      return await addToComparison(productId)
    },
    null
  )

  return (
    <form action={formAction}>
      <Button type="submit" disabled={isPending}>
        {isPending ? 'Ajout...' : 'Ajouter à la comparaison'}
      </Button>
      {state?.error && (
        <p className="text-red-500 text-sm mt-2">{state.error}</p>
      )}
    </form>
  )
}
```

### useOptimistic

```tsx
// components/product/wishlist-button.tsx
'use client'

import { useOptimistic, useTransition } from 'react'
import { toggleWishlist } from '@/app/actions/wishlist'
import { Heart } from 'lucide-react'

export function WishlistButton({
  productId,
  isInWishlist,
}: {
  productId: string
  isInWishlist: boolean
}) {
  const [isPending, startTransition] = useTransition()
  const [optimisticWishlist, setOptimisticWishlist] = useOptimistic(isInWishlist)

  const handleClick = () => {
    startTransition(async () => {
      setOptimisticWishlist(!optimisticWishlist)
      await toggleWishlist(productId)
    })
  }

  return (
    <button
      onClick={handleClick}
      disabled={isPending}
      className="p-2 rounded-full hover:bg-gray-100"
    >
      <Heart
        className={optimisticWishlist ? 'fill-red-500 text-red-500' : 'text-gray-400'}
      />
    </button>
  )
}
```

### use() Hook

```tsx
// components/product/offers.tsx
'use client'

import { use, Suspense } from 'react'
import { OfferCard } from './offer-card'

// Using `use` to unwrap promises in render
export function Offers({ offersPromise }: { offersPromise: Promise<Offer[]> }) {
  const offers = use(offersPromise)

  return (
    <div className="grid gap-4">
      {offers.map((offer) => (
        <OfferCard key={offer.id} offer={offer} />
      ))}
    </div>
  )
}

// Parent component passes the promise
export function ProductOffers({ productId }: { productId: string }) {
  const offersPromise = fetchOffers(productId) // Don't await here

  return (
    <Suspense fallback={<OffersSkeleton />}>
      <Offers offersPromise={offersPromise} />
    </Suspense>
  )
}
```

### useFormStatus

```tsx
// components/ui/submit-button.tsx
'use client'

import { useFormStatus } from 'react-dom'
import { Button } from '@/components/ui/button'
import { Loader2 } from 'lucide-react'

export function SubmitButton({
  children,
  loadingText = 'Chargement...',
}: {
  children: React.ReactNode
  loadingText?: string
}) {
  const { pending } = useFormStatus()

  return (
    <Button type="submit" disabled={pending}>
      {pending ? (
        <>
          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
          {loadingText}
        </>
      ) : (
        children
      )}
    </Button>
  )
}
```

## Component Patterns

### Server Components (Default)

```tsx
// components/product/product-details.tsx
// This is a Server Component by default (no 'use client')

import { getProduct } from '@/lib/api'
import { formatPrice, formatDate } from '@pareto/utils'
import { ProductImage } from './product-image'
import { AddToCompare } from './add-to-compare'

export async function ProductDetails({ slug }: { slug: string }) {
  const product = await getProduct(slug)

  return (
    <article className="grid md:grid-cols-2 gap-8">
      <ProductImage src={product.imageUrl} alt={product.name} priority />

      <div className="space-y-4">
        <div>
          <p className="text-sm text-gray-500">{product.brand}</p>
          <h1 className="text-3xl font-bold">{product.name}</h1>
        </div>

        <div className="flex items-baseline gap-2">
          <span className="text-3xl font-bold text-green-600">
            {formatPrice(product.minPrice)}
          </span>
          {product.maxPrice > product.minPrice && (
            <span className="text-gray-500">
              - {formatPrice(product.maxPrice)}
            </span>
          )}
        </div>

        <p className="text-sm text-gray-500">
          {product.offers.length} offres disponibles
        </p>

        {/* Client Component nested in Server Component */}
        <AddToCompare productId={product.id} />
      </div>
    </article>
  )
}
```

### Client Components

```tsx
// components/comparison/pareto-chart.tsx
'use client'

import { useMemo } from 'react'
import {
  ScatterChart,
  Scatter,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine,
} from 'recharts'
import type { ParetoResult } from '@pareto/types'

export function ParetoChart({
  data,
  xAxis = 'price',
  yAxis = 'score',
}: {
  data: ParetoResult[]
  xAxis?: string
  yAxis?: string
}) {
  const { paretoPoints, dominatedPoints } = useMemo(() => {
    const pareto = data.filter((d) => d.isParetoOptimal)
    const dominated = data.filter((d) => !d.isParetoOptimal)
    return { paretoPoints: pareto, dominatedPoints: dominated }
  }, [data])

  return (
    <ResponsiveContainer width="100%" height={400}>
      <ScatterChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis
          dataKey={xAxis}
          name="Prix"
          unit="€"
          type="number"
          domain={['dataMin - 50', 'dataMax + 50']}
        />
        <YAxis
          dataKey={yAxis}
          name="Score"
          type="number"
          domain={[0, 100]}
        />
        <Tooltip cursor={{ strokeDasharray: '3 3' }} />

        {/* Dominated points */}
        <Scatter
          name="Dominés"
          data={dominatedPoints}
          fill="#94a3b8"
          opacity={0.5}
        />

        {/* Pareto optimal points */}
        <Scatter
          name="Pareto Optimal"
          data={paretoPoints}
          fill="#22c55e"
          shape="star"
        />
      </ScatterChart>
    </ResponsiveContainer>
  )
}
```

### Compound Components

```tsx
// components/ui/comparison-card.tsx
import { createContext, useContext, type ReactNode } from 'react'

interface ComparisonCardContextType {
  productId: string
  isSelected: boolean
}

const ComparisonCardContext = createContext<ComparisonCardContextType | null>(null)

function useComparisonCard() {
  const context = useContext(ComparisonCardContext)
  if (!context) {
    throw new Error('ComparisonCard components must be used within ComparisonCard')
  }
  return context
}

// Root component
export function ComparisonCard({
  productId,
  isSelected,
  children,
}: {
  productId: string
  isSelected: boolean
  children: ReactNode
}) {
  return (
    <ComparisonCardContext.Provider value={{ productId, isSelected }}>
      <div
        className={`
          border rounded-lg p-4 transition-colors
          ${isSelected ? 'border-green-500 bg-green-50' : 'border-gray-200'}
        `}
      >
        {children}
      </div>
    </ComparisonCardContext.Provider>
  )
}

// Sub-components
ComparisonCard.Image = function Image({ src, alt }: { src: string; alt: string }) {
  return (
    <div className="relative aspect-square mb-4">
      <img src={src} alt={alt} className="object-contain" />
    </div>
  )
}

ComparisonCard.Title = function Title({ children }: { children: ReactNode }) {
  return <h3 className="font-semibold text-lg">{children}</h3>
}

ComparisonCard.Price = function Price({ value }: { value: number }) {
  return (
    <p className="text-xl font-bold text-green-600">
      {new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'EUR',
      }).format(value)}
    </p>
  )
}

ComparisonCard.Checkbox = function Checkbox({
  onToggle,
}: {
  onToggle: (id: string, selected: boolean) => void
}) {
  const { productId, isSelected } = useComparisonCard()

  return (
    <input
      type="checkbox"
      checked={isSelected}
      onChange={(e) => onToggle(productId, e.target.checked)}
      className="h-5 w-5 rounded border-gray-300"
    />
  )
}

// Usage
function ProductList() {
  return (
    <ComparisonCard productId="123" isSelected={false}>
      <ComparisonCard.Image src="/product.jpg" alt="Product" />
      <ComparisonCard.Title>iPhone 15 Pro</ComparisonCard.Title>
      <ComparisonCard.Price value={1199} />
      <ComparisonCard.Checkbox onToggle={handleToggle} />
    </ComparisonCard>
  )
}
```

## State Management

### Context + useReducer

```tsx
// contexts/comparison-context.tsx
'use client'

import {
  createContext,
  useContext,
  useReducer,
  type ReactNode,
  type Dispatch,
} from 'react'

interface ComparisonState {
  selectedProducts: string[]
  objectives: Objective[]
  results: ParetoResult[] | null
}

type ComparisonAction =
  | { type: 'ADD_PRODUCT'; productId: string }
  | { type: 'REMOVE_PRODUCT'; productId: string }
  | { type: 'SET_OBJECTIVES'; objectives: Objective[] }
  | { type: 'SET_RESULTS'; results: ParetoResult[] }
  | { type: 'RESET' }

const initialState: ComparisonState = {
  selectedProducts: [],
  objectives: [
    { name: 'price', sense: 'min', weight: 2 },
    { name: 'performance', sense: 'max', weight: 1 },
  ],
  results: null,
}

function comparisonReducer(
  state: ComparisonState,
  action: ComparisonAction
): ComparisonState {
  switch (action.type) {
    case 'ADD_PRODUCT':
      if (state.selectedProducts.length >= 5) return state
      return {
        ...state,
        selectedProducts: [...state.selectedProducts, action.productId],
      }
    case 'REMOVE_PRODUCT':
      return {
        ...state,
        selectedProducts: state.selectedProducts.filter(
          (id) => id !== action.productId
        ),
      }
    case 'SET_OBJECTIVES':
      return { ...state, objectives: action.objectives }
    case 'SET_RESULTS':
      return { ...state, results: action.results }
    case 'RESET':
      return initialState
    default:
      return state
  }
}

const ComparisonContext = createContext<{
  state: ComparisonState
  dispatch: Dispatch<ComparisonAction>
} | null>(null)

export function ComparisonProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(comparisonReducer, initialState)

  return (
    <ComparisonContext.Provider value={{ state, dispatch }}>
      {children}
    </ComparisonContext.Provider>
  )
}

export function useComparison() {
  const context = useContext(ComparisonContext)
  if (!context) {
    throw new Error('useComparison must be used within ComparisonProvider')
  }
  return context
}
```

### Custom Hooks

```tsx
// hooks/use-local-storage.ts
'use client'

import { useState, useEffect } from 'react'

export function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(initialValue)
  const [isLoaded, setIsLoaded] = useState(false)

  useEffect(() => {
    try {
      const item = window.localStorage.getItem(key)
      if (item) {
        setStoredValue(JSON.parse(item))
      }
    } catch (error) {
      console.warn(`Error reading localStorage key "${key}":`, error)
    }
    setIsLoaded(true)
  }, [key])

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value
      setStoredValue(valueToStore)
      window.localStorage.setItem(key, JSON.stringify(valueToStore))
    } catch (error) {
      console.warn(`Error setting localStorage key "${key}":`, error)
    }
  }

  return [storedValue, setValue, isLoaded] as const
}

// hooks/use-debounce.ts
import { useState, useEffect } from 'react'

export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => {
      clearTimeout(handler)
    }
  }, [value, delay])

  return debouncedValue
}
```

## Error Handling

### Error Boundaries

```tsx
// app/error.tsx
'use client'

import { useEffect } from 'react'
import { Button } from '@/components/ui/button'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // Log error to monitoring service
    console.error(error)
  }, [error])

  return (
    <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
      <h2 className="text-2xl font-bold">Une erreur est survenue</h2>
      <p className="text-gray-500">
        {error.message || 'Veuillez réessayer plus tard'}
      </p>
      <Button onClick={reset}>Réessayer</Button>
    </div>
  )
}

// app/products/[slug]/error.tsx - Page-specific error
'use client'

export default function ProductError({
  error,
  reset,
}: {
  error: Error
  reset: () => void
}) {
  return (
    <div className="container py-8">
      <h2>Produit non trouvé</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Réessayer</button>
    </div>
  )
}
```

### Not Found

```tsx
// app/not-found.tsx
import Link from 'next/link'
import { Button } from '@/components/ui/button'

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
      <h1 className="text-6xl font-bold">404</h1>
      <h2 className="text-2xl">Page non trouvée</h2>
      <p className="text-gray-500">
        La page que vous recherchez n'existe pas ou a été déplacée.
      </p>
      <Button asChild>
        <Link href="/">Retour à l'accueil</Link>
      </Button>
    </div>
  )
}

// Trigger 404 in Server Components
import { notFound } from 'next/navigation'

async function ProductPage({ params }: { params: { slug: string } }) {
  const product = await getProduct(params.slug)

  if (!product) {
    notFound()
  }

  return <ProductDetails product={product} />
}
```

## Performance Patterns

### Memoization

```tsx
'use client'

import { memo, useMemo, useCallback } from 'react'

// Memoized component
export const ProductCard = memo(function ProductCard({
  product,
  onSelect,
}: {
  product: Product
  onSelect: (id: string) => void
}) {
  // Memoized callback
  const handleClick = useCallback(() => {
    onSelect(product.id)
  }, [product.id, onSelect])

  return (
    <div onClick={handleClick}>
      {product.name}
    </div>
  )
})

// Memoized computation
function ProductList({ products, sortBy }: { products: Product[]; sortBy: string }) {
  const sortedProducts = useMemo(() => {
    return [...products].sort((a, b) => {
      if (sortBy === 'price') return a.minPrice - b.minPrice
      if (sortBy === 'name') return a.name.localeCompare(b.name)
      return 0
    })
  }, [products, sortBy])

  return (
    <div>
      {sortedProducts.map((p) => (
        <ProductCard key={p.id} product={p} onSelect={handleSelect} />
      ))}
    </div>
  )
}
```

### Code Splitting

```tsx
'use client'

import { lazy, Suspense } from 'react'
import { Skeleton } from '@/components/ui/skeleton'

// Lazy load heavy components
const ParetoChart = lazy(() => import('@/components/comparison/pareto-chart'))
const PriceHistoryChart = lazy(() => import('@/components/product/price-history-chart'))

export function ComparisonResults({ data }: { data: ParetoResult[] }) {
  return (
    <div>
      <Suspense fallback={<Skeleton className="h-[400px]" />}>
        <ParetoChart data={data} />
      </Suspense>
    </div>
  )
}
```

## TypeScript Patterns

```tsx
// types/components.ts
import type { ComponentPropsWithoutRef, ElementRef, forwardRef } from 'react'

// Polymorphic component type
type AsProp<C extends React.ElementType> = {
  as?: C
}

type PropsToOmit<C extends React.ElementType, P> = keyof (AsProp<C> & P)

type PolymorphicComponentProp<
  C extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<C>> &
  Omit<React.ComponentPropsWithoutRef<C>, PropsToOmit<C, Props>>

// Button with polymorphic as prop
type ButtonProps<C extends React.ElementType = 'button'> = PolymorphicComponentProp<
  C,
  { variant?: 'primary' | 'secondary' }
>

export function Button<C extends React.ElementType = 'button'>({
  as,
  variant = 'primary',
  children,
  ...props
}: ButtonProps<C>) {
  const Component = as || 'button'
  return <Component {...props}>{children}</Component>
}

// Usage
<Button as="a" href="/link">Link Button</Button>
<Button onClick={handleClick}>Regular Button</Button>
```

---

**See Also**:
- [Next.js 16](./nextjs.md)
- [Tailwind CSS](./tailwind.md)
- [TypeScript](./typescript.md)
