# Docker 29 - Containerization

> **Container runtime with Docker Compose for local and production**

## Version Info

| Attribute | Value |
|-----------|-------|
| **Version** | 29.1.1 |
| **Release** | November 2025 |
| **Compose** | v2.32+ |

## Project Structure

```
.
├── docker-compose.yml          # Development compose
├── docker-compose.prod.yml     # Production overrides
├── apps/
│   ├── web/
│   │   └── Dockerfile
│   ├── api/
│   │   └── Dockerfile
│   └── workers/
│       └── Dockerfile
├── packages/                   # Shared packages (copied into images)
└── .env.example
```

## Docker Compose - Development

```yaml
# docker-compose.yml
name: pareto

services:
  # PostgreSQL with TimescaleDB
  postgres:
    image: timescale/timescaledb:latest-pg18
    container_name: pareto-postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-pareto}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-pareto}
      POSTGRES_DB: ${POSTGRES_DB:-pareto}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pareto"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - pareto-network

  # Redis with JSON/Search modules
  redis:
    image: redis/redis-stack:latest
    container_name: pareto-redis
    ports:
      - "6379:6379"
      - "8001:8001"  # RedisInsight UI
    volumes:
      - redis_data:/data
    environment:
      - REDIS_ARGS=--appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - pareto-network

  # Go API
  api:
    build:
      context: ./apps/api
      dockerfile: Dockerfile
      target: development
    container_name: pareto-api
    environment:
      GO_ENV: development
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: ${POSTGRES_USER:-pareto}
      DB_PASSWORD: ${POSTGRES_PASSWORD:-pareto}
      DB_NAME: ${POSTGRES_DB:-pareto}
      REDIS_ADDR: redis:6379
    ports:
      - "8080:8080"
    volumes:
      - ./apps/api:/app
      - go_modules:/go/pkg/mod
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - pareto-network

  # Python Workers (Celery)
  workers:
    build:
      context: ./apps/workers
      dockerfile: Dockerfile
      target: development
    container_name: pareto-workers
    environment:
      CELERY_BROKER_URL: redis://redis:6379/0
      CELERY_RESULT_BACKEND: redis://redis:6379/0
      DB_URL: postgresql://pareto:pareto@postgres:5432/pareto
    volumes:
      - ./apps/workers:/app
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - pareto-network
    command: celery -A workers worker -l INFO -Q scraper,normalizer,pareto

  # Celery Beat (Scheduler)
  scheduler:
    build:
      context: ./apps/workers
      dockerfile: Dockerfile
      target: development
    container_name: pareto-scheduler
    environment:
      CELERY_BROKER_URL: redis://redis:6379/0
      CELERY_RESULT_BACKEND: redis://redis:6379/0
    volumes:
      - ./apps/workers:/app
    depends_on:
      - workers
    networks:
      - pareto-network
    command: celery -A workers beat -l INFO

  # Next.js Frontend
  web:
    build:
      context: ./apps/web
      dockerfile: Dockerfile
      target: development
    container_name: pareto-web
    environment:
      NODE_ENV: development
      NEXT_PUBLIC_API_URL: http://localhost:8080
    ports:
      - "3000:3000"
    volumes:
      - ./apps/web:/app
      - ./packages:/packages:ro
      - web_node_modules:/app/node_modules
    depends_on:
      - api
    networks:
      - pareto-network

networks:
  pareto-network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
  go_modules:
  web_node_modules:
```

## Dockerfiles

### Go API

```dockerfile
# apps/api/Dockerfile
# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git ca-certificates

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /api ./cmd/api

# Development stage (with hot reload)
FROM golang:1.24-alpine AS development

WORKDIR /app

RUN go install github.com/air-verse/air@latest

COPY go.mod go.sum ./
RUN go mod download

EXPOSE 8080

CMD ["air", "-c", ".air.toml"]

# Production stage
FROM alpine:3.21 AS production

RUN apk --no-cache add ca-certificates wget

WORKDIR /app

COPY --from=builder /api .

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:8080/health || exit 1

CMD ["./api"]
```

### Python Workers

```dockerfile
# apps/workers/Dockerfile
FROM python:3.14-slim AS base

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY pyproject.toml ./
RUN pip install --no-cache-dir -e .

# Development stage
FROM base AS development

# Install dev dependencies
RUN pip install --no-cache-dir pytest pytest-cov black ruff

COPY . .

CMD ["celery", "-A", "workers", "worker", "-l", "INFO"]

# Production stage
FROM base AS production

COPY . .

# Create non-root user
RUN useradd -m -r appuser && chown -R appuser:appuser /app
USER appuser

CMD ["celery", "-A", "workers", "worker", "-l", "INFO", "-c", "4"]
```

### Next.js Frontend

```dockerfile
# apps/web/Dockerfile
FROM node:24-alpine AS base

RUN corepack enable pnpm

WORKDIR /app

# Dependencies stage
FROM base AS deps

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Development stage
FROM base AS development

COPY --from=deps /app/node_modules ./node_modules
COPY . .

EXPOSE 3000

CMD ["pnpm", "dev"]

# Builder stage
FROM base AS builder

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1

RUN pnpm build

# Production stage
FROM base AS production

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -q --spider http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]
```

## Production Compose

```yaml
# docker-compose.prod.yml
name: pareto-prod

services:
  api:
    build:
      context: ./apps/api
      dockerfile: Dockerfile
      target: production
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    environment:
      GO_ENV: production
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  workers:
    build:
      context: ./apps/workers
      dockerfile: Dockerfile
      target: production
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2'
          memory: 1G
    environment:
      CELERY_CONCURRENCY: 4

  web:
    build:
      context: ./apps/web
      dockerfile: Dockerfile
      target: production
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.5'
          memory: 256M

  # Traefik reverse proxy (for Dokploy)
  traefik:
    image: traefik:v3.2
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik_letsencrypt:/letsencrypt
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(`traefik.${DOMAIN}`)"
      - "traefik.http.routers.dashboard.service=api@internal"
      - "traefik.http.routers.dashboard.middlewares=auth"
      - "traefik.http.middlewares.auth.basicauth.users=${TRAEFIK_AUTH}"

volumes:
  traefik_letsencrypt:
```

## Multi-Stage Build Patterns

### Shared Packages in Monorepo

```dockerfile
# apps/web/Dockerfile
FROM node:24-alpine AS base

RUN corepack enable pnpm

WORKDIR /app

# Copy monorepo package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/api-client/package.json ./packages/api-client/
COPY packages/types/package.json ./packages/types/
COPY packages/utils/package.json ./packages/utils/
COPY apps/web/package.json ./apps/web/

# Install all dependencies
RUN pnpm install --frozen-lockfile

# Copy source
COPY packages/ ./packages/
COPY apps/web/ ./apps/web/

WORKDIR /app/apps/web

# Build
RUN pnpm build

# ... production stage
```

## Docker Best Practices

### .dockerignore

```dockerignore
# .dockerignore
.git
.gitignore
.env*
!.env.example
*.md
!README.md
docker-compose*.yml
Dockerfile*
.docker/

# Node
node_modules
.next
.turbo
coverage
.nyc_output

# Go
*.exe
*.test
*.prof

# Python
__pycache__
*.pyc
.pytest_cache
.venv
*.egg-info
dist
build

# IDE
.vscode
.idea
*.swp
*.swo
```

### Health Checks

```dockerfile
# Go API health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:8080/health || exit 1

# Node.js health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -q --spider http://localhost:3000/api/health || exit 1

# Python/Celery health check (via inspect)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD celery -A workers inspect ping -d celery@$HOSTNAME || exit 1
```

### Security

```dockerfile
# Run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Read-only filesystem (where possible)
# docker-compose.yml
services:
  api:
    read_only: true
    tmpfs:
      - /tmp

# No new privileges
services:
  api:
    security_opt:
      - no-new-privileges:true
```

## Development Workflow

### Hot Reload Configuration

```toml
# apps/api/.air.toml
root = "."
tmp_dir = "tmp"

[build]
cmd = "go build -o ./tmp/api ./cmd/api"
bin = "./tmp/api"
include_ext = ["go", "tpl", "tmpl", "html"]
exclude_dir = ["assets", "tmp", "vendor"]
delay = 1000

[log]
time = false

[color]
main = "magenta"
watcher = "cyan"
build = "yellow"
runner = "green"
```

### VS Code Dev Containers

```json
// .devcontainer/devcontainer.json
{
  "name": "Pareto Dev",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "api",
  "workspaceFolder": "/app",
  "customizations": {
    "vscode": {
      "extensions": [
        "golang.go",
        "ms-python.python",
        "dbaeumer.vscode-eslint",
        "bradlc.vscode-tailwindcss"
      ]
    }
  },
  "forwardPorts": [3000, 8080, 5432, 6379]
}
```

## Commands

```bash
# Development
docker compose up -d                    # Start all services
docker compose up -d postgres redis     # Start only databases
docker compose logs -f api              # Follow API logs
docker compose exec api sh              # Shell into API container

# Build
docker compose build                    # Build all images
docker compose build --no-cache api     # Rebuild without cache
docker compose build --parallel         # Parallel build

# Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Cleanup
docker compose down                     # Stop and remove containers
docker compose down -v                  # Also remove volumes
docker system prune -a                  # Remove all unused resources

# Debug
docker compose ps                       # List containers
docker compose top                      # Show processes
docker stats                            # Resource usage
```

---

**See Also**:
- [Cloudflare](./cloudflare.md)
- [PostgreSQL](./postgresql.md)
- [Dokploy](https://dokploy.com/)
