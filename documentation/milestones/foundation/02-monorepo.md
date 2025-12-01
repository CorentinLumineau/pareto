# Phase 02: Monorepo & Turborepo Setup

> **Configure Turborepo with pnpm for Go + Python + Next.js**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      02 - Monorepo Setup                                ║
║  Initiative: Foundation                                         ║
║  Status:     ⏳ ACTIVE                                          ║
║  Effort:     1 day                                              ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Create a Turborepo monorepo with:
- Go API (modular monolith with direct imports)
- Next.js frontend
- Python Celery workers
- Shared configurations
- Docker-based development

## Final Structure

```
pareto/
├── apps/
│   ├── api/                    # Go modular monolith
│   │   ├── cmd/api/main.go
│   │   ├── internal/
│   │   │   ├── catalog/       # Product module
│   │   │   ├── scraper/       # Scraping orchestration
│   │   │   ├── compare/       # Pareto engine
│   │   │   └── affiliate/     # Revenue tracking
│   │   ├── go.mod
│   │   └── Dockerfile
│   │
│   ├── web/                    # Next.js 15 frontend
│   │   ├── src/app/           # App Router
│   │   ├── package.json
│   │   └── Dockerfile
│   │
│   └── workers/                # Python Celery workers
│       ├── src/
│       │   ├── normalizer/    # HTML parsing
│       │   └── pareto/        # Pareto calculation
│       ├── pyproject.toml
│       └── Dockerfile
│
├── packages/
│   ├── eslint-config/          # Shared ESLint config
│   ├── typescript-config/      # Shared TS config
│   └── ui/                     # Shared UI (future)
│
├── docker/
│   └── docker-compose.yml
│
├── turbo.json
├── package.json
├── pnpm-workspace.yaml
└── Makefile
```

## Tasks

### 1. Initialize Root Project

```bash
mkdir pareto && cd pareto
pnpm init
pnpm add -D turbo
```

**package.json**:
```json
{
  "name": "pareto",
  "private": true,
  "scripts": {
    "dev": "turbo dev",
    "build": "turbo build",
    "lint": "turbo lint",
    "test": "turbo test"
  },
  "devDependencies": {
    "turbo": "^2.3.0"
  },
  "packageManager": "pnpm@9.14.2"
}
```

**pnpm-workspace.yaml**:
```yaml
packages:
  - "apps/*"
  - "packages/*"
```

**turbo.json**:
```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**", "bin/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {},
    "test": {}
  }
}
```

### 2. Go API Setup

**apps/api/cmd/api/main.go**:
```go
package main

import (
    "log"
    "github.com/gin-gonic/gin"
    "github.com/clumineau/pareto/apps/api/internal/catalog"
)

func main() {
    r := gin.Default()
    r.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })

    v1 := r.Group("/api/v1")
    catalog.RegisterRoutes(v1)

    log.Fatal(r.Run(":8080"))
}
```

### 3. Next.js Setup

```bash
cd apps
pnpm create next-app@latest web --typescript --tailwind --app --src-dir
cd web
pnpm add @tanstack/react-query @tanstack/react-table recharts zod
```

### 4. Python Workers Setup

**apps/workers/pyproject.toml**:
```toml
[project]
name = "pareto-workers"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "celery>=5.4.0",
    "redis>=5.2.0",
    "curl-cffi>=0.7.4",
    "beautifulsoup4>=4.12.3",
    "pydantic>=2.10.3",
    "paretoset>=1.2.3",
]
```

### 5. Docker Compose

**docker/docker-compose.yml**:
```yaml
services:
  postgres:
    image: timescale/timescaledb:2.17.0-pg17
    environment:
      POSTGRES_USER: pareto
      POSTGRES_PASSWORD: pareto_dev
      POSTGRES_DB: pareto
    ports:
      - "5432:5432"

  redis:
    image: redis:7.4.1-alpine
    ports:
      - "6379:6379"

  api:
    build: ../apps/api
    ports:
      - "8080:8080"
    depends_on: [postgres, redis]

  web:
    build: ../apps/web
    ports:
      - "3000:3000"

  workers:
    build: ../apps/workers
    depends_on: [redis, postgres]
```

### 6. Makefile

```makefile
.PHONY: dev build lint test docker-up docker-down

dev:
	pnpm dev

build:
	pnpm build

lint:
	pnpm lint

test:
	pnpm test

docker-up:
	docker compose -f docker/docker-compose.yml up -d

docker-down:
	docker compose -f docker/docker-compose.yml down

install:
	pnpm install
	cd apps/api && go mod download
	cd apps/workers && pip install -e ".[dev]"
```

## Checklist

- [ ] `pnpm install` works
- [ ] `pnpm dev` starts all services
- [ ] `pnpm build` builds all apps
- [ ] `make docker-up` starts containers
- [ ] API responds at localhost:8080/health
- [ ] Web loads at localhost:3000

---

**Previous Phase**: [01-infrastructure.md](./01-infrastructure.md)
**Next Phase**: [03-legal.md](./03-legal.md)
**Back to**: [Foundation README](./README.md)
