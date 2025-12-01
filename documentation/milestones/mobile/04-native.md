# Phase 04: Native Features

> **Push notifications, deep linking, native integrations**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      04 - Native Features                              ║
║  Initiative: Mobile                                            ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     4 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Implement native features: push notifications for price alerts, deep linking, and share functionality.

## Tasks

- [ ] Push notification setup
- [ ] Price alert system
- [ ] Deep linking configuration
- [ ] Share functionality
- [ ] Settings screen

## Push Notifications

```typescript
// apps/mobile/lib/notifications.ts
import * as Notifications from 'expo-notifications'
import * as Device from 'expo-device'
import { Platform } from 'react-native'
import Constants from 'expo-constants'

// Configure notification handler
Notifications.setNotificationHandler({
    handleNotification: async () => ({
        shouldShowAlert: true,
        shouldPlaySound: true,
        shouldSetBadge: false,
    }),
})

export async function registerForPushNotifications(): Promise<string | null> {
    let token: string | null = null

    if (Platform.OS === 'android') {
        await Notifications.setNotificationChannelAsync('price-alerts', {
            name: 'Alertes prix',
            importance: Notifications.AndroidImportance.MAX,
            vibrationPattern: [0, 250, 250, 250],
            lightColor: '#3b82f6',
        })
    }

    if (Device.isDevice) {
        const { status: existingStatus } = await Notifications.getPermissionsAsync()
        let finalStatus = existingStatus

        if (existingStatus !== 'granted') {
            const { status } = await Notifications.requestPermissionsAsync()
            finalStatus = status
        }

        if (finalStatus !== 'granted') {
            console.log('Permission not granted for push notifications')
            return null
        }

        const projectId = Constants.expoConfig?.extra?.eas?.projectId
        token = (await Notifications.getExpoPushTokenAsync({ projectId })).data
    }

    return token
}

export async function schedulePriceAlert(
    productId: string,
    productTitle: string,
    targetPrice: number
) {
    await Notifications.scheduleNotificationAsync({
        content: {
            title: '📉 Alerte prix !',
            body: `${productTitle} est maintenant disponible sous ${targetPrice}€`,
            data: { productId, type: 'price_alert' },
        },
        trigger: null, // Will be triggered by server
    })
}

// Hook for handling notification responses
export function useNotificationObserver() {
    const router = useRouter()

    useEffect(() => {
        const subscription = Notifications.addNotificationResponseReceivedListener(
            (response) => {
                const data = response.notification.request.content.data
                if (data.productId) {
                    router.push(`/products/${data.productId}`)
                }
            }
        )

        return () => subscription.remove()
    }, [router])
}
```

## Price Alert System

```typescript
// apps/mobile/components/products/price-alert-button.tsx
import { useState } from 'react'
import { View, Text, Pressable, TextInput, Modal } from 'react-native'
import { Bell, BellOff, X } from 'lucide-react-native'
import { usePriceAlert, useCreatePriceAlert, useDeletePriceAlert } from '@pareto/api-client'
import { formatPrice } from '@pareto/utils'

interface PriceAlertButtonProps {
    productId: string
    currentPrice: number
}

export function PriceAlertButton({ productId, currentPrice }: PriceAlertButtonProps) {
    const [modalVisible, setModalVisible] = useState(false)
    const [targetPrice, setTargetPrice] = useState('')

    const { data: existingAlert } = usePriceAlert(productId)
    const createAlert = useCreatePriceAlert()
    const deleteAlert = useDeletePriceAlert()

    const handleCreate = async () => {
        const price = parseFloat(targetPrice)
        if (isNaN(price) || price <= 0) return

        await createAlert.mutateAsync({
            productId,
            targetPrice: price,
        })
        setModalVisible(false)
    }

    const handleDelete = async () => {
        if (existingAlert?.id) {
            await deleteAlert.mutateAsync(existingAlert.id)
        }
    }

    if (existingAlert) {
        return (
            <Pressable
                onPress={handleDelete}
                className="flex-row items-center bg-blue-100 px-4 py-2 rounded-lg"
            >
                <Bell size={18} color="#3b82f6" />
                <Text className="text-blue-600 ml-2">
                    Alerte à {formatPrice(existingAlert.targetPrice)}
                </Text>
            </Pressable>
        )
    }

    return (
        <>
            <Pressable
                onPress={() => setModalVisible(true)}
                className="flex-row items-center bg-gray-100 px-4 py-2 rounded-lg"
            >
                <BellOff size={18} color="#64748b" />
                <Text className="text-gray-600 ml-2">Créer une alerte</Text>
            </Pressable>

            <Modal
                visible={modalVisible}
                transparent
                animationType="slide"
                onRequestClose={() => setModalVisible(false)}
            >
                <View className="flex-1 justify-end bg-black/50">
                    <View className="bg-white rounded-t-3xl p-6">
                        <View className="flex-row justify-between items-center mb-6">
                            <Text className="text-lg font-semibold">
                                Alerte de prix
                            </Text>
                            <Pressable onPress={() => setModalVisible(false)}>
                                <X size={24} color="#64748b" />
                            </Pressable>
                        </View>

                        <Text className="text-gray-500 mb-2">
                            Prix actuel: {formatPrice(currentPrice)}
                        </Text>

                        <Text className="text-sm text-gray-500 mb-2">
                            M'alerter quand le prix descend sous:
                        </Text>

                        <View className="flex-row items-center border border-gray-300 rounded-lg px-4 mb-6">
                            <TextInput
                                value={targetPrice}
                                onChangeText={setTargetPrice}
                                keyboardType="numeric"
                                placeholder={String(Math.round(currentPrice * 0.9))}
                                className="flex-1 py-3 text-lg"
                            />
                            <Text className="text-gray-500">€</Text>
                        </View>

                        <Pressable
                            onPress={handleCreate}
                            className="bg-primary py-4 rounded-lg"
                        >
                            <Text className="text-white text-center font-semibold">
                                Créer l'alerte
                            </Text>
                        </Pressable>
                    </View>
                </View>
            </Modal>
        </>
    )
}
```

## Deep Linking

```typescript
// apps/mobile/app.config.ts
export default {
    expo: {
        scheme: 'pareto',
        // ... other config
    },
}

// Deep link format: pareto://products/123

// apps/mobile/app/_layout.tsx
import { useEffect } from 'react'
import * as Linking from 'expo-linking'
import { router } from 'expo-router'

export default function RootLayout() {
    useEffect(() => {
        // Handle deep links when app is already open
        const subscription = Linking.addEventListener('url', ({ url }) => {
            handleDeepLink(url)
        })

        // Handle initial URL (app opened via link)
        Linking.getInitialURL().then((url) => {
            if (url) handleDeepLink(url)
        })

        return () => subscription.remove()
    }, [])

    return (/* ... */)
}

function handleDeepLink(url: string) {
    const parsed = Linking.parse(url)

    // pareto://products/123
    if (parsed.path?.startsWith('products/')) {
        const productId = parsed.path.replace('products/', '')
        router.push(`/products/${productId}`)
    }

    // pareto://compare?ids=1,2,3
    if (parsed.path === 'compare' && parsed.queryParams?.ids) {
        router.push(`/compare?ids=${parsed.queryParams.ids}`)
    }
}
```

## Share Functionality

```typescript
// apps/mobile/components/products/share-button.tsx
import { Pressable, Share } from 'react-native'
import { Share as ShareIcon } from 'lucide-react-native'
import { Product } from '@pareto/types'
import { formatPrice } from '@pareto/utils'

interface ShareButtonProps {
    product: Product
}

export function ShareButton({ product }: ShareButtonProps) {
    const handleShare = async () => {
        const bestPrice = product.offers?.reduce(
            (min, o) => (o.price && o.price < min ? o.price : min),
            Infinity
        )

        try {
            await Share.share({
                title: product.title,
                message: `${product.title}\n\nMeilleur prix: ${formatPrice(bestPrice || 0)}\n\nComparez sur Pareto:\nhttps://pareto.fr/products/${product.id}`,
                url: `https://pareto.fr/products/${product.id}`,
            })
        } catch (error) {
            console.error('Share error:', error)
        }
    }

    return (
        <Pressable onPress={handleShare} className="p-2">
            <ShareIcon size={24} color="#3b82f6" />
        </Pressable>
    )
}
```

## Settings Screen

```typescript
// apps/mobile/app/(tabs)/settings.tsx
import { View, Text, Switch, Pressable, Linking, ScrollView } from 'react-native'
import { useState, useEffect } from 'react'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { Bell, Moon, Shield, Info, ExternalLink } from 'lucide-react-native'

export default function SettingsScreen() {
    const [notifications, setNotifications] = useState(true)
    const [darkMode, setDarkMode] = useState(false)

    useEffect(() => {
        loadSettings()
    }, [])

    const loadSettings = async () => {
        const stored = await AsyncStorage.getItem('settings')
        if (stored) {
            const settings = JSON.parse(stored)
            setNotifications(settings.notifications ?? true)
            setDarkMode(settings.darkMode ?? false)
        }
    }

    const saveSettings = async (key: string, value: boolean) => {
        const stored = await AsyncStorage.getItem('settings')
        const settings = stored ? JSON.parse(stored) : {}
        settings[key] = value
        await AsyncStorage.setItem('settings', JSON.stringify(settings))
    }

    return (
        <ScrollView className="flex-1 bg-gray-50">
            {/* Notifications */}
            <View className="bg-white mt-4">
                <View className="flex-row items-center justify-between p-4 border-b border-gray-100">
                    <View className="flex-row items-center">
                        <Bell size={20} color="#64748b" />
                        <Text className="ml-3">Notifications</Text>
                    </View>
                    <Switch
                        value={notifications}
                        onValueChange={(value) => {
                            setNotifications(value)
                            saveSettings('notifications', value)
                        }}
                        trackColor={{ true: '#3b82f6' }}
                    />
                </View>

                <View className="flex-row items-center justify-between p-4">
                    <View className="flex-row items-center">
                        <Moon size={20} color="#64748b" />
                        <Text className="ml-3">Mode sombre</Text>
                    </View>
                    <Switch
                        value={darkMode}
                        onValueChange={(value) => {
                            setDarkMode(value)
                            saveSettings('darkMode', value)
                        }}
                        trackColor={{ true: '#3b82f6' }}
                    />
                </View>
            </View>

            {/* Legal */}
            <Text className="px-4 py-2 text-sm text-gray-500 mt-4">
                LÉGAL
            </Text>
            <View className="bg-white">
                <Pressable
                    onPress={() => Linking.openURL('https://pareto.fr/mentions-legales')}
                    className="flex-row items-center justify-between p-4 border-b border-gray-100"
                >
                    <View className="flex-row items-center">
                        <Shield size={20} color="#64748b" />
                        <Text className="ml-3">Mentions légales</Text>
                    </View>
                    <ExternalLink size={16} color="#94a3b8" />
                </Pressable>

                <Pressable
                    onPress={() => Linking.openURL('https://pareto.fr/politique-confidentialite')}
                    className="flex-row items-center justify-between p-4"
                >
                    <View className="flex-row items-center">
                        <Info size={20} color="#64748b" />
                        <Text className="ml-3">Confidentialité</Text>
                    </View>
                    <ExternalLink size={16} color="#94a3b8" />
                </Pressable>
            </View>

            {/* App info */}
            <View className="p-4 items-center mt-8">
                <Text className="text-gray-500">Pareto v1.0.0</Text>
            </View>
        </ScrollView>
    )
}
```

## Deliverables

- [ ] Push notification setup
- [ ] Price alert creation UI
- [ ] Deep linking configuration
- [ ] Share functionality
- [ ] Settings screen

---

**Previous Phase**: [03-comparison.md](./03-comparison.md)
**Next Phase**: [05-store.md](./05-store.md)
**Back to**: [Mobile README](./README.md)
