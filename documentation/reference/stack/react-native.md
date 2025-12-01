# React Native 0.79 - Mobile Runtime

> **Cross-platform mobile development with the New Architecture**

## Version Info

| Attribute | Value |
|-----------|-------|
| **Version** | 0.79.0 |
| **Release** | May 2025 |
| **Expo SDK** | 53 |
| **Context7** | `/websites/reactnative_dev` |

## New Architecture (Default)

React Native 0.79 enables the New Architecture by default:
- **JSI (JavaScript Interface)**: Direct synchronous calls between JS and native
- **Fabric**: New rendering system with concurrent features
- **TurboModules**: Lazy-loaded native modules

### Bridge vs New Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     OLD ARCHITECTURE                          │
├──────────────────────────────────────────────────────────────┤
│  JavaScript Thread  ──async──▶  Bridge  ──async──▶  Native   │
│                                  (JSON)                       │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                     NEW ARCHITECTURE                          │
├──────────────────────────────────────────────────────────────┤
│  JavaScript Thread  ◀──sync──▶  JSI  ◀──sync──▶  Native      │
│                                 (C++)                         │
└──────────────────────────────────────────────────────────────┘
```

## Core Components

### View & Layout

```tsx
import { View, StyleSheet } from 'react-native'

// Flexbox layout (default)
export function ProductGrid({ children }: { children: React.ReactNode }) {
  return (
    <View style={styles.grid}>
      {children}
    </View>
  )
}

const styles = StyleSheet.create({
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 16,
    padding: 16,
  },
})

// With NativeWind (Tailwind)
export function ProductGridNW({ children }: { children: React.ReactNode }) {
  return (
    <View className="flex-row flex-wrap gap-4 p-4">
      {children}
    </View>
  )
}
```

### Text

```tsx
import { Text, StyleSheet } from 'react-native'

export function ProductTitle({ children }: { children: string }) {
  return <Text style={styles.title}>{children}</Text>
}

export function ProductPrice({ value }: { value: number }) {
  return (
    <Text style={styles.price}>
      {new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'EUR',
      }).format(value)}
    </Text>
  )
}

const styles = StyleSheet.create({
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1f2937',
  },
  price: {
    fontSize: 24,
    fontWeight: '700',
    color: '#22c55e',
  },
})
```

### Image

```tsx
import { Image, View } from 'react-native'

export function ProductImage({
  uri,
  size = 200,
}: {
  uri: string
  size?: number
}) {
  return (
    <View
      style={{
        width: size,
        height: size,
        backgroundColor: '#f3f4f6',
        borderRadius: 8,
        overflow: 'hidden',
      }}
    >
      <Image
        source={{ uri }}
        style={{ width: '100%', height: '100%' }}
        resizeMode="contain"
      />
    </View>
  )
}

// With loading state
import { useState } from 'react'
import { ActivityIndicator } from 'react-native'

export function ProductImageWithLoader({ uri }: { uri: string }) {
  const [loading, setLoading] = useState(true)

  return (
    <View className="aspect-square bg-gray-100 rounded-lg overflow-hidden">
      {loading && (
        <View className="absolute inset-0 items-center justify-center">
          <ActivityIndicator color="#22c55e" />
        </View>
      )}
      <Image
        source={{ uri }}
        className="w-full h-full"
        resizeMode="contain"
        onLoadEnd={() => setLoading(false)}
      />
    </View>
  )
}
```

### ScrollView & FlatList

```tsx
import { FlatList, RefreshControl } from 'react-native'
import { useState, useCallback } from 'react'

export function ProductList({
  products,
  onRefresh,
  onEndReached,
}: {
  products: Product[]
  onRefresh?: () => Promise<void>
  onEndReached?: () => void
}) {
  const [refreshing, setRefreshing] = useState(false)

  const handleRefresh = useCallback(async () => {
    if (!onRefresh) return
    setRefreshing(true)
    await onRefresh()
    setRefreshing(false)
  }, [onRefresh])

  const renderItem = useCallback(
    ({ item }: { item: Product }) => <ProductCard product={item} />,
    []
  )

  const keyExtractor = useCallback((item: Product) => item.id, [])

  return (
    <FlatList
      data={products}
      renderItem={renderItem}
      keyExtractor={keyExtractor}
      numColumns={2}
      columnWrapperStyle={{ gap: 16 }}
      contentContainerStyle={{ padding: 16, gap: 16 }}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
      }
      onEndReached={onEndReached}
      onEndReachedThreshold={0.5}
      // Performance optimizations
      removeClippedSubviews={true}
      maxToRenderPerBatch={10}
      windowSize={5}
      initialNumToRender={6}
    />
  )
}
```

### Pressable & TouchableOpacity

```tsx
import { Pressable, Text, StyleSheet } from 'react-native'

export function Button({
  title,
  onPress,
  variant = 'primary',
}: {
  title: string
  onPress: () => void
  variant?: 'primary' | 'secondary'
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        variant === 'primary' ? styles.primary : styles.secondary,
        pressed && styles.pressed,
      ]}
    >
      <Text
        style={[
          styles.text,
          variant === 'secondary' && styles.textSecondary,
        ]}
      >
        {title}
      </Text>
    </Pressable>
  )
}

const styles = StyleSheet.create({
  button: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  primary: {
    backgroundColor: '#22c55e',
  },
  secondary: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: '#22c55e',
  },
  pressed: {
    opacity: 0.8,
  },
  text: {
    color: 'white',
    fontWeight: '600',
    fontSize: 16,
  },
  textSecondary: {
    color: '#22c55e',
  },
})

// With NativeWind
export function ButtonNW({
  title,
  onPress,
  variant = 'primary',
}: {
  title: string
  onPress: () => void
  variant?: 'primary' | 'secondary'
}) {
  return (
    <Pressable
      onPress={onPress}
      className={`
        px-6 py-3 rounded-lg items-center
        ${variant === 'primary' ? 'bg-pareto-600' : 'border border-pareto-600'}
        active:opacity-80
      `}
    >
      <Text
        className={`
          font-semibold text-base
          ${variant === 'primary' ? 'text-white' : 'text-pareto-600'}
        `}
      >
        {title}
      </Text>
    </Pressable>
  )
}
```

### TextInput

```tsx
import { TextInput, View, Text } from 'react-native'
import { useState } from 'react'

export function SearchInput({
  onSearch,
}: {
  onSearch: (query: string) => void
}) {
  const [value, setValue] = useState('')

  const handleSubmit = () => {
    if (value.trim()) {
      onSearch(value.trim())
    }
  }

  return (
    <View className="flex-row items-center bg-gray-100 rounded-lg px-4">
      <SearchIcon className="w-5 h-5 text-gray-400" />
      <TextInput
        value={value}
        onChangeText={setValue}
        onSubmitEditing={handleSubmit}
        placeholder="Rechercher un produit..."
        placeholderTextColor="#9ca3af"
        returnKeyType="search"
        autoCapitalize="none"
        autoCorrect={false}
        className="flex-1 py-3 px-2 text-base"
      />
      {value.length > 0 && (
        <Pressable onPress={() => setValue('')}>
          <XIcon className="w-5 h-5 text-gray-400" />
        </Pressable>
      )}
    </View>
  )
}
```

## Navigation Patterns

### Stack Navigation

```tsx
// app/_layout.tsx with expo-router
import { Stack } from 'expo-router'

export default function RootLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: '#fff' },
        headerTintColor: '#22c55e',
        headerTitleStyle: { fontWeight: '600' },
        contentStyle: { backgroundColor: '#fff' },
        animation: 'slide_from_right',
      }}
    >
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen
        name="product/[slug]"
        options={{
          headerBackTitle: 'Retour',
          headerTransparent: true,
          headerBlurEffect: 'light',
        }}
      />
      <Stack.Screen
        name="search"
        options={{
          presentation: 'modal',
          animation: 'slide_from_bottom',
        }}
      />
    </Stack>
  )
}
```

### Tab Navigation

```tsx
// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router'
import { Platform } from 'react-native'
import { BlurView } from 'expo-blur'

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: '#22c55e',
        tabBarInactiveTintColor: '#9ca3af',
        tabBarStyle: {
          position: 'absolute',
          borderTopWidth: 0,
          elevation: 0,
        },
        tabBarBackground: () =>
          Platform.OS === 'ios' ? (
            <BlurView
              intensity={100}
              style={{ flex: 1 }}
              tint="light"
            />
          ) : null,
      }}
    >
      {/* Tab screens */}
    </Tabs>
  )
}
```

## Gestures & Animations

### React Native Gesture Handler

```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler'
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  runOnJS,
} from 'react-native-reanimated'

export function SwipeableCard({
  onSwipeRight,
  onSwipeLeft,
  children,
}: {
  onSwipeRight?: () => void
  onSwipeLeft?: () => void
  children: React.ReactNode
}) {
  const translateX = useSharedValue(0)

  const pan = Gesture.Pan()
    .onUpdate((e) => {
      translateX.value = e.translationX
    })
    .onEnd((e) => {
      if (e.translationX > 100 && onSwipeRight) {
        runOnJS(onSwipeRight)()
      } else if (e.translationX < -100 && onSwipeLeft) {
        runOnJS(onSwipeLeft)()
      }
      translateX.value = withSpring(0)
    })

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.value }],
  }))

  return (
    <GestureDetector gesture={pan}>
      <Animated.View style={animatedStyle}>{children}</Animated.View>
    </GestureDetector>
  )
}
```

### Reanimated Animations

```tsx
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSequence,
  withDelay,
  Easing,
  FadeIn,
  FadeOut,
  Layout,
} from 'react-native-reanimated'

// Entering/Exiting animations
export function AnimatedProductCard({ product }: { product: Product }) {
  return (
    <Animated.View
      entering={FadeIn.duration(300)}
      exiting={FadeOut.duration(200)}
      layout={Layout.springify()}
    >
      <ProductCard product={product} />
    </Animated.View>
  )
}

// Custom animation
export function PulsingDot() {
  const scale = useSharedValue(1)

  useEffect(() => {
    scale.value = withSequence(
      withTiming(1.3, { duration: 500 }),
      withTiming(1, { duration: 500 })
    )
    // Repeat
    const interval = setInterval(() => {
      scale.value = withSequence(
        withTiming(1.3, { duration: 500 }),
        withTiming(1, { duration: 500 })
      )
    }, 1000)
    return () => clearInterval(interval)
  }, [])

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }))

  return (
    <Animated.View
      style={[
        { width: 12, height: 12, borderRadius: 6, backgroundColor: '#22c55e' },
        animatedStyle,
      ]}
    />
  )
}
```

## Platform-Specific Code

```tsx
import { Platform, StyleSheet } from 'react-native'

// Platform.select
const styles = StyleSheet.create({
  container: {
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
})

// Platform-specific files
// ProductCard.ios.tsx
// ProductCard.android.tsx
// ProductCard.tsx (default/web)

// Platform.OS checks
export function SafeAreaWrapper({ children }: { children: React.ReactNode }) {
  if (Platform.OS === 'ios') {
    return <SafeAreaView style={{ flex: 1 }}>{children}</SafeAreaView>
  }
  return <View style={{ flex: 1, paddingTop: StatusBar.currentHeight }}>{children}</View>
}
```

## State Management

### Zustand Store

```tsx
// stores/comparison-store.ts
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import AsyncStorage from '@react-native-async-storage/async-storage'

interface ComparisonState {
  selectedProducts: string[]
  objectives: Objective[]
  addProduct: (id: string) => void
  removeProduct: (id: string) => void
  clearProducts: () => void
  setObjectives: (objectives: Objective[]) => void
}

export const useComparisonStore = create<ComparisonState>()(
  persist(
    (set) => ({
      selectedProducts: [],
      objectives: [
        { name: 'price', sense: 'min', weight: 2 },
        { name: 'performance', sense: 'max', weight: 1 },
      ],

      addProduct: (id) =>
        set((state) => {
          if (state.selectedProducts.length >= 5) return state
          if (state.selectedProducts.includes(id)) return state
          return { selectedProducts: [...state.selectedProducts, id] }
        }),

      removeProduct: (id) =>
        set((state) => ({
          selectedProducts: state.selectedProducts.filter((p) => p !== id),
        })),

      clearProducts: () => set({ selectedProducts: [] }),

      setObjectives: (objectives) => set({ objectives }),
    }),
    {
      name: 'comparison-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
)
```

## Performance Optimization

### Memoization

```tsx
import { memo, useCallback, useMemo } from 'react'

// Memoized component
export const ProductCard = memo(function ProductCard({
  product,
  onPress,
}: {
  product: Product
  onPress: (id: string) => void
}) {
  const handlePress = useCallback(() => {
    onPress(product.id)
  }, [product.id, onPress])

  return (
    <Pressable onPress={handlePress}>
      {/* ... */}
    </Pressable>
  )
})

// Memoized list
export function ProductList({ products }: { products: Product[] }) {
  const handlePress = useCallback((id: string) => {
    router.push(`/product/${id}`)
  }, [])

  const sortedProducts = useMemo(
    () => [...products].sort((a, b) => a.minPrice - b.minPrice),
    [products]
  )

  const renderItem = useCallback(
    ({ item }: { item: Product }) => (
      <ProductCard product={item} onPress={handlePress} />
    ),
    [handlePress]
  )

  return (
    <FlatList
      data={sortedProducts}
      renderItem={renderItem}
      keyExtractor={(item) => item.id}
    />
  )
}
```

### FlashList for Large Lists

```tsx
import { FlashList } from '@shopify/flash-list'

export function LargeProductList({ products }: { products: Product[] }) {
  return (
    <FlashList
      data={products}
      renderItem={({ item }) => <ProductCard product={item} />}
      estimatedItemSize={200}
      numColumns={2}
    />
  )
}
```

## Error Boundaries

```tsx
import { Component, ErrorInfo, ReactNode } from 'react'
import { View, Text, Pressable } from 'react-native'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error?: Error
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught:', error, errorInfo)
  }

  resetError = () => {
    this.setState({ hasError: false, error: undefined })
  }

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback || (
          <View className="flex-1 items-center justify-center p-4">
            <Text className="text-xl font-bold mb-2">Oops!</Text>
            <Text className="text-gray-500 text-center mb-4">
              Une erreur est survenue
            </Text>
            <Pressable
              onPress={this.resetError}
              className="bg-pareto-600 px-6 py-3 rounded-lg"
            >
              <Text className="text-white font-semibold">Réessayer</Text>
            </Pressable>
          </View>
        )
      )
    }

    return this.props.children
  }
}
```

## Testing

```tsx
// __tests__/ProductCard.test.tsx
import { render, screen, fireEvent } from '@testing-library/react-native'
import { ProductCard } from '@/components/product/product-card'

const mockProduct = {
  id: '1',
  name: 'iPhone 15 Pro',
  brand: 'Apple',
  slug: 'iphone-15-pro',
  minPrice: 1199,
  maxPrice: 1499,
  imageUrl: 'https://example.com/image.jpg',
  offers: [],
}

describe('ProductCard', () => {
  it('renders product information', () => {
    render(<ProductCard product={mockProduct} />)

    expect(screen.getByText('iPhone 15 Pro')).toBeTruthy()
    expect(screen.getByText('Apple')).toBeTruthy()
    expect(screen.getByText('1 199,00 €')).toBeTruthy()
  })

  it('calls onPress when tapped', () => {
    const onPress = jest.fn()
    render(<ProductCard product={mockProduct} onPress={onPress} />)

    fireEvent.press(screen.getByText('iPhone 15 Pro'))

    expect(onPress).toHaveBeenCalledWith('1')
  })
})
```

---

**See Also**:
- [Expo SDK 53](./expo.md)
- [NativeWind](https://nativewind.dev/)
- [React Native Reanimated](https://docs.swmansion.com/react-native-reanimated/)
