# Architecture Documentation v2

## Modular Monolith for MVP — YAGNI-First Design

---

## Why NOT Microservices for MVP

| Microservices Problem          | Impact on Solo Dev                          |
| ------------------------------ | ------------------------------------------- |
| 9 containers to deploy/monitor | Hours lost on ops instead of features       |
| Inter-service network calls    | Debugging nightmare, added latency          |
| Distributed transactions       | Complex saga patterns for simple operations |
| Multiple repos/packages        | Context switching overhead                  |
| Service discovery              | Infrastructure you don't need yet           |

**The Right Approach**: Start with a **Modular Monolith** — clean internal boundaries that CAN become microservices later, but deployed as 2-3 services maximum.

---

## Simplified Architecture (MVP)

```mermaid
flowchart TB
    subgraph External["External World"]
        Retailers[(Retailer Sites)]
        Users([Users/Browsers])
        Affiliates[(Affiliate Networks)]
    end

    subgraph Monolith["🏗️ MODULAR MONOLITH (Single Go Binary)"]
        direction TB

        subgraph API["API Layer"]
            Gateway[HTTP Router\nChi/Echo]
            Middleware[Auth + RateLimit\n+ CORS]
        end

        subgraph Modules["Domain Modules (Internal Packages)"]
            direction LR
            CatalogMod[📦 Catalog\nProducts, Prices\nCategories]
            ScraperMod[🔍 Scraper\nJobs, Retailers\nProxy Management]
            CompareMod[⚖️ Compare\nPareto, Rankings\nNormalization]
            AffiliateMod[💰 Affiliate\nLinks, Clicks\nCommissions]
            UserMod[👤 User\nAuth, Prefs\nAlerts]
        end

        subgraph Infra["Infrastructure Layer"]
            DB[(PostgreSQL\n+ TimescaleDB)]
            Cache[(Redis\nCache + Queue)]
        end

        API --> Modules
        Modules --> Infra
    end

    subgraph Workers["🐍 PYTHON WORKERS (Celery)"]
        Normalizer[Normalizer\nHTML Parsing\nData Extraction]
        ParetoCalc[Pareto Calculator\nparetoset library]
    end

    subgraph Frontend["🖥️ NEXT.JS FRONTEND"]
        SSR[SSR Pages]
        ClientUI[React Components]
    end

    Retailers -->|Scrape| ScraperMod
    ScraperMod -->|Raw HTML| Cache
    Cache -->|Jobs| Normalizer
    Normalizer -->|Structured Data| DB

    Users --> Frontend
    Frontend -->|API Calls| Gateway

    CompareMod <-->|Heavy Compute| ParetoCalc
    AffiliateMod --> Affiliates
```

---

## Service Count: 3 (Not 9)

| Service            | Language | Responsibility                                     | Why Separate?                                             |
| ------------------ | -------- | -------------------------------------------------- | --------------------------------------------------------- |
| **Monolith API**   | Go       | All business logic, API, scraping orchestration    | Single binary, fast, type-safe                            |
| **Python Workers** | Python   | HTML parsing, ML normalization, Pareto computation | Needs Python libraries (BeautifulSoup, paretoset, pandas) |
| **Frontend**       | Next.js  | SSR, React UI                                      | Different runtime, SSR requirements                       |

**Total Containers**: 5 (Monolith + Workers + Frontend + PostgreSQL + Redis)

---

## Module Boundaries (Internal to Monolith)

```mermaid
classDiagram
    direction LR

    class CatalogModule {
        +CreateProduct()
        +UpdatePrice()
        +GetProduct()
        +SearchProducts()
        +MatchProduct()
        ---
        ProductRepository
        PriceRepository
        CategoryRepository
    }

    class ScraperModule {
        +QueueScrapeJob()
        +GetJobStatus()
        +ProcessResult()
        ---
        JobQueue
        RetailerRegistry
        ProxyPool
    }

    class CompareModule {
        +GetParetoFrontier()
        +RankProducts()
        +NormalizeScores()
        ---
        ParetoService
        NormalizationService
    }

    class AffiliateModule {
        +GenerateLink()
        +TrackClick()
        +GetCommissions()
        ---
        LinkGenerator
        ClickTracker
    }

    class UserModule {
        +Register()
        +Login()
        +SetAlert()
        +GetPreferences()
        ---
        AuthService
        AlertService
    }

    ScraperModule --> CatalogModule : normalized data
    CompareModule --> CatalogModule : product queries
    AffiliateModule --> CatalogModule : product lookups
    UserModule --> CatalogModule : saved products
    UserModule --> CompareModule : comparison prefs
```

---

## Directory Structure (Go Monolith)

```
comparateur/
├── cmd/
│   └── server/
│       └── main.go                 # Entry point
├── internal/
│   ├── catalog/                    # 📦 Catalog Module
│   │   ├── domain/
│   │   │   ├── product.go          # Entity
│   │   │   ├── price.go            # Entity
│   │   │   └── category.go         # Entity
│   │   ├── repository/
│   │   │   ├── interface.go        # Port (interface)
│   │   │   └── postgres.go         # Adapter (implementation)
│   │   ├── service/
│   │   │   └── catalog.go          # Use cases
│   │   └── handler/
│   │       └── http.go             # HTTP handlers
│   │
│   ├── scraper/                    # 🔍 Scraper Module
│   │   ├── domain/
│   │   │   ├── job.go
│   │   │   └── retailer.go
│   │   ├── adapters/
│   │   │   ├── amazon.go           # Retailer-specific
│   │   │   ├── fnac.go
│   │   │   └── cdiscount.go
│   │   ├── service/
│   │   │   ├── orchestrator.go
│   │   │   └── proxy.go
│   │   └── handler/
│   │       └── http.go
│   │
│   ├── compare/                    # ⚖️ Compare Module
│   │   ├── domain/
│   │   │   └── comparison.go
│   │   ├── service/
│   │   │   ├── pareto.go           # Delegates heavy compute to Python
│   │   │   └── ranking.go
│   │   └── handler/
│   │       └── http.go
│   │
│   ├── affiliate/                  # 💰 Affiliate Module
│   │   ├── domain/
│   │   │   ├── link.go
│   │   │   └── click.go
│   │   ├── service/
│   │   │   └── tracking.go
│   │   └── handler/
│   │       └── http.go
│   │
│   ├── user/                       # 👤 User Module
│   │   ├── domain/
│   │   │   ├── user.go
│   │   │   └── alert.go
│   │   ├── service/
│   │   │   ├── auth.go
│   │   │   └── alerts.go
│   │   └── handler/
│   │       └── http.go
│   │
│   └── shared/                     # 🔧 Shared Infrastructure
│       ├── database/
│       │   └── postgres.go
│       ├── cache/
│       │   └── redis.go
│       ├── queue/
│       │   └── redis.go
│       └── config/
│           └── config.go
│
├── pkg/                            # Public packages (if needed)
│   └── httputil/
│       └── response.go
│
├── migrations/
│   └── 001_initial.sql
├── docker-compose.yml
├── Dockerfile
├── Makefile
└── go.mod
```

---

## Python Workers Structure

```
workers/
├── src/
│   ├── normalizer/
│   │   ├── __init__.py
│   │   ├── parser.py               # BeautifulSoup parsing
│   │   ├── extractors/
│   │   │   ├── amazon.py
│   │   │   ├── fnac.py
│   │   │   └── cdiscount.py
│   │   └── validator.py
│   │
│   ├── pareto/
│   │   ├── __init__.py
│   │   ├── calculator.py           # paretoset integration
│   │   └── normalizer.py           # z-score normalization
│   │
│   └── tasks/
│       ├── __init__.py
│       └── celery_app.py
│
├── tests/
├── requirements.txt
├── Dockerfile
└── pyproject.toml
```

---

## Communication Pattern (Simplified)

```mermaid
sequenceDiagram
    participant U as User Browser
    participant F as Next.js Frontend
    participant G as Go Monolith
    participant R as Redis
    participant P as Python Worker
    participant DB as PostgreSQL

    Note over U,DB: User Requests Comparison
    U->>F: Visit /compare/laptops
    F->>G: GET /api/products?category=laptops
    G->>DB: SELECT products WHERE category='laptops'
    DB-->>G: Products[]
    G->>R: Check cache: pareto:laptops

    alt Cache Hit
        R-->>G: Cached Pareto Result
    else Cache Miss
        G->>R: Queue pareto calculation job
        R->>P: Job: calculate pareto
        P->>P: paretoset computation
        P->>R: Store result + notify
        R-->>G: Pareto Result
        G->>R: Cache result (TTL: 1h)
    end

    G-->>F: {products, paretoFrontier}
    F-->>U: Render comparison page
```

---

## Data Flow (Scraping Pipeline)

```mermaid
flowchart LR
    subgraph Trigger["⏰ Trigger"]
        Cron[GitHub Actions\nCron Schedule]
        Manual[Manual API Call]
    end

    subgraph GoMonolith["Go Monolith"]
        Orchestrator[Scraper\nOrchestrator]
        ProxyPool[Proxy Pool\nManager]
        JobQueue[Redis\nJob Queue]
    end

    subgraph PythonWorkers["Python Workers"]
        Fetcher[curl_cffi\nFetcher]
        Parser[BeautifulSoup\nParser]
        Validator[Pydantic\nValidator]
    end

    subgraph Storage["Storage"]
        Redis[(Redis\nRaw HTML Cache)]
        Postgres[(PostgreSQL\nProducts & Prices)]
    end

    Cron --> Orchestrator
    Manual --> Orchestrator
    Orchestrator --> ProxyPool
    Orchestrator --> JobQueue
    JobQueue --> Fetcher
    Fetcher --> Redis
    Redis --> Parser
    Parser --> Validator
    Validator --> Postgres

    ProxyPool -.->|Proxy URL| Fetcher
```

---

## When to Split into Microservices

**Don't split until you have ALL of these:**

| Trigger                | Threshold                                      | Action                               |
| ---------------------- | ---------------------------------------------- | ------------------------------------ |
| Team size              | >3 developers                                  | Consider splitting by team ownership |
| Deploy frequency       | Different modules need different deploy cycles | Split the bottleneck                 |
| Scale requirements     | One module needs 10x more resources            | Extract to scale independently       |
| Revenue validation     | >€5k MRR                                       | Business validated, invest in infra  |
| Performance bottleneck | Profiling shows clear module boundary          | Extract hot path                     |

**Until then**: Keep the monolith, enjoy simple deployments, fast debugging, and single-process transactions.

---

## Database Schema (Single PostgreSQL)

```mermaid
erDiagram
    PRODUCTS ||--o{ PRICES : has
    PRODUCTS ||--o{ PRODUCT_ATTRIBUTES : has
    PRODUCTS }o--|| CATEGORIES : belongs_to
    PRODUCTS }o--|| BRANDS : has

    RETAILERS ||--o{ PRICES : offers
    RETAILERS ||--o{ SCRAPE_JOBS : targets

    USERS ||--o{ ALERTS : creates
    USERS ||--o{ SAVED_PRODUCTS : saves
    ALERTS }o--|| PRODUCTS : monitors

    CLICKS ||--|| PRICES : tracks
    CLICKS }o--|| USERS : optional

    PRODUCTS {
        uuid id PK
        string slug UK
        string name
        string gtin
        uuid category_id FK
        uuid brand_id FK
        jsonb attributes
        timestamp created_at
        timestamp updated_at
    }

    PRICES {
        uuid id PK
        uuid product_id FK
        uuid retailer_id FK
        decimal price
        decimal shipping
        boolean in_stock
        string affiliate_url
        timestamp scraped_at
    }

    RETAILERS {
        uuid id PK
        string name UK
        string slug UK
        string scraper_type
        jsonb config
        boolean active
    }

    CATEGORIES {
        uuid id PK
        string name
        string slug UK
        uuid parent_id FK
        jsonb attribute_schema
    }

    USERS {
        uuid id PK
        string email UK
        string password_hash
        jsonb preferences
        timestamp created_at
    }

    ALERTS {
        uuid id PK
        uuid user_id FK
        uuid product_id FK
        decimal target_price
        boolean active
        timestamp triggered_at
    }

    CLICKS {
        uuid id PK
        uuid price_id FK
        uuid user_id FK
        string ip_hash
        timestamp clicked_at
        boolean converted
    }
```

---

## MVP Feature Scope (YAGNI Applied)

### ✅ MVP (Weeks 1-16)

| Feature                        | Included | Rationale         |
| ------------------------------ | -------- | ----------------- |
| Product scraping (6 retailers) | ✅       | Core value        |
| Price comparison table         | ✅       | Core value        |
| Pareto frontier visualization  | ✅       | Differentiator    |
| Affiliate link tracking        | ✅       | Revenue           |
| Basic search/filter            | ✅       | Usability         |
| Price history charts           | ✅       | User value        |
| SEO (Schema.org, SSR)          | ✅       | Acquisition       |
| Transparency page              | ✅       | Legal requirement |

### ❌ NOT in MVP (Add Later If Validated)

| Feature                | Excluded | Add When                  |
| ---------------------- | -------- | ------------------------- |
| User accounts          | ❌       | After 1000 MAU            |
| Price alerts           | ❌       | After user accounts       |
| Email notifications    | ❌       | After price alerts        |
| Mobile app             | ❌       | After €10k MRR            |
| Multi-language         | ❌       | After France validated    |
| Banking/SaaS verticals | ❌       | After hardware validated  |
| Admin dashboard        | ❌       | Use SQL directly          |
| A/B testing            | ❌       | After significant traffic |

---

## Revised Timeline (Simpler = Faster)

```mermaid
gantt
    title MVP Development Timeline (12 Weeks)
    dateFormat  YYYY-MM-DD

    section Foundation
    Legal & Domain Setup           :f1, 2024-01-01, 5d
    Dokploy + CI/CD               :f2, after f1, 4d
    Database Schema               :f3, after f2, 3d

    section Scraping
    Go Scraper Module (3 retailers) :s1, after f3, 10d
    Python Normalizer              :s2, after s1, 7d
    Add 3 More Retailers           :s3, after s2, 5d

    section Catalog & Compare
    Catalog Module + API           :c1, after s2, 7d
    Pareto Engine                  :c2, after c1, 5d
    Affiliate Links                :c3, after c2, 3d

    section Frontend
    Next.js Setup + Core Pages     :fe1, after c1, 7d
    Comparison UI + Charts         :fe2, after fe1, 7d
    SEO + Transparency Page        :fe3, after fe2, 5d

    section Launch
    Testing & Bug Fixes            :l1, after fe3, 5d
    Soft Launch                    :milestone, after l1, 0d
```

**Result**: 12 weeks instead of 16, with less complexity and clearer focus.

---

## Evolution Path (If Business Succeeds)

```mermaid
flowchart TB
    subgraph Phase1["Phase 1: MVP (Now)"]
        Mono[Modular Monolith\n+ Python Workers\n+ Next.js]
    end

    subgraph Phase2["Phase 2: Growth (€5k MRR)"]
        direction TB
        API2[Go API]
        Scraper2[Scraper Service]
        Frontend2[Next.js]
        Workers2[Python Workers]
    end

    subgraph Phase3["Phase 3: Scale (€20k MRR)"]
        direction TB
        Gateway3[API Gateway]
        Catalog3[Catalog Service]
        Compare3[Compare Service]
        Scraper3[Scraper Service]
        User3[User Service]
        Frontend3[Next.js]
    end

    Phase1 -->|"Validate business\nGet traction"| Phase2
    Phase2 -->|"Team grows\nScale needs"| Phase3

    style Phase1 fill:#90EE90
    style Phase2 fill:#FFE4B5
    style Phase3 fill:#ADD8E6
```

---

## Key Takeaways

1. **Start with 3 services max**: Go Monolith + Python Workers + Frontend
2. **Use internal packages** as module boundaries (not network boundaries)
3. **Same database** for all modules (PostgreSQL)
4. **Split only when forced** by team size, scale, or deploy needs
5. **YAGNI everything** — no user accounts, no alerts, no admin until validated
6. **12 weeks** is achievable with this simplified architecture

---

_"The best architecture is the one that lets you ship and iterate fastest."_
