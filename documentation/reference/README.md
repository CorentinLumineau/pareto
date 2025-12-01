# Reference - Stack Documentation & API Specs

> **Technical references, stack documentation, and external resources**

## Stack Reference (Latest Stable - Dec 2025)

### Backend

| Technology | Version | Documentation | Context7 ID |
|------------|---------|---------------|-------------|
| **Go** | 1.24.10 | [go.dev/doc](https://go.dev/doc/) | `/golang/go/go1_24_6` |
| **Chi Router** | 5.2.0 | [go-chi.io](https://go-chi.io/) | - |
| **Gin** (alt) | 1.10.0 | [gin-gonic.com](https://gin-gonic.com/) | `/gin-gonic/gin` |
| **Python** | 3.14.0 | [docs.python.org](https://docs.python.org/3.14/) | - |
| **Celery** | 5.5+ | [docs.celeryq.dev](https://docs.celeryq.dev/) | - |
| **Pydantic** | 2.11+ | [docs.pydantic.dev](https://docs.pydantic.dev/) | - |

### Frontend

| Technology | Version | Documentation | Context7 ID |
|------------|---------|---------------|-------------|
| **Next.js** | 16.0.3 | [nextjs.org/docs](https://nextjs.org/docs) | `/vercel/next.js/v16.0.3` |
| **React** | 19.2.0 | [react.dev](https://react.dev) | `/facebook/react/v19_2_0` |
| **Tailwind CSS** | 4.1.17 | [tailwindcss.com/docs](https://tailwindcss.com/docs) | `/websites/tailwindcss` |
| **TypeScript** | 5.9+ | [typescriptlang.org](https://typescriptlang.org/docs/) | - |
| **TanStack Query** | 5.84+ | [tanstack.com/query](https://tanstack.com/query/latest) | `/tanstack/query/v5_84_1` |

### Mobile

| Technology | Version | Documentation | Context7 ID |
|------------|---------|---------------|-------------|
| **Expo SDK** | 53 | [docs.expo.dev](https://docs.expo.dev/) | `/expo/expo` |
| **React Native** | 0.79.0 | [reactnative.dev](https://reactnative.dev/) | `/websites/reactnative_dev` |
| **NativeWind** | 4.x | [nativewind.dev](https://nativewind.dev/) | `/websites/nativewind_dev` |

### Database & Infrastructure

| Technology | Version | Documentation |
|------------|---------|---------------|
| **PostgreSQL** | 18.1 | [postgresql.org/docs](https://postgresql.org/docs/18/) |
| **TimescaleDB** | 2.23.0 | [docs.timescale.com](https://docs.timescale.com/) |
| **Redis** | 8.4.0 | [redis.io/docs](https://redis.io/docs/) |
| **Docker** | 29.1.1 | [docs.docker.com](https://docs.docker.com/) |
| **Node.js** | 24.x LTS | [nodejs.org/docs](https://nodejs.org/docs/latest-v24.x/api/) |

## Key Libraries

### Python Libraries

| Library | Purpose | Docs |
|---------|---------|------|
| **curl_cffi** | Anti-bot bypass (TLS fingerprinting) | [github.com/yifeikong/curl_cffi](https://github.com/yifeikong/curl_cffi) |
| **BeautifulSoup4** | HTML parsing | [crummy.com/software/BeautifulSoup](https://www.crummy.com/software/BeautifulSoup/bs4/doc/) |
| **paretoset** | Pareto frontier calculation | [github.com/tommyod/paretoset](https://github.com/tommyod/paretoset) |
| **lxml** | Fast XML/HTML parser | [lxml.de](https://lxml.de/) |

### Go Libraries

| Library | Purpose | Docs |
|---------|---------|------|
| **go-redis/v9** | Redis client | [redis.uptrace.dev](https://redis.uptrace.dev/) |
| **pgx/v5** | PostgreSQL driver | [github.com/jackc/pgx](https://github.com/jackc/pgx) |
| **fuzzysearch** | Entity matching | [github.com/lithammer/fuzzysearch](https://github.com/lithammer/fuzzysearch) |

### Frontend Libraries

| Library | Purpose | Docs |
|---------|---------|------|
| **Recharts** | Pareto visualization | [recharts.org](https://recharts.org/) |
| **TanStack Query** | Data fetching | [tanstack.com/query](https://tanstack.com/query/latest) |
| **Zod** | Schema validation | [zod.dev](https://zod.dev/) |
| **shadcn/ui** | UI components | [ui.shadcn.com](https://ui.shadcn.com/) |

## External APIs

### Affiliate Networks

| Network | Coverage | Documentation |
|---------|----------|---------------|
| **Amazon Associates** | Amazon.fr | [affiliate-program.amazon.fr](https://affiliate-program.amazon.fr/) |
| **Awin** | Fnac, Darty, Cdiscount | [wiki.awin.com](https://wiki.awin.com/) |
| **Effinity** | Boulanger, Rakuten | [effinity.fr](https://effinity.fr/) |

### Proxy Services

| Service | Type | Documentation |
|---------|------|---------------|
| **IPRoyal** | Residential FR | [iproyal.com/docs](https://iproyal.com/docs) |
| **Bright Data** | Alternative | [brightdata.com/docs](https://brightdata.com/docs) |

## French Market Resources

### E-Commerce Data

| Resource | Purpose |
|----------|---------|
| [fevad.com](https://www.fevad.com/) | French e-commerce federation stats |
| [idealo.fr](https://www.idealo.fr/) | Competitor - price comparison |
| [ledenicheur.fr](https://ledenicheur.fr/) | Competitor - price comparison |
| [lesnumeriques.com](https://www.lesnumeriques.com/) | Competitor - reviews/tests |

### Legal & Compliance

| Resource | Purpose |
|----------|---------|
| [legifrance.gouv.fr](https://www.legifrance.gouv.fr/) | French law database |
| [cnil.fr](https://www.cnil.fr/) | GDPR regulator (France) |
| [Decree 2017-1434](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000035720908) | Platform transparency law |

## API Specification

### Internal API (Go)

See: [api/openapi.yaml](./api/openapi.yaml)

**Base URL**: `http://localhost:8000` (dev) / `https://api.comparateur.fr` (prod)

### Example Requests

**List Products**
```bash
curl -X GET "http://localhost:8000/api/products?category=laptops&limit=20"
```

**Get Product**
```bash
curl -X GET "http://localhost:8000/api/products/macbook-pro-m3-14"
```

**Compare Products**
```bash
curl -X POST "http://localhost:8000/api/compare" \
  -H "Content-Type: application/json" \
  -d '{
    "product_ids": ["uuid1", "uuid2", "uuid3"],
    "objectives": [
      {"name": "price", "sense": "min", "weight": 2},
      {"name": "performance", "sense": "max", "weight": 1}
    ]
  }'
```

**Search**
```bash
curl -X GET "http://localhost:8000/api/search?q=macbook%20pro"
```

## Architecture Diagrams

### System Context
```
                    [Users]
                       |
               [Browser/Mobile]
                       |
              [Cloudflare CDN]
                       |
        [Pareto Comparator Platform]
                       |
    +--------+---------+---------+
    |        |         |         |
[Retailers] [Affiliates] [Proxies]
```

### Container Diagram
See: [Implementation README](../implementation/README.md)

### Database Schema
See: [database/schema.md](./database/schema.md)

---

## Files in this Section

- [api/](./api/) - OpenAPI specifications
- [database/](./database/) - Schema reference
- [specs/](./specs/) - Original specification documents
  - [blueprint.md](./specs/blueprint.md) - Strategic vision, market analysis
  - [architecture.md](./specs/architecture.md) - Technical architecture decisions
  - [scrapper-module.md](./specs/scrapper-module.md) - Scraping module specification
  - [normalizer-catalog.md](./specs/normalizer-catalog.md) - Data processing pipeline
  - [comparaison-catalog.md](./specs/comparaison-catalog.md) - Pareto and affiliate logic
  - [frontend.md](./specs/frontend.md) - Frontend specification
  - [infrastructure.md](./specs/infrastructure.md) - DevOps and deployment
- [glossary.md](./glossary.md) - Technical terms

**See Also**: [Implementation](../implementation/) for detailed specs
