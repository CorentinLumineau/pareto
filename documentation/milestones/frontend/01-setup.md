# Phase 01: Project Setup

> **Next.js 15, Tailwind CSS, shadcn/ui**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      01 - Project Setup                                ║
║  Initiative: Frontend Web                                      ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Setup the Next.js 15 project with all dependencies and configurations.

## Tasks

- [ ] Create Next.js 15 project
- [ ] Configure Tailwind CSS
- [ ] Install shadcn/ui components
- [ ] Setup TanStack Query
- [ ] Configure shared packages
- [ ] Setup development environment

## Project Creation

```bash
# Create Next.js project
cd apps
pnpm create next-app@latest web --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"

# Navigate to project
cd web

# Install dependencies
pnpm add @tanstack/react-query @tanstack/react-query-devtools
pnpm add recharts date-fns
pnpm add react-hook-form @hookform/resolvers zod
pnpm add lucide-react class-variance-authority clsx tailwind-merge

# Install shared packages
pnpm add @pareto/api-client @pareto/types @pareto/utils --workspace
```

## shadcn/ui Setup

```bash
# Initialize shadcn/ui
pnpm dlx shadcn@latest init

# Install components we'll need
pnpm dlx shadcn@latest add button card input select
pnpm dlx shadcn@latest add dropdown-menu navigation-menu
pnpm dlx shadcn@latest add table badge skeleton
pnpm dlx shadcn@latest add dialog sheet toast
pnpm dlx shadcn@latest add form label checkbox radio-group
pnpm dlx shadcn@latest add slider separator scroll-area
```

## Configuration Files

### next.config.ts

```typescript
// apps/web/next.config.ts
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
    transpilePackages: ['@pareto/api-client', '@pareto/types', '@pareto/utils'],
    images: {
        remotePatterns: [
            { hostname: 'images-eu.ssl-images-amazon.com' },
            { hostname: 'static.fnac-static.com' },
            { hostname: 'i.cdiscount.com' },
        ],
    },
    experimental: {
        optimizePackageImports: ['lucide-react', 'recharts'],
    },
}

export default nextConfig
```

### tailwind.config.ts

```typescript
// apps/web/tailwind.config.ts
import type { Config } from 'tailwindcss'

const config: Config = {
    darkMode: ['class'],
    content: [
        './src/**/*.{ts,tsx}',
        './components/**/*.{ts,tsx}',
    ],
    theme: {
        extend: {
            colors: {
                border: 'hsl(var(--border))',
                background: 'hsl(var(--background))',
                foreground: 'hsl(var(--foreground))',
                primary: {
                    DEFAULT: 'hsl(var(--primary))',
                    foreground: 'hsl(var(--primary-foreground))',
                },
                secondary: {
                    DEFAULT: 'hsl(var(--secondary))',
                    foreground: 'hsl(var(--secondary-foreground))',
                },
                muted: {
                    DEFAULT: 'hsl(var(--muted))',
                    foreground: 'hsl(var(--muted-foreground))',
                },
                accent: {
                    DEFAULT: 'hsl(var(--accent))',
                    foreground: 'hsl(var(--accent-foreground))',
                },
                destructive: {
                    DEFAULT: 'hsl(var(--destructive))',
                    foreground: 'hsl(var(--destructive-foreground))',
                },
                card: {
                    DEFAULT: 'hsl(var(--card))',
                    foreground: 'hsl(var(--card-foreground))',
                },
            },
            borderRadius: {
                lg: 'var(--radius)',
                md: 'calc(var(--radius) - 2px)',
                sm: 'calc(var(--radius) - 4px)',
            },
        },
    },
    plugins: [require('tailwindcss-animate')],
}

export default config
```

## TanStack Query Provider

```typescript
// apps/web/src/providers/query-provider.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function QueryProvider({ children }: { children: React.ReactNode }) {
    const [queryClient] = useState(
        () =>
            new QueryClient({
                defaultOptions: {
                    queries: {
                        staleTime: 60 * 1000, // 1 minute
                        gcTime: 5 * 60 * 1000, // 5 minutes
                    },
                },
            })
    )

    return (
        <QueryClientProvider client={queryClient}>
            {children}
            <ReactQueryDevtools initialIsOpen={false} />
        </QueryClientProvider>
    )
}
```

## Root Layout

```typescript
// apps/web/src/app/layout.tsx
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import { QueryProvider } from '@/providers/query-provider'
import { Header } from '@/components/layout/header'
import { Footer } from '@/components/layout/footer'
import '@/styles/globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
    title: {
        default: 'Pareto - Comparateur Smartphones',
        template: '%s | Pareto',
    },
    description: 'Trouvez le meilleur smartphone grâce à l\'optimisation Pareto',
    keywords: ['comparateur', 'smartphone', 'prix', 'france'],
}

export default function RootLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <html lang="fr">
            <body className={inter.className}>
                <QueryProvider>
                    <div className="flex min-h-screen flex-col">
                        <Header />
                        <main className="flex-1">{children}</main>
                        <Footer />
                    </div>
                </QueryProvider>
            </body>
        </html>
    )
}
```

## API Client Setup

```typescript
// apps/web/src/lib/api.ts
import { createApiClient } from '@pareto/api-client'

export const api = createApiClient({
    baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080',
})

// Server-side fetching
export async function fetchProducts(params?: {
    page?: number
    brand?: string
}) {
    return api.products.list(params)
}

export async function fetchProduct(id: string) {
    return api.products.get(id)
}
```

## Environment Variables

```bash
# apps/web/.env.local
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

## Package.json Scripts

```json
{
    "name": "@pareto/web",
    "version": "0.1.0",
    "private": true,
    "scripts": {
        "dev": "next dev",
        "build": "next build",
        "start": "next start",
        "lint": "next lint",
        "type-check": "tsc --noEmit"
    },
    "dependencies": {
        "@pareto/api-client": "workspace:*",
        "@pareto/types": "workspace:*",
        "@pareto/utils": "workspace:*",
        "@tanstack/react-query": "^5.0.0",
        "next": "15.0.0",
        "react": "^18.2.0",
        "react-dom": "^18.2.0",
        "recharts": "^2.10.0",
        "lucide-react": "^0.300.0"
    },
    "devDependencies": {
        "@types/node": "^20",
        "@types/react": "^18",
        "typescript": "^5",
        "tailwindcss": "^3.4.0",
        "postcss": "^8",
        "autoprefixer": "^10"
    }
}
```

## Deliverables

- [ ] Next.js 15 project created
- [ ] Tailwind CSS configured
- [ ] shadcn/ui components installed
- [ ] TanStack Query setup
- [ ] Shared packages integrated
- [ ] Development server running

---

**Next Phase**: [02-core-pages.md](./02-core-pages.md)
**Back to**: [Frontend README](./README.md)
