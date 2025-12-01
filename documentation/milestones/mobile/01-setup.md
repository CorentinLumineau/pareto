# Phase 01: Project Setup

> **Expo, NativeWind, shared packages integration**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      01 - Project Setup                                ║
║  Initiative: Mobile                                            ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Setup Expo project with NativeWind styling and shared monorepo packages.

## Tasks

- [ ] Create Expo project
- [ ] Configure NativeWind
- [ ] Integrate shared packages
- [ ] Setup TanStack Query
- [ ] Configure Expo Router

## Project Creation

```bash
# Create Expo project with Expo Router template
cd apps
npx create-expo-app@latest mobile --template tabs

# Navigate to project
cd mobile

# Install NativeWind
pnpm add nativewind
pnpm add -D tailwindcss@^3.4.0

# Install dependencies
pnpm add @tanstack/react-query
pnpm add victory-native react-native-svg
pnpm add expo-linking expo-notifications expo-constants

# Install shared packages
pnpm add @pareto/api-client @pareto/types @pareto/utils --workspace
```

## Expo Configuration

```json
// apps/mobile/app.json
{
    "expo": {
        "name": "Pareto",
        "slug": "pareto",
        "version": "1.0.0",
        "orientation": "portrait",
        "icon": "./assets/images/icon.png",
        "scheme": "pareto",
        "userInterfaceStyle": "automatic",
        "splash": {
            "image": "./assets/images/splash.png",
            "resizeMode": "contain",
            "backgroundColor": "#ffffff"
        },
        "assetBundlePatterns": ["**/*"],
        "ios": {
            "supportsTablet": true,
            "bundleIdentifier": "fr.pareto.app",
            "infoPlist": {
                "NSCameraUsageDescription": "Pour scanner des codes-barres"
            }
        },
        "android": {
            "adaptiveIcon": {
                "foregroundImage": "./assets/images/adaptive-icon.png",
                "backgroundColor": "#ffffff"
            },
            "package": "fr.pareto.app"
        },
        "web": {
            "bundler": "metro",
            "output": "static"
        },
        "plugins": [
            "expo-router",
            [
                "expo-notifications",
                {
                    "icon": "./assets/images/notification-icon.png"
                }
            ]
        ],
        "experiments": {
            "typedRoutes": true
        }
    }
}
```

## NativeWind Configuration

```javascript
// apps/mobile/tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        "./app/**/*.{js,jsx,ts,tsx}",
        "./components/**/*.{js,jsx,ts,tsx}",
    ],
    presets: [require("nativewind/preset")],
    theme: {
        extend: {
            colors: {
                primary: {
                    DEFAULT: "#3b82f6",
                    foreground: "#ffffff",
                },
                secondary: {
                    DEFAULT: "#f1f5f9",
                    foreground: "#0f172a",
                },
                muted: {
                    DEFAULT: "#f1f5f9",
                    foreground: "#64748b",
                },
                destructive: {
                    DEFAULT: "#ef4444",
                    foreground: "#ffffff",
                },
            },
        },
    },
    plugins: [],
}

// apps/mobile/global.css
@tailwind base;
@tailwind components;
@tailwind utilities;

// apps/mobile/nativewind-env.d.ts
/// <reference types="nativewind/types" />
```

## Metro Configuration

```javascript
// apps/mobile/metro.config.js
const { getDefaultConfig } = require("expo/metro-config");
const { withNativeWind } = require("nativewind/metro");
const path = require("path");

const projectRoot = __dirname;
const monorepoRoot = path.resolve(projectRoot, "../..");

const config = getDefaultConfig(projectRoot);

// Watch monorepo packages
config.watchFolders = [monorepoRoot];

// Configure package resolution
config.resolver.nodeModulesPaths = [
    path.resolve(projectRoot, "node_modules"),
    path.resolve(monorepoRoot, "node_modules"),
];

// Add shared packages to extraNodeModules
config.resolver.extraNodeModules = {
    "@pareto/api-client": path.resolve(monorepoRoot, "packages/api-client"),
    "@pareto/types": path.resolve(monorepoRoot, "packages/types"),
    "@pareto/utils": path.resolve(monorepoRoot, "packages/utils"),
};

module.exports = withNativeWind(config, { input: "./global.css" });
```

## Root Layout

```typescript
// apps/mobile/app/_layout.tsx
import { Stack } from 'expo-router'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useState } from 'react'
import { StatusBar } from 'expo-status-bar'
import '../global.css'

export default function RootLayout() {
    const [queryClient] = useState(
        () =>
            new QueryClient({
                defaultOptions: {
                    queries: {
                        staleTime: 60 * 1000,
                        gcTime: 5 * 60 * 1000,
                    },
                },
            })
    )

    return (
        <QueryClientProvider client={queryClient}>
            <StatusBar style="auto" />
            <Stack>
                <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
                <Stack.Screen
                    name="products/[id]"
                    options={{
                        title: 'Détails du produit',
                        headerBackTitle: 'Retour',
                    }}
                />
                <Stack.Screen
                    name="search"
                    options={{
                        title: 'Recherche',
                        presentation: 'modal',
                    }}
                />
            </Stack>
        </QueryClientProvider>
    )
}
```

## Tab Navigation

```typescript
// apps/mobile/app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router'
import { Home, Search, GitCompare, Settings } from 'lucide-react-native'

export default function TabLayout() {
    return (
        <Tabs
            screenOptions={{
                tabBarActiveTintColor: '#3b82f6',
                tabBarInactiveTintColor: '#64748b',
                headerShown: true,
            }}
        >
            <Tabs.Screen
                name="index"
                options={{
                    title: 'Accueil',
                    tabBarIcon: ({ color, size }) => (
                        <Home color={color} size={size} />
                    ),
                }}
            />
            <Tabs.Screen
                name="products"
                options={{
                    title: 'Produits',
                    tabBarIcon: ({ color, size }) => (
                        <Search color={color} size={size} />
                    ),
                }}
            />
            <Tabs.Screen
                name="compare"
                options={{
                    title: 'Comparer',
                    tabBarIcon: ({ color, size }) => (
                        <GitCompare color={color} size={size} />
                    ),
                }}
            />
            <Tabs.Screen
                name="settings"
                options={{
                    title: 'Paramètres',
                    tabBarIcon: ({ color, size }) => (
                        <Settings color={color} size={size} />
                    ),
                }}
            />
        </Tabs>
    )
}
```

## API Client Setup

```typescript
// apps/mobile/lib/api.ts
import { createApiClient } from '@pareto/api-client'
import Constants from 'expo-constants'

const API_URL = Constants.expoConfig?.extra?.apiUrl || 'http://localhost:8080'

export const api = createApiClient({
    baseURL: API_URL,
})

// Re-export hooks for convenience
export {
    useProducts,
    useProduct,
    useComparison,
    useSearch,
} from '@pareto/api-client'
```

## Package.json

```json
{
    "name": "@pareto/mobile",
    "version": "1.0.0",
    "main": "expo-router/entry",
    "scripts": {
        "start": "expo start",
        "ios": "expo start --ios",
        "android": "expo start --android",
        "build:ios": "eas build --platform ios",
        "build:android": "eas build --platform android",
        "lint": "eslint .",
        "type-check": "tsc --noEmit"
    },
    "dependencies": {
        "@pareto/api-client": "workspace:*",
        "@pareto/types": "workspace:*",
        "@pareto/utils": "workspace:*",
        "@tanstack/react-query": "^5.0.0",
        "expo": "~52.0.0",
        "expo-constants": "~17.0.0",
        "expo-linking": "~7.0.0",
        "expo-notifications": "~0.29.0",
        "expo-router": "~4.0.0",
        "nativewind": "^4.0.0",
        "react": "18.3.1",
        "react-native": "0.76.0",
        "victory-native": "^41.0.0"
    },
    "devDependencies": {
        "@types/react": "~18.3.0",
        "tailwindcss": "^3.4.0",
        "typescript": "~5.3.0"
    }
}
```

## Deliverables

- [ ] Expo project created
- [ ] NativeWind configured
- [ ] Shared packages working
- [ ] TanStack Query setup
- [ ] Tab navigation working
- [ ] Development server running

---

**Next Phase**: [02-core-screens.md](./02-core-screens.md)
**Back to**: [Mobile README](./README.md)
