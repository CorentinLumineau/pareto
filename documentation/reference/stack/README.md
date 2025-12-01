# Stack Documentation

> **Comprehensive documentation for all technologies in the Pareto Comparator stack**

## Stack Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PARETO COMPARATOR STACK                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                   │
│  │   FRONTEND   │  │    MOBILE    │  │   BACKEND    │                   │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤                   │
│  │ Next.js 16   │  │ Expo SDK 53  │  │ Go 1.24      │                   │
│  │ React 19.2   │  │ React Native │  │ Chi Router   │                   │
│  │ Tailwind 4.1 │  │ NativeWind   │  │ Python 3.14  │                   │
│  │ TanStack     │  │ Victory      │  │ Celery       │                   │
│  │ TypeScript   │  │              │  │ Pydantic     │                   │
│  └──────────────┘  └──────────────┘  └──────────────┘                   │
│          │                 │                 │                           │
│          └─────────────────┼─────────────────┘                           │
│                            │                                             │
│                    ┌───────┴───────┐                                     │
│                    │   DATABASE    │                                     │
│                    ├───────────────┤                                     │
│                    │ PostgreSQL 18 │                                     │
│                    │ TimescaleDB   │                                     │
│                    │ Redis 8.4     │                                     │
│                    └───────────────┘                                     │
│                            │                                             │
│                    ┌───────┴───────┐                                     │
│                    │ INFRASTRUCTURE│                                     │
│                    ├───────────────┤                                     │
│                    │ Docker 29     │                                     │
│                    │ Dokploy       │                                     │
│                    │ Cloudflare    │                                     │
│                    │ Node.js 24    │                                     │
│                    └───────────────┘                                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Documentation Index

| Category | Document | Description |
|----------|----------|-------------|
| **Backend** | [go.md](./go.md) | Go 1.24 with Chi router |
| **Backend** | [python.md](./python.md) | Python 3.14 with Celery workers |
| **Frontend** | [nextjs.md](./nextjs.md) | Next.js 16 with App Router |
| **Frontend** | [react.md](./react.md) | React 19.2 patterns |
| **Frontend** | [tailwind.md](./tailwind.md) | Tailwind CSS v4 |
| **Mobile** | [expo.md](./expo.md) | Expo SDK 53 |
| **Mobile** | [react-native.md](./react-native.md) | React Native 0.79 |
| **Database** | [postgresql.md](./postgresql.md) | PostgreSQL 18 + TimescaleDB |
| **Database** | [redis.md](./redis.md) | Redis 8.4 |
| **Infrastructure** | [docker.md](./docker.md) | Docker 29 + Compose |
| **Infrastructure** | [cloudflare.md](./cloudflare.md) | Cloudflare Tunnel + CDN |

## Version Matrix (December 2025)

| Technology | Version | Release Date | EOL |
|------------|---------|--------------|-----|
| Go | 1.24.10 | Feb 2025 | Feb 2026 |
| Python | 3.14.0 | Oct 2025 | Oct 2030 |
| Next.js | 16.0.3 | Oct 2025 | - |
| React | 19.2.0 | Oct 2025 | - |
| Tailwind CSS | 4.1.17 | Jan 2025 | - |
| Expo SDK | 53 | May 2025 | - |
| React Native | 0.79.0 | May 2025 | - |
| PostgreSQL | 18.1 | Nov 2025 | Nov 2030 |
| TimescaleDB | 2.23.0 | Oct 2025 | - |
| Redis | 8.4.0 | Nov 2025 | - |
| Docker | 29.1.1 | Nov 2025 | - |
| Node.js | 24.x LTS | Oct 2025 | Apr 2028 |
| TypeScript | 5.9+ | - | - |

## Shared Packages Architecture

```
packages/
├── @pareto/api-client/     # Shared API client
│   ├── client.ts           # Fetch wrapper
│   ├── hooks.ts            # TanStack Query hooks
│   └── types.ts            # API response types
│
├── @pareto/types/          # Shared TypeScript types
│   ├── product.ts          # Product, Offer, Price
│   ├── comparison.ts       # ParetoResult, Score
│   └── index.ts            # Re-exports
│
└── @pareto/utils/          # Shared utilities
    ├── format.ts           # formatPrice, formatDate
    ├── pareto.ts           # isParetoOptimal, sortByScore
    └── validation.ts       # Zod schemas
```

## Context7 Quick Reference

```yaml
# Fetch latest docs for any library
Next.js 16:     /vercel/next.js/v16.0.3
React 19:       /facebook/react/v19_2_0
Tailwind v4:    /websites/tailwindcss
TanStack Query: /tanstack/query/v5_84_1
Expo SDK 53:    /expo/expo
Go 1.24:        /golang/go/go1_24_6
```

## Key Design Decisions

### Why This Stack?

| Choice | Rationale |
|--------|-----------|
| **Go for API** | Performance, single binary, excellent concurrency |
| **Python for Workers** | Rich ecosystem (curl_cffi, paretoset, BeautifulSoup) |
| **Next.js 16** | Turbopack default, Cache Components, SEO-first |
| **Expo** | Cross-platform mobile with shared packages |
| **PostgreSQL 18** | 3x I/O improvements, UUIDv7, mature ecosystem |
| **Redis 8** | Unified OSS + Stack, built-in JSON, Query Engine |
| **Turborepo** | Monorepo caching, shared packages |

### Stack Synergies

```
Web + Mobile Code Sharing:
├── @pareto/api-client → Same API hooks
├── @pareto/types → Same TypeScript types
└── @pareto/utils → Same business logic

Go + Python Hybrid:
├── Go → Fast API, orchestration, low latency
├── Python → curl_cffi (anti-bot), paretoset (algorithm)
└── Redis → Pub/sub communication
```

---

**Last Updated**: December 2025
**Stack Version**: Pareto MVP v1.0
