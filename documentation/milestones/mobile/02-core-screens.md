# Phase 02: Core Screens

> **Home, product list, product detail**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      02 - Core Screens                                 ║
║  Initiative: Mobile                                            ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     5 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Build the core screens: home, product list, product detail, and search.

## Tasks

- [ ] Home screen with search
- [ ] Product list with infinite scroll
- [ ] Product detail screen
- [ ] Search screen
- [ ] Base components

## Home Screen

```typescript
// apps/mobile/app/(tabs)/index.tsx
import { View, Text, ScrollView, Pressable, TextInput } from 'react-native'
import { Link, router } from 'expo-router'
import { Search, TrendingUp } from 'lucide-react-native'
import { useProducts } from '@pareto/api-client'
import { formatPrice } from '@pareto/utils'
import { ProductCard } from '@/components/products/product-card'

export default function HomeScreen() {
    const { data: trending } = useProducts({ limit: 6, sort: 'trending' })

    return (
        <ScrollView className="flex-1 bg-white">
            {/* Hero */}
            <View className="px-4 py-8 bg-primary">
                <Text className="text-2xl font-bold text-white text-center mb-2">
                    Pareto
                </Text>
                <Text className="text-white/80 text-center mb-6">
                    Trouvez le smartphone parfait
                </Text>

                {/* Search bar */}
                <Pressable
                    onPress={() => router.push('/search')}
                    className="bg-white rounded-full px-4 py-3 flex-row items-center"
                >
                    <Search size={20} color="#64748b" />
                    <Text className="ml-2 text-gray-500">
                        Rechercher un smartphone...
                    </Text>
                </Pressable>
            </View>

            {/* Trending products */}
            <View className="px-4 py-6">
                <View className="flex-row items-center mb-4">
                    <TrendingUp size={20} color="#3b82f6" />
                    <Text className="text-lg font-semibold ml-2">
                        Tendances
                    </Text>
                </View>

                <View className="flex-row flex-wrap -mx-2">
                    {trending?.products.slice(0, 6).map((product) => (
                        <View key={product.id} className="w-1/2 px-2 mb-4">
                            <ProductCard product={product} compact />
                        </View>
                    ))}
                </View>

                <Link href="/products" asChild>
                    <Pressable className="bg-gray-100 rounded-lg py-3 mt-2">
                        <Text className="text-center text-primary font-medium">
                            Voir tous les produits
                        </Text>
                    </Pressable>
                </Link>
            </View>
        </ScrollView>
    )
}
```

## Product Card Component

```typescript
// apps/mobile/components/products/product-card.tsx
import { View, Text, Image, Pressable } from 'react-native'
import { Link } from 'expo-router'
import { Product } from '@pareto/types'
import { formatPrice } from '@pareto/utils'
import { Star } from 'lucide-react-native'

interface ProductCardProps {
    product: Product
    compact?: boolean
}

export function ProductCard({ product, compact = false }: ProductCardProps) {
    const bestPrice = product.offers?.reduce(
        (min, o) => (o.price && o.price < min ? o.price : min),
        Infinity
    )

    return (
        <Link href={`/products/${product.id}`} asChild>
            <Pressable
                className={`bg-white rounded-lg border border-gray-200 overflow-hidden ${
                    compact ? '' : 'flex-row'
                }`}
            >
                {/* Image */}
                <View className={`bg-gray-100 ${compact ? 'aspect-square' : 'w-24 h-24'}`}>
                    {product.imageUrl && (
                        <Image
                            source={{ uri: product.imageUrl }}
                            className="w-full h-full"
                            resizeMode="contain"
                        />
                    )}
                </View>

                {/* Info */}
                <View className="p-3 flex-1">
                    <Text className="text-xs text-gray-500 mb-1">
                        {product.brand}
                    </Text>
                    <Text
                        className="font-medium mb-2"
                        numberOfLines={2}
                    >
                        {product.title}
                    </Text>

                    <View className="flex-row items-center justify-between">
                        <Text className="text-lg font-bold text-primary">
                            {formatPrice(bestPrice || 0)}
                        </Text>

                        {product.score && product.score > 80 && (
                            <View className="flex-row items-center bg-yellow-100 px-2 py-1 rounded">
                                <Star size={12} color="#eab308" fill="#eab308" />
                                <Text className="text-xs text-yellow-700 ml-1">
                                    Top
                                </Text>
                            </View>
                        )}
                    </View>

                    <Text className="text-xs text-gray-500 mt-1">
                        {product.offers?.length || 0} offres
                    </Text>
                </View>
            </Pressable>
        </Link>
    )
}
```

## Products List Screen

```typescript
// apps/mobile/app/(tabs)/products.tsx
import { useState, useCallback } from 'react'
import { View, Text, FlatList, ActivityIndicator, RefreshControl } from 'react-native'
import { useProducts } from '@pareto/api-client'
import { ProductCard } from '@/components/products/product-card'
import { FilterBar } from '@/components/products/filter-bar'

export default function ProductsScreen() {
    const [page, setPage] = useState(1)
    const [brand, setBrand] = useState<string>()

    const {
        data,
        isLoading,
        isFetchingNextPage,
        fetchNextPage,
        hasNextPage,
        refetch,
        isRefetching,
    } = useProducts({ page, brand, limit: 20 })

    const handleEndReached = useCallback(() => {
        if (hasNextPage && !isFetchingNextPage) {
            fetchNextPage()
        }
    }, [hasNextPage, isFetchingNextPage, fetchNextPage])

    const renderFooter = () => {
        if (!isFetchingNextPage) return null
        return (
            <View className="py-4">
                <ActivityIndicator size="small" color="#3b82f6" />
            </View>
        )
    }

    if (isLoading) {
        return (
            <View className="flex-1 items-center justify-center">
                <ActivityIndicator size="large" color="#3b82f6" />
            </View>
        )
    }

    return (
        <View className="flex-1 bg-gray-50">
            <FilterBar
                selectedBrand={brand}
                onBrandChange={setBrand}
            />

            <FlatList
                data={data?.products}
                keyExtractor={(item) => item.id}
                renderItem={({ item }) => (
                    <View className="px-4 py-2">
                        <ProductCard product={item} />
                    </View>
                )}
                onEndReached={handleEndReached}
                onEndReachedThreshold={0.5}
                ListFooterComponent={renderFooter}
                refreshControl={
                    <RefreshControl
                        refreshing={isRefetching}
                        onRefresh={refetch}
                        colors={['#3b82f6']}
                    />
                }
                ListEmptyComponent={
                    <View className="flex-1 items-center justify-center py-20">
                        <Text className="text-gray-500">Aucun produit trouvé</Text>
                    </View>
                }
            />
        </View>
    )
}
```

## Product Detail Screen

```typescript
// apps/mobile/app/products/[id].tsx
import { View, Text, ScrollView, Image, Pressable, Linking } from 'react-native'
import { useLocalSearchParams } from 'expo-router'
import { useProduct } from '@pareto/api-client'
import { formatPrice } from '@pareto/utils'
import { ExternalLink, Star, Check, X } from 'lucide-react-native'
import { PriceHistoryChart } from '@/components/products/price-history-chart'

export default function ProductDetailScreen() {
    const { id } = useLocalSearchParams<{ id: string }>()
    const { data: product, isLoading } = useProduct(id)

    if (isLoading || !product) {
        return (
            <View className="flex-1 items-center justify-center">
                <Text>Chargement...</Text>
            </View>
        )
    }

    const bestOffer = product.offers?.reduce(
        (best, o) => (!best || (o.price && o.price < best.price!) ? o : best),
        product.offers[0]
    )

    return (
        <ScrollView className="flex-1 bg-white">
            {/* Image */}
            <View className="bg-gray-100 aspect-square">
                {product.imageUrl && (
                    <Image
                        source={{ uri: product.imageUrl }}
                        className="w-full h-full"
                        resizeMode="contain"
                    />
                )}
            </View>

            {/* Info */}
            <View className="p-4">
                <Text className="text-gray-500 mb-1">{product.brand}</Text>
                <Text className="text-xl font-bold mb-2">{product.title}</Text>

                {bestOffer && (
                    <View className="flex-row items-center mb-4">
                        <Text className="text-2xl font-bold text-primary">
                            {formatPrice(bestOffer.price || 0)}
                        </Text>
                        <Text className="text-gray-500 ml-2">
                            chez {bestOffer.retailerName}
                        </Text>
                    </View>
                )}

                {/* Score badge */}
                {product.score && (
                    <View className="flex-row items-center bg-blue-50 p-3 rounded-lg mb-4">
                        <Star size={20} color="#3b82f6" />
                        <Text className="ml-2 font-semibold">
                            Score Pareto: {product.score}/100
                        </Text>
                    </View>
                )}
            </View>

            {/* Offers */}
            <View className="p-4 border-t border-gray-200">
                <Text className="text-lg font-semibold mb-4">
                    Comparer les offres
                </Text>

                {product.offers?.map((offer) => (
                    <Pressable
                        key={offer.id}
                        onPress={() => Linking.openURL(`${API_URL}/go/${offer.id}`)}
                        className="flex-row items-center justify-between py-3 border-b border-gray-100"
                    >
                        <View className="flex-1">
                            <Text className="font-medium">{offer.retailerName}</Text>
                            <View className="flex-row items-center mt-1">
                                {offer.inStock ? (
                                    <>
                                        <Check size={14} color="#22c55e" />
                                        <Text className="text-green-600 text-xs ml-1">
                                            En stock
                                        </Text>
                                    </>
                                ) : (
                                    <>
                                        <X size={14} color="#ef4444" />
                                        <Text className="text-red-600 text-xs ml-1">
                                            Rupture
                                        </Text>
                                    </>
                                )}
                            </View>
                        </View>

                        <View className="flex-row items-center">
                            <Text className="text-lg font-bold mr-2">
                                {formatPrice(offer.price || 0)}
                            </Text>
                            <ExternalLink size={16} color="#3b82f6" />
                        </View>
                    </Pressable>
                ))}
            </View>

            {/* Price history */}
            <View className="p-4">
                <Text className="text-lg font-semibold mb-4">
                    Historique des prix
                </Text>
                <PriceHistoryChart productId={product.id} />
            </View>
        </ScrollView>
    )
}
```

## Search Screen

```typescript
// apps/mobile/app/search.tsx
import { useState } from 'react'
import { View, Text, TextInput, FlatList, Pressable } from 'react-native'
import { router } from 'expo-router'
import { Search as SearchIcon, X } from 'lucide-react-native'
import { useSearch } from '@pareto/api-client'
import { ProductCard } from '@/components/products/product-card'
import { useDebounce } from '@/lib/hooks'

export default function SearchScreen() {
    const [query, setQuery] = useState('')
    const debouncedQuery = useDebounce(query, 300)

    const { data, isLoading } = useSearch(debouncedQuery, {
        enabled: debouncedQuery.length >= 2,
    })

    return (
        <View className="flex-1 bg-white">
            {/* Search input */}
            <View className="p-4 border-b border-gray-200">
                <View className="flex-row items-center bg-gray-100 rounded-lg px-3">
                    <SearchIcon size={20} color="#64748b" />
                    <TextInput
                        value={query}
                        onChangeText={setQuery}
                        placeholder="Rechercher un smartphone..."
                        className="flex-1 py-3 px-2"
                        autoFocus
                        returnKeyType="search"
                    />
                    {query.length > 0 && (
                        <Pressable onPress={() => setQuery('')}>
                            <X size={20} color="#64748b" />
                        </Pressable>
                    )}
                </View>
            </View>

            {/* Results */}
            {query.length < 2 ? (
                <View className="flex-1 items-center justify-center">
                    <Text className="text-gray-500">
                        Tapez au moins 2 caractères
                    </Text>
                </View>
            ) : isLoading ? (
                <View className="flex-1 items-center justify-center">
                    <Text className="text-gray-500">Recherche...</Text>
                </View>
            ) : (
                <FlatList
                    data={data?.results}
                    keyExtractor={(item) => item.id}
                    renderItem={({ item }) => (
                        <View className="px-4 py-2">
                            <ProductCard product={item} />
                        </View>
                    )}
                    ListEmptyComponent={
                        <View className="flex-1 items-center justify-center py-20">
                            <Text className="text-gray-500">
                                Aucun résultat pour "{query}"
                            </Text>
                        </View>
                    }
                />
            )}
        </View>
    )
}
```

## Deliverables

- [ ] Home screen with search
- [ ] Product list with infinite scroll
- [ ] Product detail with offers
- [ ] Search screen
- [ ] Base components (ProductCard, FilterBar)

---

**Previous Phase**: [01-setup.md](./01-setup.md)
**Next Phase**: [03-comparison.md](./03-comparison.md)
**Back to**: [Mobile README](./README.md)
