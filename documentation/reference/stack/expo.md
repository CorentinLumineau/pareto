# Expo SDK 53 - Mobile Framework

> **Cross-platform mobile development with React Native**

## Version Info

| Attribute | Value |
|-----------|-------|
| **Version** | SDK 53 |
| **Release** | May 2025 |
| **React Native** | 0.79.0 |
| **Context7** | `/expo/expo` |

## Project Structure

```
apps/mobile/
├── app/                        # Expo Router
│   ├── _layout.tsx             # Root layout
│   ├── index.tsx               # Home screen
│   ├── (tabs)/                 # Tab navigation
│   │   ├── _layout.tsx         # Tab layout
│   │   ├── index.tsx           # Home tab
│   │   ├── categories.tsx      # Categories tab
│   │   ├── compare.tsx         # Compare tab
│   │   └── profile.tsx         # Profile tab
│   ├── product/
│   │   └── [slug].tsx          # Product detail
│   └── search.tsx              # Search screen
├── components/
│   ├── ui/                     # UI components
│   ├── product/                # Product components
│   └── comparison/             # Comparison components
├── lib/
│   ├── api.ts                  # API client
│   └── storage.ts              # AsyncStorage helpers
├── hooks/                      # Custom hooks
├── app.json                    # Expo config
├── metro.config.js             # Metro bundler config
├── tailwind.config.js          # NativeWind config
└── package.json
```

## Expo SDK 53 Features

### app.json Configuration

```json
{
  "expo": {
    "name": "Pareto",
    "slug": "pareto",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "automatic",
    "scheme": "pareto",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#22c55e"
    },
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "fr.pareto.app",
      "buildNumber": "1"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#22c55e"
      },
      "package": "fr.pareto.app",
      "versionCode": 1
    },
    "web": {
      "favicon": "./assets/favicon.png",
      "bundler": "metro"
    },
    "plugins": [
      "expo-router",
      [
        "expo-camera",
        {
          "cameraPermission": "Scanner des codes-barres"
        }
      ],
      [
        "expo-notifications",
        {
          "icon": "./assets/notification-icon.png"
        }
      ]
    ],
    "experiments": {
      "typedRoutes": true
    }
  }
}
```

### Metro Configuration

```javascript
// metro.config.js
const { getDefaultConfig } = require('expo/metro-config')
const { withNativeWind } = require('nativewind/metro')

const config = getDefaultConfig(__dirname)

// Monorepo support
config.watchFolders = [
  `${__dirname}/../../packages/api-client`,
  `${__dirname}/../../packages/types`,
  `${__dirname}/../../packages/utils`,
]

config.resolver.nodeModulesPaths = [
  `${__dirname}/node_modules`,
  `${__dirname}/../../node_modules`,
]

module.exports = withNativeWind(config, { input: './global.css' })
```

## Expo Router

### Root Layout

```tsx
// app/_layout.tsx
import { Stack } from 'expo-router'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { GestureHandlerRootView } from 'react-native-gesture-handler'
import { SafeAreaProvider } from 'react-native-safe-area-context'
import '../global.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,
    },
  },
})

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <Stack>
            <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
            <Stack.Screen
              name="product/[slug]"
              options={{
                headerTitle: '',
                headerBackTitle: 'Retour',
              }}
            />
            <Stack.Screen
              name="search"
              options={{
                presentation: 'modal',
                headerTitle: 'Rechercher',
              }}
            />
          </Stack>
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  )
}
```

### Tab Navigation

```tsx
// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router'
import { Home, Grid, Scale, User } from 'lucide-react-native'

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: '#22c55e',
        tabBarInactiveTintColor: '#9ca3af',
        headerShown: true,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Accueil',
          tabBarIcon: ({ color, size }) => <Home size={size} color={color} />,
        }}
      />
      <Tabs.Screen
        name="categories"
        options={{
          title: 'Catégories',
          tabBarIcon: ({ color, size }) => <Grid size={size} color={color} />,
        }}
      />
      <Tabs.Screen
        name="compare"
        options={{
          title: 'Comparer',
          tabBarIcon: ({ color, size }) => <Scale size={size} color={color} />,
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profil',
          tabBarIcon: ({ color, size }) => <User size={size} color={color} />,
        }}
      />
    </Tabs>
  )
}
```

### Dynamic Routes

```tsx
// app/product/[slug].tsx
import { useLocalSearchParams } from 'expo-router'
import { ScrollView, View, Text, Image, Pressable } from 'react-native'
import { useProduct, usePriceHistory } from '@/hooks/queries'
import { formatPrice } from '@pareto/utils'
import { PriceHistoryChart } from '@/components/product/price-history-chart'
import { OfferList } from '@/components/product/offer-list'

export default function ProductScreen() {
  const { slug } = useLocalSearchParams<{ slug: string }>()
  const { data: product, isLoading, error } = useProduct(slug)

  if (isLoading) return <ProductSkeleton />
  if (error || !product) return <ErrorView message="Produit non trouvé" />

  return (
    <ScrollView className="flex-1 bg-white">
      {/* Product Image */}
      <View className="aspect-square bg-gray-100">
        <Image
          source={{ uri: product.imageUrl }}
          className="w-full h-full"
          resizeMode="contain"
        />
      </View>

      {/* Product Info */}
      <View className="p-4 space-y-4">
        <View>
          <Text className="text-sm text-gray-500">{product.brand}</Text>
          <Text className="text-2xl font-bold">{product.name}</Text>
        </View>

        <View className="flex-row items-baseline space-x-2">
          <Text className="text-3xl font-bold text-green-600">
            {formatPrice(product.minPrice)}
          </Text>
          {product.maxPrice > product.minPrice && (
            <Text className="text-gray-400 line-through">
              {formatPrice(product.maxPrice)}
            </Text>
          )}
        </View>

        <Text className="text-sm text-gray-500">
          {product.offers.length} offres disponibles
        </Text>

        {/* Price History Chart */}
        <PriceHistoryChart productId={product.id} />

        {/* Offers */}
        <OfferList offers={product.offers} />
      </View>
    </ScrollView>
  )
}
```

## NativeWind Styling

### Configuration

```javascript
// tailwind.config.js
const { hairlineWidth } = require('nativewind/theme')

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,jsx,ts,tsx}',
    './components/**/*.{js,jsx,ts,tsx}',
  ],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      colors: {
        pareto: {
          50: '#f0fdf4',
          100: '#dcfce7',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
        },
        amazon: '#ff9900',
        fnac: '#e5a100',
        darty: '#c30a1c',
        boulanger: '#0066cc',
        cdiscount: '#00a0e3',
      },
      borderWidth: {
        hairline: hairlineWidth(),
      },
    },
  },
  plugins: [],
}
```

### Global Styles

```css
/* global.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom utilities for mobile */
@layer utilities {
  .safe-area-top {
    padding-top: env(safe-area-inset-top);
  }

  .safe-area-bottom {
    padding-bottom: env(safe-area-inset-bottom);
  }
}
```

### Component Examples

```tsx
// components/product/product-card.tsx
import { View, Text, Image, Pressable } from 'react-native'
import { Link } from 'expo-router'
import { formatPrice } from '@pareto/utils'

export function ProductCard({ product }: { product: Product }) {
  return (
    <Link href={`/product/${product.slug}`} asChild>
      <Pressable className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden active:opacity-80">
        <View className="aspect-square bg-gray-50">
          <Image
            source={{ uri: product.imageUrl }}
            className="w-full h-full"
            resizeMode="contain"
          />
        </View>

        <View className="p-3 space-y-1">
          <Text className="text-xs text-gray-500">{product.brand}</Text>
          <Text className="font-semibold" numberOfLines={2}>
            {product.name}
          </Text>
          <Text className="text-lg font-bold text-pareto-600">
            {formatPrice(product.minPrice)}
          </Text>
          <Text className="text-xs text-gray-400">
            {product.offers.length} offres
          </Text>
        </View>
      </Pressable>
    </Link>
  )
}
```

## Data Fetching

### TanStack Query Hooks

```tsx
// hooks/queries.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'

export function useProducts(category?: string) {
  return useQuery({
    queryKey: ['products', { category }],
    queryFn: () => api.products.list({ category }),
    staleTime: 5 * 60 * 1000,
  })
}

export function useProduct(slug: string) {
  return useQuery({
    queryKey: ['product', slug],
    queryFn: () => api.products.getBySlug(slug),
    enabled: !!slug,
  })
}

export function usePriceHistory(productId: string) {
  return useQuery({
    queryKey: ['priceHistory', productId],
    queryFn: () => api.prices.history(productId),
    staleTime: 30 * 60 * 1000,
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

### API Client

```tsx
// lib/api.ts
import { API_URL } from '@/constants/config'
import type { Product, Offer, ParetoResult } from '@pareto/types'

class ApiClient {
  private baseUrl: string

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl
  }

  private async fetch<T>(path: string, options?: RequestInit): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
    })

    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`)
    }

    return response.json()
  }

  products = {
    list: (params?: { category?: string; limit?: number }) =>
      this.fetch<{ data: Product[]; total: number }>(
        `/products?${new URLSearchParams(params as Record<string, string>)}`
      ),
    getBySlug: (slug: string) =>
      this.fetch<Product>(`/products/${slug}`),
  }

  prices = {
    history: (productId: string) =>
      this.fetch<{ prices: { date: string; price: number }[] }>(
        `/products/${productId}/prices`
      ),
  }

  compare = (params: { product_ids: string[]; objectives: any[] }) =>
    this.fetch<{ results: ParetoResult[] }>('/compare', {
      method: 'POST',
      body: JSON.stringify(params),
    })
}

export const api = new ApiClient(API_URL)
```

## Charts with Victory Native

```tsx
// components/product/price-history-chart.tsx
import { View, Text } from 'react-native'
import {
  VictoryChart,
  VictoryLine,
  VictoryAxis,
  VictoryTheme,
  VictoryArea,
} from 'victory-native'
import { usePriceHistory } from '@/hooks/queries'
import { formatPrice, formatDate } from '@pareto/utils'

export function PriceHistoryChart({ productId }: { productId: string }) {
  const { data, isLoading } = usePriceHistory(productId)

  if (isLoading || !data) {
    return <View className="h-48 bg-gray-100 rounded-lg animate-pulse" />
  }

  const chartData = data.prices.map((p) => ({
    x: new Date(p.date),
    y: p.price,
  }))

  const minPrice = Math.min(...chartData.map((d) => d.y))
  const maxPrice = Math.max(...chartData.map((d) => d.y))

  return (
    <View className="bg-gray-50 rounded-lg p-4">
      <Text className="font-semibold mb-2">Historique des prix</Text>

      <VictoryChart
        theme={VictoryTheme.material}
        height={200}
        padding={{ top: 20, bottom: 40, left: 50, right: 20 }}
      >
        <VictoryAxis
          tickFormat={(t) => formatDate(t, 'MMM')}
          style={{
            tickLabels: { fontSize: 10 },
          }}
        />
        <VictoryAxis
          dependentAxis
          tickFormat={(t) => `${t}€`}
          domain={[minPrice * 0.95, maxPrice * 1.05]}
          style={{
            tickLabels: { fontSize: 10 },
          }}
        />
        <VictoryArea
          data={chartData}
          style={{
            data: {
              fill: '#dcfce7',
              stroke: '#22c55e',
              strokeWidth: 2,
            },
          }}
        />
      </VictoryChart>

      <View className="flex-row justify-between mt-2">
        <View>
          <Text className="text-xs text-gray-500">Min</Text>
          <Text className="font-semibold text-green-600">
            {formatPrice(minPrice)}
          </Text>
        </View>
        <View className="items-end">
          <Text className="text-xs text-gray-500">Max</Text>
          <Text className="font-semibold text-red-500">
            {formatPrice(maxPrice)}
          </Text>
        </View>
      </View>
    </View>
  )
}
```

## Barcode Scanner

```tsx
// components/scanner/barcode-scanner.tsx
import { useState, useEffect } from 'react'
import { View, Text, Pressable, StyleSheet } from 'react-native'
import { CameraView, useCameraPermissions } from 'expo-camera'
import { useRouter } from 'expo-router'

export function BarcodeScanner() {
  const router = useRouter()
  const [permission, requestPermission] = useCameraPermissions()
  const [scanned, setScanned] = useState(false)

  if (!permission) {
    return <View className="flex-1 bg-black" />
  }

  if (!permission.granted) {
    return (
      <View className="flex-1 items-center justify-center p-4">
        <Text className="text-center mb-4">
          Autorisez l'accès à la caméra pour scanner des codes-barres
        </Text>
        <Pressable
          onPress={requestPermission}
          className="bg-pareto-600 px-6 py-3 rounded-lg"
        >
          <Text className="text-white font-semibold">Autoriser</Text>
        </Pressable>
      </View>
    )
  }

  const handleBarCodeScanned = async ({
    type,
    data,
  }: {
    type: string
    data: string
  }) => {
    if (scanned) return
    setScanned(true)

    // Search for product by barcode
    try {
      const response = await fetch(`${API_URL}/products/barcode/${data}`)
      if (response.ok) {
        const product = await response.json()
        router.push(`/product/${product.slug}`)
      } else {
        alert('Produit non trouvé')
        setScanned(false)
      }
    } catch {
      alert('Erreur de recherche')
      setScanned(false)
    }
  }

  return (
    <View className="flex-1">
      <CameraView
        style={StyleSheet.absoluteFillObject}
        facing="back"
        barcodeScannerSettings={{
          barcodeTypes: ['ean13', 'ean8', 'upc_a', 'upc_e'],
        }}
        onBarcodeScanned={handleBarCodeScanned}
      />

      {/* Overlay */}
      <View className="flex-1 items-center justify-center">
        <View className="w-64 h-64 border-2 border-white rounded-lg" />
        <Text className="text-white mt-4">
          Placez le code-barres dans le cadre
        </Text>
      </View>
    </View>
  )
}
```

## Push Notifications

```tsx
// lib/notifications.ts
import * as Notifications from 'expo-notifications'
import * as Device from 'expo-device'
import { Platform } from 'react-native'
import Constants from 'expo-constants'

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
})

export async function registerForPushNotifications() {
  if (!Device.isDevice) {
    console.log('Push notifications require a physical device')
    return null
  }

  const { status: existingStatus } = await Notifications.getPermissionsAsync()
  let finalStatus = existingStatus

  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync()
    finalStatus = status
  }

  if (finalStatus !== 'granted') {
    return null
  }

  const projectId = Constants.expoConfig?.extra?.eas?.projectId
  const token = await Notifications.getExpoPushTokenAsync({ projectId })

  if (Platform.OS === 'android') {
    Notifications.setNotificationChannelAsync('default', {
      name: 'default',
      importance: Notifications.AndroidImportance.MAX,
    })
  }

  return token.data
}

// hooks/use-notifications.ts
import { useEffect, useRef, useState } from 'react'
import * as Notifications from 'expo-notifications'
import { registerForPushNotifications } from '@/lib/notifications'

export function useNotifications() {
  const [expoPushToken, setExpoPushToken] = useState<string | null>(null)
  const notificationListener = useRef<Notifications.EventSubscription>()
  const responseListener = useRef<Notifications.EventSubscription>()

  useEffect(() => {
    registerForPushNotifications().then(setExpoPushToken)

    notificationListener.current =
      Notifications.addNotificationReceivedListener((notification) => {
        console.log('Notification received:', notification)
      })

    responseListener.current =
      Notifications.addNotificationResponseReceivedListener((response) => {
        const { productId } = response.notification.request.content.data
        if (productId) {
          // Navigate to product
        }
      })

    return () => {
      notificationListener.current?.remove()
      responseListener.current?.remove()
    }
  }, [])

  return { expoPushToken }
}
```

## Storage

```tsx
// lib/storage.ts
import AsyncStorage from '@react-native-async-storage/async-storage'

export const storage = {
  async get<T>(key: string): Promise<T | null> {
    try {
      const value = await AsyncStorage.getItem(key)
      return value ? JSON.parse(value) : null
    } catch {
      return null
    }
  },

  async set<T>(key: string, value: T): Promise<void> {
    try {
      await AsyncStorage.setItem(key, JSON.stringify(value))
    } catch (error) {
      console.error('Storage set error:', error)
    }
  },

  async remove(key: string): Promise<void> {
    try {
      await AsyncStorage.removeItem(key)
    } catch (error) {
      console.error('Storage remove error:', error)
    }
  },

  async clear(): Promise<void> {
    try {
      await AsyncStorage.clear()
    } catch (error) {
      console.error('Storage clear error:', error)
    }
  },
}

// Comparison history
export const comparisonStorage = {
  KEY: 'comparison_history',

  async getHistory(): Promise<string[][]> {
    return (await storage.get<string[][]>(this.KEY)) || []
  },

  async addComparison(productIds: string[]): Promise<void> {
    const history = await this.getHistory()
    const updated = [productIds, ...history.slice(0, 9)] // Keep last 10
    await storage.set(this.KEY, updated)
  },
}
```

## Commands

```bash
# Development
npx expo start              # Start dev server
npx expo start --ios        # iOS simulator
npx expo start --android    # Android emulator
npx expo start --web        # Web browser

# Build
eas build --platform ios    # Build iOS
eas build --platform android # Build Android
eas build --platform all    # Build both

# Submit to stores
eas submit --platform ios
eas submit --platform android

# Update (OTA)
eas update --branch production --message "Bug fix"
```

---

**See Also**:
- [React Native](./react-native.md)
- [NativeWind](https://nativewind.dev/)
- [Victory Native](https://commerce.nearform.com/open-source/victory-native/)
