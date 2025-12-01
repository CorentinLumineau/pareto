# Mobile Initiative

> **Expo SDK 53 app for iOS and Android with shared packages**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                           MOBILE INITIATIVE                                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     ⏳ PENDING (10% pre-done)                                       ║
║  Effort:     3 weeks (15 days)                                               ║
║  Depends:    Catalog, Comparison, Affiliate                                  ║
║  Parallel:   Frontend Web                                                    ║
║  Unlocks:    Launch                                                          ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Objective

Build native iOS and Android apps using Expo, sharing code with the web frontend through monorepo packages.

**Already done**: Landing page exists in `apps/mobile/` with Expo SDK 53 + Expo Router v4.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       MOBILE APP                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Expo (React Native)                                           │
│   ├── Expo Router (file-based navigation)                       │
│   ├── Shared packages (@pareto/*)                              │
│   └── Native features (notifications, deep links)              │
│                                                                 │
│   Data Fetching:                                                │
│   └── @pareto/api-client (same as web!)                        │
│       └── TanStack Query for caching                           │
│                                                                 │
│   Styling:                                                      │
│   └── NativeWind (Tailwind for React Native)                   │
│                                                                 │
│   Charts:                                                       │
│   └── Victory Native (React Native charts)                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Expo SDK 53 | Cross-platform |
| Navigation | Expo Router v4 | File-based routing |
| Language | TypeScript 5.7 | Type safety |
| Data | TanStack Query v5 | Server state |
| Styling | NativeWind v4 | Tailwind for RN |
| Charts | Victory Native | Data visualization |

## Milestones

| # | Phase | Effort | Status | Description |
|---|-------|--------|--------|-------------|
| M1 | [Project Setup](./01-setup.md) | 2d | ✅ Done | Expo, NativeWind, shared packages |
| M2 | [Core Screens](./02-core-screens.md) | 5d | ⏳ Pending | Home, list, detail |
| M3 | [Comparison UI](./03-comparison.md) | 4d | ⏳ Pending | Pareto visualization |
| M4 | [Native Features](./04-native.md) | 2d | ⏳ Pending | Notifications, deep links |
| M5 | [Store Submission](./05-store.md) | 2d | ⏳ Pending | App Store, Play Store |

## Progress: 10%

```
M1 Project Setup   [██████████] 100% ✅
M2 Core Screens    [░░░░░░░░░░]   0%
M3 Comparison UI   [░░░░░░░░░░]   0%
M4 Native Features [░░░░░░░░░░]   0%
M5 Store Submit    [░░░░░░░░░░]   0%
```

## App Structure

```
apps/mobile/
├── app/                          # Expo Router
│   ├── _layout.tsx               # Root layout
│   ├── index.tsx                 # Home screen
│   ├── (tabs)/                   # Tab navigation
│   │   ├── _layout.tsx
│   │   ├── index.tsx             # Products tab
│   │   ├── compare.tsx           # Compare tab
│   │   └── settings.tsx          # Settings tab
│   ├── products/
│   │   └── [id].tsx              # Product detail
│   └── search.tsx                # Search screen
├── components/
│   ├── ui/                       # Base components
│   ├── products/                 # Product-specific
│   └── comparison/               # Comparison-specific
├── lib/
│   ├── api.ts                    # API client setup
│   └── utils.ts                  # Utilities
├── app.json                      # Expo config
├── tailwind.config.js            # NativeWind config
└── package.json
```

## Code Sharing Strategy

```
packages/
├── api-client/        # API client (shared web + mobile)
│   ├── src/
│   │   ├── client.ts      # Fetch wrapper
│   │   ├── hooks/         # TanStack Query hooks
│   │   │   ├── useProducts.ts
│   │   │   ├── useProduct.ts
│   │   │   └── useComparison.ts
│   │   └── index.ts
│   └── package.json
│
├── types/             # TypeScript types (shared)
│   ├── src/
│   │   ├── product.ts
│   │   ├── offer.ts
│   │   ├── comparison.ts
│   │   └── index.ts
│   └── package.json
│
└── utils/             # Utilities (shared)
    ├── src/
    │   ├── format.ts      # formatPrice, formatDate
    │   ├── pareto.ts      # Pareto helpers
    │   └── index.ts
    └── package.json
```

## Shared Code Usage

```typescript
// apps/mobile/app/(tabs)/index.tsx
import { useProducts } from '@pareto/api-client'
import { Product } from '@pareto/types'
import { formatPrice } from '@pareto/utils'
import { View, Text, FlatList, Pressable } from 'react-native'
import { Link } from 'expo-router'

export default function ProductsScreen() {
    const { data, isLoading } = useProducts()

    return (
        <FlatList
            data={data?.products}
            keyExtractor={(item) => item.id}
            renderItem={({ item }) => (
                <Link href={`/products/${item.id}`} asChild>
                    <Pressable className="p-4 border-b border-gray-200">
                        <Text className="font-semibold">{item.title}</Text>
                        <Text className="text-blue-600 font-bold">
                            {formatPrice(item.bestPrice || 0)}
                        </Text>
                    </Pressable>
                </Link>
            )}
        />
    )
}
```

## Platform Differences

| Feature | Web | Mobile |
|---------|-----|--------|
| Navigation | Next.js App Router | Expo Router |
| Styling | Tailwind CSS | NativeWind |
| Charts | Recharts | Victory Native |
| Links | `<Link>` | `expo-linking` |
| Storage | localStorage | AsyncStorage |

## Success Metrics

| Metric | Target |
|--------|--------|
| App Store rating | >4.0 |
| Startup time | <2s |
| Bundle size | <15MB |
| Crash rate | <1% |

## Deliverables

- [ ] Expo project setup
- [ ] Core screens (home, list, detail)
- [ ] Comparison with Pareto chart
- [ ] Push notifications
- [ ] Deep linking
- [ ] App Store submission
- [ ] Play Store submission

---

**Depends on**: [Catalog](../catalog/), [Comparison](../comparison/), [Affiliate](../affiliate/)
**Parallel with**: [Frontend Web](../frontend/)
**Unlocks**: [Launch](../launch/)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
