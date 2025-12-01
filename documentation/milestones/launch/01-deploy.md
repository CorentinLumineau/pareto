# Phase 01: Production Deploy

> **Docker, Dokploy, HTTPS configuration**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      01 - Production Deploy                            ║
║  Initiative: Launch                                            ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     3 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Deploy all services to production on local PC using Dokploy with Cloudflare Tunnel.

## Tasks

- [ ] Finalize Docker images
- [ ] Configure Dokploy project
- [ ] Setup Cloudflare Tunnel
- [ ] Configure domain routing
- [ ] Test production deployment

## Docker Compose (Production)

```yaml
# docker/docker-compose.prod.yml
version: '3.8'

services:
  # Go API
  api:
    build:
      context: ../apps/api
      dockerfile: Dockerfile
    environment:
      - DATABASE_URL=postgresql://pareto:${DB_PASSWORD}@postgres:5432/pareto
      - REDIS_URL=redis://redis:6379
      - INTERNAL_TOKEN=${INTERNAL_TOKEN}
      - GIN_MODE=release
    depends_on:
      - postgres
      - redis
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.pareto.fr`)"
      - "traefik.http.routers.api.entrypoints=websecure"
      - "traefik.http.routers.api.tls=true"
      - "traefik.http.services.api.loadbalancer.server.port=8080"

  # Next.js Web
  web:
    build:
      context: ../apps/web
      dockerfile: Dockerfile
    environment:
      - NEXT_PUBLIC_API_URL=https://api.pareto.fr
    depends_on:
      - api
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.web.rule=Host(`pareto.fr`) || Host(`www.pareto.fr`)"
      - "traefik.http.routers.web.entrypoints=websecure"
      - "traefik.http.routers.web.tls=true"
      - "traefik.http.services.web.loadbalancer.server.port=3000"

  # Python Workers
  workers:
    build:
      context: ../apps/workers
      dockerfile: Dockerfile
    environment:
      - REDIS_URL=redis://redis:6379
      - CATALOG_API_URL=http://api:8080
      - INTERNAL_TOKEN=${INTERNAL_TOKEN}
    depends_on:
      - redis
      - api
    command: celery -A src.celery_app worker --loglevel=info

  # PostgreSQL
  postgres:
    image: timescale/timescaledb:latest-pg17
    environment:
      - POSTGRES_USER=pareto
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=pareto
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pareto"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis
  redis:
    image: redis:7.4-alpine
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Traefik (Reverse Proxy)
  traefik:
    image: traefik:v3.0
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(`traefik.pareto.local`)"
      - "traefik.http.routers.dashboard.service=api@internal"

volumes:
  postgres_data:
  redis_data:
```

## Dockerfile - API

```dockerfile
# apps/api/Dockerfile
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Install dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /api ./cmd/api

# Production image
FROM alpine:3.19

RUN apk --no-cache add ca-certificates wget

WORKDIR /app

COPY --from=builder /api .
COPY --from=builder /app/internal/catalog/migrations ./migrations

EXPOSE 8080

CMD ["./api"]
```

## Dockerfile - Web

```dockerfile
# apps/web/Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy workspace files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages ./packages
COPY apps/web ./apps/web

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build
WORKDIR /app/apps/web
ENV NEXT_TELEMETRY_DISABLED 1
RUN pnpm build

# Production image
FROM node:20-alpine

WORKDIR /app

RUN corepack enable

COPY --from=builder /app/apps/web/.next/standalone ./
COPY --from=builder /app/apps/web/.next/static ./.next/static
COPY --from=builder /app/apps/web/public ./public

ENV NODE_ENV production
ENV PORT 3000

EXPOSE 3000

CMD ["node", "server.js"]
```

## Dockerfile - Workers

```dockerfile
# apps/workers/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY src ./src

ENV PYTHONPATH=/app

CMD ["celery", "-A", "src.celery_app", "worker", "--loglevel=info"]
```

## Cloudflare Tunnel Setup

```bash
# Install cloudflared
# https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/

# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create pareto

# Configure tunnel
cat > ~/.cloudflared/config.yml << EOF
tunnel: <TUNNEL_ID>
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: pareto.fr
    service: http://localhost:3000
  - hostname: www.pareto.fr
    service: http://localhost:3000
  - hostname: api.pareto.fr
    service: http://localhost:8080
  - service: http_status:404
EOF

# Run tunnel (or as systemd service)
cloudflared tunnel run pareto
```

## Dokploy Configuration

```yaml
# Dokploy project configuration
name: pareto
compose_file: docker/docker-compose.prod.yml

environment:
  DB_PASSWORD: "${DB_PASSWORD}"
  INTERNAL_TOKEN: "${INTERNAL_TOKEN}"

health_checks:
  - name: API Health
    url: http://api:8080/health
    interval: 30s
  - name: Web Health
    url: http://web:3000
    interval: 30s

backups:
  postgres:
    schedule: "0 3 * * *"  # Daily at 3 AM
    retention: 7
```

## Environment Variables

```bash
# .env.production
# Database
DB_PASSWORD=<generate-secure-password>

# Internal communication
INTERNAL_TOKEN=<generate-secure-token>

# Affiliate keys (get from networks)
AMAZON_ASSOCIATE_TAG=pareto-21
AWIN_AFFILIATE_ID=<from-awin>
AWIN_FNAC_MERCHANT_ID=<from-awin>
AWIN_DARTY_MERCHANT_ID=<from-awin>
AWIN_BOULANGER_MERCHANT_ID=<from-awin>
AWIN_LDLC_MERCHANT_ID=<from-awin>
EFFINITY_COMPTEUR_ID=<from-effinity>

# Analytics (optional at launch)
NEXT_PUBLIC_GA_ID=<google-analytics-id>
```

## Deployment Commands

```bash
# Build all images
docker compose -f docker/docker-compose.prod.yml build

# Start all services
docker compose -f docker/docker-compose.prod.yml up -d

# Check logs
docker compose -f docker/docker-compose.prod.yml logs -f

# Run migrations
docker compose -f docker/docker-compose.prod.yml exec api ./api migrate

# Scale workers
docker compose -f docker/docker-compose.prod.yml up -d --scale workers=2
```

## Deliverables

- [ ] All Dockerfiles finalized
- [ ] docker-compose.prod.yml working
- [ ] Cloudflare Tunnel configured
- [ ] Domain routing correct
- [ ] HTTPS working
- [ ] All services healthy

---

**Next Phase**: [02-monitoring.md](./02-monitoring.md)
**Back to**: [Launch README](./README.md)
