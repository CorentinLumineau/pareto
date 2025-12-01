# Phase 03: Comparison UI

> **Pareto visualization and product comparison**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      03 - Comparison UI                                ║
║  Initiative: Frontend Web                                      ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     5 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Build the comparison page with Pareto frontier visualization and side-by-side product comparison.

## Tasks

- [ ] Comparison state management
- [ ] Pareto scatter plot chart
- [ ] Side-by-side comparison table
- [ ] Score explanations
- [ ] "Best for" recommendations

## Comparison Page

```typescript
// apps/web/src/app/compare/page.tsx
'use client'

import { useSearchParams } from 'next/navigation'
import { useComparison } from '@pareto/api-client'
import { ParetoChart } from '@/components/comparison/pareto-chart'
import { ComparisonTable } from '@/components/comparison/comparison-table'
import { ScoreExplanation } from '@/components/comparison/score-explanation'
import { TopPicks } from '@/components/comparison/top-picks'
import { CompareToolbar } from '@/components/comparison/compare-toolbar'
import { Skeleton } from '@/components/ui/skeleton'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

export default function ComparePage() {
    const searchParams = useSearchParams()
    const productIds = searchParams.get('ids')?.split(',') || []

    const { data, isLoading, error } = useComparison(productIds)

    if (productIds.length < 2) {
        return (
            <div className="container py-12 text-center">
                <h1 className="text-2xl font-bold mb-4">Comparer des produits</h1>
                <p className="text-muted-foreground">
                    Sélectionnez au moins 2 produits pour les comparer.
                </p>
            </div>
        )
    }

    if (isLoading) {
        return <ComparisonSkeleton />
    }

    if (error || !data) {
        return (
            <div className="container py-12 text-center">
                <p className="text-destructive">Erreur lors du chargement</p>
            </div>
        )
    }

    return (
        <div className="container py-8">
            <h1 className="text-3xl font-bold mb-2">Comparaison</h1>
            <p className="text-muted-foreground mb-8">
                {data.totalProducts} produits comparés • {data.frontierCount} sur la frontière Pareto
            </p>

            {/* Top picks */}
            <section className="mb-8">
                <TopPicks picks={data.topPicks} products={data.products} />
            </section>

            <Tabs defaultValue="chart" className="space-y-6">
                <TabsList>
                    <TabsTrigger value="chart">Graphique Pareto</TabsTrigger>
                    <TabsTrigger value="table">Comparaison détaillée</TabsTrigger>
                </TabsList>

                <TabsContent value="chart">
                    <div className="grid lg:grid-cols-3 gap-6">
                        <div className="lg:col-span-2">
                            <ParetoChart data={data} />
                        </div>
                        <div>
                            <ScoreExplanation />
                        </div>
                    </div>
                </TabsContent>

                <TabsContent value="table">
                    <ComparisonTable
                        frontier={data.frontier}
                        dominated={data.dominated}
                        scores={data.scores}
                    />
                </TabsContent>
            </Tabs>
        </div>
    )
}
```

## Pareto Chart

```typescript
// apps/web/src/components/comparison/pareto-chart.tsx
'use client'

import { useMemo, useState } from 'react'
import {
    ScatterChart,
    Scatter,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
    ReferenceLine,
    Legend,
} from 'recharts'
import { ComparisonResult, ProductScore } from '@pareto/types'
import { formatPrice } from '@pareto/utils'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select'

interface ParetoChartProps {
    data: ComparisonResult
}

const CRITERIA = [
    { value: 'price', label: 'Prix', invert: true },
    { value: 'storage', label: 'Stockage', invert: false },
    { value: 'ram', label: 'RAM', invert: false },
    { value: 'overall', label: 'Score global', invert: false },
]

export function ParetoChart({ data }: ParetoChartProps) {
    const [xAxis, setXAxis] = useState('price')
    const [yAxis, setYAxis] = useState('overall')

    const chartData = useMemo(() => {
        const allProducts = [...data.frontier, ...data.dominated]

        return allProducts.map((product) => {
            const score = data.scores[product.id]
            return {
                id: product.id,
                name: product.title,
                brand: product.brand,
                x: getAxisValue(product, score, xAxis),
                y: getAxisValue(product, score, yAxis),
                isFrontier: data.frontier.some(f => f.id === product.id),
                price: product.bestPrice,
            }
        })
    }, [data, xAxis, yAxis])

    const frontierData = chartData.filter(d => d.isFrontier)
    const dominatedData = chartData.filter(d => !d.isFrontier)

    return (
        <Card>
            <CardHeader>
                <CardTitle className="flex items-center justify-between">
                    <span>Frontière de Pareto</span>
                    <div className="flex gap-4">
                        <Select value={xAxis} onValueChange={setXAxis}>
                            <SelectTrigger className="w-32">
                                <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                                {CRITERIA.map(c => (
                                    <SelectItem key={c.value} value={c.value}>
                                        {c.label}
                                    </SelectItem>
                                ))}
                            </SelectContent>
                        </Select>
                        <span className="text-muted-foreground">vs</span>
                        <Select value={yAxis} onValueChange={setYAxis}>
                            <SelectTrigger className="w-32">
                                <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                                {CRITERIA.map(c => (
                                    <SelectItem key={c.value} value={c.value}>
                                        {c.label}
                                    </SelectItem>
                                ))}
                            </SelectContent>
                        </Select>
                    </div>
                </CardTitle>
            </CardHeader>
            <CardContent>
                <ResponsiveContainer width="100%" height={400}>
                    <ScatterChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis
                            type="number"
                            dataKey="x"
                            name={CRITERIA.find(c => c.value === xAxis)?.label}
                            tickFormatter={xAxis === 'price' ? (v) => formatPrice(v) : undefined}
                        />
                        <YAxis
                            type="number"
                            dataKey="y"
                            name={CRITERIA.find(c => c.value === yAxis)?.label}
                        />
                        <Tooltip content={<CustomTooltip />} />
                        <Legend />

                        {/* Dominated products (gray) */}
                        <Scatter
                            name="Produits dominés"
                            data={dominatedData}
                            fill="#94a3b8"
                            opacity={0.5}
                        />

                        {/* Frontier products (colored) */}
                        <Scatter
                            name="Frontière Pareto"
                            data={frontierData}
                            fill="#3b82f6"
                        />
                    </ScatterChart>
                </ResponsiveContainer>

                <div className="mt-4 p-4 bg-muted rounded-lg">
                    <p className="text-sm text-muted-foreground">
                        <strong>Frontière de Pareto:</strong> Les produits sur la frontière
                        représentent les meilleurs compromis - aucun autre produit n'est
                        meilleur sur tous les critères à la fois.
                    </p>
                </div>
            </CardContent>
        </Card>
    )
}

function getAxisValue(product: ProductScore, score: any, axis: string): number {
    switch (axis) {
        case 'price':
            return product.bestPrice || 0
        case 'overall':
            return score?.overall || 0
        case 'storage':
            return score?.criteria?.storage || 0
        case 'ram':
            return score?.criteria?.ram || 0
        default:
            return 0
    }
}

function CustomTooltip({ active, payload }: any) {
    if (!active || !payload?.length) return null

    const data = payload[0].payload
    return (
        <div className="bg-background border rounded-lg p-3 shadow-lg">
            <p className="font-semibold">{data.name}</p>
            <p className="text-sm text-muted-foreground">{data.brand}</p>
            <p className="text-lg font-bold mt-1">{formatPrice(data.price)}</p>
            {data.isFrontier && (
                <span className="text-xs text-blue-600 font-medium">
                    ★ Frontière Pareto
                </span>
            )}
        </div>
    )
}
```

## Comparison Table

```typescript
// apps/web/src/components/comparison/comparison-table.tsx
import { ProductScore } from '@pareto/types'
import { formatPrice } from '@pareto/utils'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { Star, TrendingUp, DollarSign, Zap } from 'lucide-react'

interface ComparisonTableProps {
    frontier: ProductScore[]
    dominated: ProductScore[]
    scores: Record<string, any>
}

export function ComparisonTable({ frontier, dominated, scores }: ComparisonTableProps) {
    const allProducts = [...frontier, ...dominated]

    const criteria = [
        { key: 'overall', label: 'Score global', icon: Star },
        { key: 'value', label: 'Rapport qualité-prix', icon: DollarSign },
        { key: 'performance', label: 'Performance', icon: Zap },
    ]

    return (
        <div className="overflow-x-auto">
            <Table>
                <TableHeader>
                    <TableRow>
                        <TableHead className="w-64">Produit</TableHead>
                        <TableHead>Prix</TableHead>
                        {criteria.map(c => (
                            <TableHead key={c.key}>{c.label}</TableHead>
                        ))}
                        <TableHead>Statut</TableHead>
                    </TableRow>
                </TableHeader>
                <TableBody>
                    {allProducts.map((product) => {
                        const score = scores[product.id]
                        const isFrontier = frontier.some(f => f.id === product.id)

                        return (
                            <TableRow key={product.id} className={isFrontier ? 'bg-blue-50/50' : ''}>
                                <TableCell>
                                    <div>
                                        <p className="font-medium">{product.title}</p>
                                        <p className="text-sm text-muted-foreground">
                                            {product.brand}
                                        </p>
                                    </div>
                                </TableCell>
                                <TableCell className="font-bold">
                                    {formatPrice(product.bestPrice || 0)}
                                </TableCell>
                                {criteria.map(c => (
                                    <TableCell key={c.key}>
                                        <div className="flex items-center gap-2">
                                            <Progress
                                                value={score?.[c.key] || 0}
                                                className="w-20"
                                            />
                                            <span className="text-sm">
                                                {Math.round(score?.[c.key] || 0)}
                                            </span>
                                        </div>
                                    </TableCell>
                                ))}
                                <TableCell>
                                    {isFrontier ? (
                                        <Badge>
                                            <TrendingUp className="h-3 w-3 mr-1" />
                                            Optimal
                                        </Badge>
                                    ) : (
                                        <Badge variant="secondary">Dominé</Badge>
                                    )}
                                </TableCell>
                            </TableRow>
                        )
                    })}
                </TableBody>
            </Table>
        </div>
    )
}
```

## Top Picks Component

```typescript
// apps/web/src/components/comparison/top-picks.tsx
import { ProductScore } from '@pareto/types'
import { formatPrice } from '@pareto/utils'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Star, DollarSign, Zap, Scale, Wallet } from 'lucide-react'
import Link from 'next/link'

interface TopPicksProps {
    picks: Record<string, { productId: string; badge: string }>
    products: ProductScore[]
}

const PICK_INFO = {
    overall: { label: 'Meilleur choix', icon: Star, color: 'bg-yellow-100 text-yellow-800' },
    value: { label: 'Meilleur rapport qualité-prix', icon: DollarSign, color: 'bg-green-100 text-green-800' },
    premium: { label: 'Premium', icon: Zap, color: 'bg-purple-100 text-purple-800' },
    budget: { label: 'Choix économique', icon: Wallet, color: 'bg-blue-100 text-blue-800' },
    balanced: { label: 'Le plus équilibré', icon: Scale, color: 'bg-orange-100 text-orange-800' },
}

export function TopPicks({ picks, products }: TopPicksProps) {
    const productMap = new Map(products.map(p => [p.id, p]))

    return (
        <div className="grid md:grid-cols-3 lg:grid-cols-5 gap-4">
            {Object.entries(picks).map(([type, pick]) => {
                const info = PICK_INFO[type as keyof typeof PICK_INFO]
                const product = productMap.get(pick.productId)

                if (!info || !product) return null

                const Icon = info.icon

                return (
                    <Card key={type} className="relative overflow-hidden">
                        <div className={`absolute top-0 left-0 right-0 h-1 ${info.color.split(' ')[0]}`} />
                        <CardHeader className="pb-2">
                            <Badge variant="outline" className={info.color}>
                                <Icon className="h-3 w-3 mr-1" />
                                {info.label}
                            </Badge>
                        </CardHeader>
                        <CardContent>
                            <h3 className="font-semibold line-clamp-2 mb-1">
                                {product.title}
                            </h3>
                            <p className="text-lg font-bold mb-2">
                                {formatPrice(product.bestPrice || 0)}
                            </p>
                            <Button asChild size="sm" variant="outline" className="w-full">
                                <Link href={`/products/${product.id}`}>
                                    Voir le produit
                                </Link>
                            </Button>
                        </CardContent>
                    </Card>
                )
            })}
        </div>
    )
}
```

## Deliverables

- [ ] Pareto scatter chart with axis selection
- [ ] Comparison table with scores
- [ ] Top picks recommendations
- [ ] Score explanations
- [ ] Responsive design
- [ ] Interactive tooltips

---

**Previous Phase**: [02-core-pages.md](./02-core-pages.md)
**Next Phase**: [04-seo.md](./04-seo.md)
**Back to**: [Frontend README](./README.md)
