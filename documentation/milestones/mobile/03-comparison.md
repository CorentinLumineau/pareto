# Phase 03: Comparison UI

> **Pareto visualization with Victory Native**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      03 - Comparison UI                                ║
║  Initiative: Mobile                                            ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     5 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Build the comparison screen with Pareto visualization using Victory Native charts.

## Tasks

- [ ] Comparison screen layout
- [ ] Product selection for comparison
- [ ] Pareto scatter chart
- [ ] Side-by-side comparison
- [ ] Score visualization

## Comparison Screen

```typescript
// apps/mobile/app/(tabs)/compare.tsx
import { useState } from 'react'
import { View, Text, ScrollView, Pressable } from 'react-native'
import { useComparison } from '@pareto/api-client'
import { CompareSelection } from '@/components/comparison/compare-selection'
import { ParetoChart } from '@/components/comparison/pareto-chart'
import { TopPicks } from '@/components/comparison/top-picks'
import { ComparisonList } from '@/components/comparison/comparison-list'

export default function CompareScreen() {
    const [selectedIds, setSelectedIds] = useState<string[]>([])
    const { data, isLoading } = useComparison(selectedIds, {
        enabled: selectedIds.length >= 2,
    })

    const handleToggleProduct = (id: string) => {
        setSelectedIds((prev) =>
            prev.includes(id)
                ? prev.filter((p) => p !== id)
                : prev.length < 10
                ? [...prev, id]
                : prev
        )
    }

    return (
        <ScrollView className="flex-1 bg-gray-50">
            {/* Product selection */}
            <CompareSelection
                selectedIds={selectedIds}
                onToggle={handleToggleProduct}
                onClear={() => setSelectedIds([])}
            />

            {selectedIds.length < 2 ? (
                <View className="p-8 items-center">
                    <Text className="text-gray-500 text-center">
                        Sélectionnez au moins 2 produits pour les comparer
                    </Text>
                </View>
            ) : isLoading ? (
                <View className="p-8 items-center">
                    <Text className="text-gray-500">Calcul en cours...</Text>
                </View>
            ) : data ? (
                <>
                    {/* Top picks */}
                    <View className="p-4">
                        <Text className="text-lg font-semibold mb-4">
                            Nos recommandations
                        </Text>
                        <TopPicks picks={data.topPicks} products={data.products} />
                    </View>

                    {/* Pareto chart */}
                    <View className="p-4">
                        <Text className="text-lg font-semibold mb-4">
                            Frontière de Pareto
                        </Text>
                        <ParetoChart data={data} />
                    </View>

                    {/* Comparison list */}
                    <View className="p-4">
                        <Text className="text-lg font-semibold mb-4">
                            Comparaison détaillée
                        </Text>
                        <ComparisonList
                            frontier={data.frontier}
                            dominated={data.dominated}
                            scores={data.scores}
                        />
                    </View>
                </>
            ) : null}
        </ScrollView>
    )
}
```

## Pareto Chart with Victory Native

```typescript
// apps/mobile/components/comparison/pareto-chart.tsx
import { View, Text, Dimensions } from 'react-native'
import {
    VictoryChart,
    VictoryScatter,
    VictoryAxis,
    VictoryTooltip,
    VictoryTheme,
    VictoryLegend,
} from 'victory-native'
import { ComparisonResult } from '@pareto/types'
import { formatPrice } from '@pareto/utils'

interface ParetoChartProps {
    data: ComparisonResult
}

const { width: screenWidth } = Dimensions.get('window')
const chartWidth = screenWidth - 32

export function ParetoChart({ data }: ParetoChartProps) {
    const frontierData = data.frontier.map((p) => ({
        x: p.bestPrice || 0,
        y: data.scores[p.id]?.overall || 0,
        label: p.title.substring(0, 20),
        isFrontier: true,
    }))

    const dominatedData = data.dominated.map((p) => ({
        x: p.bestPrice || 0,
        y: data.scores[p.id]?.overall || 0,
        label: p.title.substring(0, 20),
        isFrontier: false,
    }))

    return (
        <View className="bg-white rounded-lg p-4">
            <VictoryChart
                width={chartWidth}
                height={300}
                theme={VictoryTheme.material}
                padding={{ top: 20, bottom: 50, left: 60, right: 20 }}
            >
                <VictoryAxis
                    label="Prix (€)"
                    tickFormat={(t) => `${t / 1000}k`}
                    style={{
                        axisLabel: { padding: 35, fontSize: 12 },
                        tickLabels: { fontSize: 10 },
                    }}
                />
                <VictoryAxis
                    dependentAxis
                    label="Score"
                    style={{
                        axisLabel: { padding: 40, fontSize: 12 },
                        tickLabels: { fontSize: 10 },
                    }}
                />

                {/* Dominated products (gray) */}
                <VictoryScatter
                    data={dominatedData}
                    style={{
                        data: {
                            fill: '#94a3b8',
                            opacity: 0.5,
                        },
                    }}
                    size={5}
                    labelComponent={<VictoryTooltip />}
                />

                {/* Frontier products (blue) */}
                <VictoryScatter
                    data={frontierData}
                    style={{
                        data: {
                            fill: '#3b82f6',
                        },
                    }}
                    size={7}
                    labelComponent={<VictoryTooltip />}
                />

                <VictoryLegend
                    x={chartWidth - 150}
                    y={10}
                    orientation="vertical"
                    gutter={10}
                    style={{ labels: { fontSize: 10 } }}
                    data={[
                        { name: 'Pareto optimal', symbol: { fill: '#3b82f6' } },
                        { name: 'Dominé', symbol: { fill: '#94a3b8' } },
                    ]}
                />
            </VictoryChart>

            <Text className="text-xs text-gray-500 text-center mt-2">
                Les produits bleus sont les meilleurs compromis prix/qualité
            </Text>
        </View>
    )
}
```

## Top Picks Component

```typescript
// apps/mobile/components/comparison/top-picks.tsx
import { View, Text, ScrollView, Pressable } from 'react-native'
import { Link } from 'expo-router'
import { ProductScore } from '@pareto/types'
import { formatPrice } from '@pareto/utils'
import { Star, DollarSign, Zap, Wallet, Scale } from 'lucide-react-native'

interface TopPicksProps {
    picks: Record<string, { productId: string; badge: string }>
    products: ProductScore[]
}

const PICK_INFO = {
    overall: { label: 'Meilleur choix', icon: Star, color: '#eab308' },
    value: { label: 'Qualité-prix', icon: DollarSign, color: '#22c55e' },
    premium: { label: 'Premium', icon: Zap, color: '#a855f7' },
    budget: { label: 'Économique', icon: Wallet, color: '#3b82f6' },
    balanced: { label: 'Équilibré', icon: Scale, color: '#f97316' },
}

export function TopPicks({ picks, products }: TopPicksProps) {
    const productMap = new Map(products.map((p) => [p.id, p]))

    return (
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {Object.entries(picks).map(([type, pick]) => {
                const info = PICK_INFO[type as keyof typeof PICK_INFO]
                const product = productMap.get(pick.productId)

                if (!info || !product) return null

                const Icon = info.icon

                return (
                    <Link key={type} href={`/products/${product.id}`} asChild>
                        <Pressable
                            className="bg-white rounded-lg p-3 mr-3 border border-gray-200"
                            style={{ width: 150 }}
                        >
                            <View className="flex-row items-center mb-2">
                                <Icon size={14} color={info.color} />
                                <Text
                                    className="text-xs font-medium ml-1"
                                    style={{ color: info.color }}
                                >
                                    {info.label}
                                </Text>
                            </View>

                            <Text className="font-medium text-sm" numberOfLines={2}>
                                {product.title}
                            </Text>

                            <Text className="text-primary font-bold mt-1">
                                {formatPrice(product.bestPrice || 0)}
                            </Text>
                        </Pressable>
                    </Link>
                )
            })}
        </ScrollView>
    )
}
```

## Comparison List

```typescript
// apps/mobile/components/comparison/comparison-list.tsx
import { View, Text, Pressable } from 'react-native'
import { Link } from 'expo-router'
import { ProductScore } from '@pareto/types'
import { formatPrice } from '@pareto/utils'
import { TrendingUp, TrendingDown } from 'lucide-react-native'

interface ComparisonListProps {
    frontier: ProductScore[]
    dominated: ProductScore[]
    scores: Record<string, any>
}

export function ComparisonList({ frontier, dominated, scores }: ComparisonListProps) {
    return (
        <View>
            {/* Frontier products */}
            {frontier.map((product) => (
                <ComparisonCard
                    key={product.id}
                    product={product}
                    score={scores[product.id]}
                    isFrontier
                />
            ))}

            {/* Dominated products */}
            {dominated.length > 0 && (
                <View className="mt-4">
                    <Text className="text-sm text-gray-500 mb-2">
                        Autres produits
                    </Text>
                    {dominated.map((product) => (
                        <ComparisonCard
                            key={product.id}
                            product={product}
                            score={scores[product.id]}
                            isFrontier={false}
                        />
                    ))}
                </View>
            )}
        </View>
    )
}

function ComparisonCard({
    product,
    score,
    isFrontier,
}: {
    product: ProductScore
    score: any
    isFrontier: boolean
}) {
    return (
        <Link href={`/products/${product.id}`} asChild>
            <Pressable
                className={`bg-white rounded-lg p-4 mb-2 border ${
                    isFrontier ? 'border-blue-200 bg-blue-50/50' : 'border-gray-200'
                }`}
            >
                <View className="flex-row items-center justify-between mb-2">
                    <View className="flex-1">
                        <Text className="font-semibold" numberOfLines={1}>
                            {product.title}
                        </Text>
                        <Text className="text-sm text-gray-500">{product.brand}</Text>
                    </View>
                    <Text className="text-lg font-bold text-primary">
                        {formatPrice(product.bestPrice || 0)}
                    </Text>
                </View>

                {/* Score bars */}
                <View className="flex-row items-center mt-2">
                    <View className="flex-1 mr-4">
                        <Text className="text-xs text-gray-500 mb-1">Score global</Text>
                        <View className="h-2 bg-gray-200 rounded-full overflow-hidden">
                            <View
                                className="h-full bg-blue-500 rounded-full"
                                style={{ width: `${score?.overall || 0}%` }}
                            />
                        </View>
                    </View>

                    <View className="flex-row items-center">
                        {isFrontier ? (
                            <>
                                <TrendingUp size={16} color="#3b82f6" />
                                <Text className="text-xs text-blue-600 ml-1 font-medium">
                                    Optimal
                                </Text>
                            </>
                        ) : (
                            <>
                                <TrendingDown size={16} color="#94a3b8" />
                                <Text className="text-xs text-gray-500 ml-1">
                                    Dominé
                                </Text>
                            </>
                        )}
                    </View>
                </View>
            </Pressable>
        </Link>
    )
}
```

## Deliverables

- [ ] Comparison screen layout
- [ ] Product selection UI
- [ ] Victory Native Pareto chart
- [ ] Top picks carousel
- [ ] Comparison list with scores

---

**Previous Phase**: [02-core-screens.md](./02-core-screens.md)
**Next Phase**: [04-native.md](./04-native.md)
**Back to**: [Mobile README](./README.md)
