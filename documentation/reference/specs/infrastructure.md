# Infrastructure & DevOps Specification

## Dokploy Setup, CI/CD, Monitoring & Cloud Migration

---

## Overview

| Aspect         | MVP (Dokploy)               | Scale (Cloud)      |
| -------------- | --------------------------- | ------------------ |
| **Compute**    | Single VPS (8GB RAM)        | Kubernetes cluster |
| **Database**   | PostgreSQL container        | Managed PostgreSQL |
| **Cache**      | Redis container             | Managed Redis      |
| **CDN**        | Cloudflare (free)           | Cloudflare Pro     |
| **CI/CD**      | GitHub Actions              | GitHub Actions     |
| **Monitoring** | Uptime Kuma + basic metrics | Grafana Cloud      |

---

## Infrastructure Architecture

```mermaid
flowchart TB
    subgraph Internet["Internet"]
        Users([Users])
        SearchEngines([Search Engines])
    end

    subgraph Cloudflare["Cloudflare (CDN + DDoS)"]
        CF[Cloudflare Proxy]
    end

    subgraph VPS["Dokploy VPS (Hetzner/Scaleway)"]
        direction TB

        subgraph Traefik["Traefik (Reverse Proxy)"]
            SSL[Let's Encrypt SSL]
            Router[HTTP Router]
        end

        subgraph Containers["Docker Containers"]
            Frontend[Next.js\nPort 3000]
            Backend[Go Monolith\nPort 8000]
            Workers[Python Workers\nCelery]
        end

        subgraph Data["Data Layer"]
            Postgres[(PostgreSQL\n+ TimescaleDB)]
            Redis[(Redis)]
        end

        subgraph Monitoring["Monitoring"]
            Uptime[Uptime Kuma]
        end
    end

    Users --> CF
    SearchEngines --> CF
    CF --> SSL
    SSL --> Router
    Router --> Frontend
    Router --> Backend
    Backend --> Postgres
    Backend --> Redis
    Workers --> Redis
    Workers --> Postgres
```

---

## Milestones

### M0.2: Infrastructure Setup (3 days)

**Goal**: Dokploy running with basic services

**VPS Requirements**:

| Provider     | Plan        | Specs                      | Price      |
| ------------ | ----------- | -------------------------- | ---------- |
| **Hetzner**  | CPX31       | 4 vCPU, 8GB RAM, 160GB SSD | ~€15/month |
| **Scaleway** | DEV1-M      | 3 vCPU, 4GB RAM, 40GB SSD  | ~€12/month |
| **OVH**      | VPS Starter | 2 vCPU, 4GB RAM, 80GB SSD  | ~€7/month  |

**Recommended**: Hetzner CPX31 for best price/performance.

**Dokploy Installation**:

```bash
# SSH into VPS
ssh root@your-vps-ip

# Install Dokploy (one-line installer)
curl -sSL https://dokploy.com/install.sh | sh

# Access Dokploy dashboard
# https://your-vps-ip:3000
```

**Docker Compose** (`docker-compose.yml`):

```yaml
version: "3.8"

services:
  # ===================
  # FRONTEND
  # ===================
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    restart: unless-stopped
    environment:
      - NEXT_PUBLIC_API_URL=https://api.comparateur.fr
    networks:
      - dokploy-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(`comparateur.fr`) || Host(`www.comparateur.fr`)"
      - "traefik.http.routers.frontend.tls=true"
      - "traefik.http.routers.frontend.tls.certResolver=letsencrypt"
      - "traefik.http.services.frontend.loadbalancer.server.port=3000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ===================
  # BACKEND (Go Monolith)
  # ===================
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgres://comparateur:${DB_PASSWORD}@postgres:5432/comparateur?sslmode=disable
      - REDIS_URL=redis://redis:6379/0
      - PROXY_URL=${PROXY_URL}
      - ENVIRONMENT=production
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - dokploy-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backend.rule=Host(`api.comparateur.fr`)"
      - "traefik.http.routers.backend.tls=true"
      - "traefik.http.routers.backend.tls.certResolver=letsencrypt"
      - "traefik.http.services.backend.loadbalancer.server.port=8000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ===================
  # PYTHON WORKERS
  # ===================
  celery-worker:
    build:
      context: ./workers
      dockerfile: Dockerfile
    command: celery -A celery_app worker --loglevel=info --concurrency=2
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgres://comparateur:${DB_PASSWORD}@postgres:5432/comparateur?sslmode=disable
      - REDIS_URL=redis://redis:6379/0
      - PROXY_URL=${PROXY_URL}
    depends_on:
      - redis
      - postgres
    networks:
      - dokploy-network

  celery-beat:
    build:
      context: ./workers
      dockerfile: Dockerfile
    command: celery -A celery_app beat --loglevel=info
    restart: unless-stopped
    environment:
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - redis
    networks:
      - dokploy-network

  # ===================
  # DATABASES
  # ===================
  postgres:
    image: timescale/timescaledb:latest-pg15
    restart: unless-stopped
    environment:
      POSTGRES_USER: comparateur
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: comparateur
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - dokploy-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U comparateur"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - dokploy-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ===================
  # MONITORING
  # ===================
  uptime-kuma:
    image: louislam/uptime-kuma:1
    restart: unless-stopped
    volumes:
      - uptime_data:/app/data
    networks:
      - dokploy-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.uptime.rule=Host(`status.comparateur.fr`)"
      - "traefik.http.routers.uptime.tls=true"
      - "traefik.http.services.uptime.loadbalancer.server.port=3001"

volumes:
  postgres_data:
  redis_data:
  uptime_data:

networks:
  dokploy-network:
    external: true
```

**Environment Variables** (`.env.production`):

```bash
# Database
DB_PASSWORD=your_secure_password_here

# Proxy (for scraping)
PROXY_URL=http://user:pass@proxy.iproyal.com:12321

# Domain
DOMAIN=comparateur.fr

# Feature flags
ENABLE_SCRAPING=true
ENABLE_ALERTS=false  # Disable for MVP
```

**Deliverables**:

- [ ] VPS provisioned
- [ ] Dokploy installed and configured
- [ ] Docker Compose file complete
- [ ] All containers running
- [ ] SSL certificates issued

---

### M0.3: CI/CD Pipeline (2 days)

**Goal**: Automated testing and deployment

**GitHub Actions Workflow** (`.github/workflows/deploy.yml`):

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # ===================
  # TEST
  # ===================
  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: "1.22"

      - name: Run tests
        working-directory: ./backend
        run: |
          go mod download
          go test -v -race -coverprofile=coverage.out ./...

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./backend/coverage.out

  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
          cache-dependency-path: frontend/package-lock.json

      - name: Install and test
        working-directory: ./frontend
        run: |
          npm ci
          npm run lint
          npm run test

  test-workers:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install and test
        working-directory: ./workers
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov
          pytest --cov=src tests/

  # ===================
  # BUILD
  # ===================
  build:
    needs: [test-backend, test-frontend, test-workers]
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    permissions:
      contents: read
      packages: write

    strategy:
      matrix:
        service: [backend, frontend, workers]

    steps:
      - uses: actions/checkout@v4

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: ./${{ matrix.service }}
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-${{ matrix.service }}:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-${{ matrix.service }}:${{ github.sha }}

  # ===================
  # DEPLOY
  # ===================
  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - name: Deploy to Dokploy
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /opt/comparateur

            # Pull latest images
            docker compose pull

            # Rolling update
            docker compose up -d --no-deps --build backend
            docker compose up -d --no-deps --build frontend
            docker compose up -d --no-deps --build celery-worker

            # Cleanup old images
            docker image prune -f

            # Health check
            sleep 10
            curl -f http://localhost:8000/health || exit 1
            curl -f http://localhost:3000/api/health || exit 1

            echo "Deployment successful!"

  # ===================
  # NOTIFY
  # ===================
  notify:
    needs: deploy
    runs-on: ubuntu-latest
    if: always()

    steps:
      - name: Send notification
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          fields: repo,message,commit,author
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
        if: env.SLACK_WEBHOOK_URL != ''
```

**Scheduled Scraping** (`.github/workflows/scrape.yml`):

```yaml
name: Scheduled Scraping

on:
  schedule:
    # Run every 4 hours
    - cron: "0 */4 * * *"
  workflow_dispatch:
    inputs:
      retailer:
        description: "Specific retailer to scrape"
        required: false
        default: "all"

jobs:
  scrape:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        retailer: [amazon, fnac, cdiscount, darty, boulanger, ldlc]
      fail-fast: false

    steps:
      - name: Trigger scrape job
        run: |
          curl -X POST \
            -H "Authorization: Bearer ${{ secrets.API_TOKEN }}" \
            -H "Content-Type: application/json" \
            -d '{"retailer": "${{ matrix.retailer }}"}' \
            https://api.comparateur.fr/internal/scrape/trigger
```

**Deliverables**:

- [ ] Test workflow for all services
- [ ] Build workflow with multi-arch images
- [ ] Deploy workflow with rolling updates
- [ ] Scheduled scraping workflow
- [ ] Slack/Discord notifications

---

### M1.1-M1.4: Database Setup (3 days)

**Goal**: PostgreSQL + TimescaleDB with proper schema

**Init Script** (`init.sql`):

```sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For fuzzy search
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- ===================
-- CORE TABLES
-- ===================

CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    logo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    parent_id UUID REFERENCES categories(id),
    level INTEGER NOT NULL DEFAULT 0,
    attribute_schema JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE retailers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    website_url TEXT NOT NULL,
    logo_url TEXT,
    scraper_config JSONB DEFAULT '{}',
    affiliate_config JSONB DEFAULT '{}',
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(500) NOT NULL,
    name_normalized VARCHAR(500) NOT NULL,
    gtin VARCHAR(14),
    brand_id UUID REFERENCES brands(id),
    category_id UUID REFERENCES categories(id),
    image_url TEXT,
    attributes JSONB DEFAULT '{}',
    search_vector tsvector,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===================
-- PRICE HISTORY (TimescaleDB)
-- ===================

CREATE TABLE prices (
    id UUID DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    retailer_id UUID NOT NULL REFERENCES retailers(id),
    price DECIMAL(10,2) NOT NULL,
    shipping DECIMAL(6,2),
    in_stock BOOLEAN DEFAULT true,
    url TEXT NOT NULL,
    scraped_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, scraped_at)
);

-- Convert to hypertable for time-series optimization
SELECT create_hypertable('prices', 'scraped_at');

-- Compression policy (compress data older than 7 days)
ALTER TABLE prices SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'product_id, retailer_id'
);

SELECT add_compression_policy('prices', INTERVAL '7 days');

-- Retention policy (keep 1 year of data)
SELECT add_retention_policy('prices', INTERVAL '1 year');

-- ===================
-- USER & TRACKING
-- ===================

CREATE TABLE clicks (
    id VARCHAR(8) PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES products(id),
    retailer_id UUID NOT NULL REFERENCES retailers(id),
    ip_hash VARCHAR(16) NOT NULL,
    user_agent TEXT,
    referer TEXT,
    clicked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE scrape_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    retailer_id UUID NOT NULL REFERENCES retailers(id),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    urls_total INTEGER DEFAULT 0,
    urls_processed INTEGER DEFAULT 0,
    urls_failed INTEGER DEFAULT 0,
    error_message TEXT,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===================
-- INDEXES
-- ===================

-- Products
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_gtin ON products(gtin) WHERE gtin IS NOT NULL;
CREATE INDEX idx_products_search ON products USING GIN(search_vector);
CREATE INDEX idx_products_name_trgm ON products USING GIN(name_normalized gin_trgm_ops);

-- Prices
CREATE INDEX idx_prices_product_retailer ON prices(product_id, retailer_id, scraped_at DESC);
CREATE INDEX idx_prices_latest ON prices(product_id, scraped_at DESC);

-- Clicks
CREATE INDEX idx_clicks_product ON clicks(product_id);
CREATE INDEX idx_clicks_date ON clicks(clicked_at);

-- ===================
-- FUNCTIONS
-- ===================

-- Update search vector on product change
CREATE OR REPLACE FUNCTION update_product_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('french', COALESCE(NEW.name, '')), 'A') ||
        setweight(to_tsvector('french', COALESCE((
            SELECT name FROM brands WHERE id = NEW.brand_id
        ), '')), 'B');
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_search_vector_update
    BEFORE INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_product_search_vector();

-- Get latest price for a product
CREATE OR REPLACE FUNCTION get_latest_prices(p_product_id UUID)
RETURNS TABLE(
    retailer_id UUID,
    retailer_name VARCHAR,
    price DECIMAL,
    shipping DECIMAL,
    in_stock BOOLEAN,
    url TEXT,
    scraped_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (p.retailer_id)
        p.retailer_id,
        r.name,
        p.price,
        p.shipping,
        p.in_stock,
        p.url,
        p.scraped_at
    FROM prices p
    JOIN retailers r ON r.id = p.retailer_id
    WHERE p.product_id = p_product_id
    ORDER BY p.retailer_id, p.scraped_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ===================
-- MATERIALIZED VIEWS
-- ===================

-- Daily price aggregates
CREATE MATERIALIZED VIEW daily_price_stats AS
SELECT
    product_id,
    retailer_id,
    date_trunc('day', scraped_at) AS day,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price)::DECIMAL(10,2) AS avg_price
FROM prices
WHERE scraped_at > NOW() - INTERVAL '90 days'
GROUP BY product_id, retailer_id, date_trunc('day', scraped_at);

CREATE UNIQUE INDEX idx_daily_price_stats
ON daily_price_stats(product_id, retailer_id, day);

-- Refresh daily
-- (Schedule via pg_cron or external cron)
```

**Backup Script** (`scripts/backup.sh`):

```bash
#!/bin/bash
set -e

# Configuration
BACKUP_DIR="/opt/backups"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
docker exec comparateur-postgres pg_dump \
    -U comparateur \
    -Fc \
    comparateur > "${BACKUP_DIR}/comparateur_${DATE}.dump"

# Compress
gzip "${BACKUP_DIR}/comparateur_${DATE}.dump"

# Upload to S3 (optional)
if [ -n "$AWS_S3_BUCKET" ]; then
    aws s3 cp "${BACKUP_DIR}/comparateur_${DATE}.dump.gz" \
        "s3://${AWS_S3_BUCKET}/backups/"
fi

# Cleanup old backups
find "${BACKUP_DIR}" -name "*.dump.gz" -mtime +${RETENTION_DAYS} -delete

echo "Backup completed: comparateur_${DATE}.dump.gz"
```

**Deliverables**:

- [ ] PostgreSQL container running
- [ ] TimescaleDB extension enabled
- [ ] All tables created with indexes
- [ ] Search vector triggers working
- [ ] Backup script configured

---

## Monitoring Setup

**Uptime Kuma Configuration**:

| Monitor    | Type | URL                               | Interval |
| ---------- | ---- | --------------------------------- | -------- |
| Frontend   | HTTP | https://comparateur.fr            | 60s      |
| API Health | HTTP | https://api.comparateur.fr/health | 30s      |
| Database   | TCP  | postgres:5432                     | 60s      |
| Redis      | TCP  | redis:6379                        | 60s      |

**Health Check Endpoints**:

```go
// backend/internal/health/handler.go
func (h *HealthHandler) Check(w http.ResponseWriter, r *http.Request) {
    health := map[string]interface{}{
        "status": "ok",
        "timestamp": time.Now().UTC(),
        "checks": map[string]string{},
    }

    // Check database
    if err := h.db.Ping(r.Context()); err != nil {
        health["status"] = "degraded"
        health["checks"]["database"] = "error: " + err.Error()
    } else {
        health["checks"]["database"] = "ok"
    }

    // Check Redis
    if err := h.redis.Ping(r.Context()).Err(); err != nil {
        health["status"] = "degraded"
        health["checks"]["redis"] = "error: " + err.Error()
    } else {
        health["checks"]["redis"] = "ok"
    }

    statusCode := http.StatusOK
    if health["status"] != "ok" {
        statusCode = http.StatusServiceUnavailable
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(statusCode)
    json.NewEncoder(w).Encode(health)
}
```

---

## Cloud Migration Triggers

```mermaid
flowchart TB
    subgraph Triggers["Migration Triggers"]
        Traffic[">20K monthly visits"]
        Response["P95 > 500ms"]
        Cost["Proxy costs > €500/mo"]
        Team["Team > 2 developers"]
    end

    subgraph Actions["Migration Actions"]
        K8s[Migrate to Kubernetes]
        ManagedDB[Use Managed PostgreSQL]
        CDN[Enable Cloudflare Pro]
        Monitoring[Add Grafana Cloud]
    end

    Triggers --> Evaluate{Any trigger hit?}
    Evaluate -->|Yes| Plan[Plan migration]
    Plan --> Actions
    Evaluate -->|No| Stay[Stay on Dokploy]
```

**Migration Checklist**:

- [ ] Export database dump
- [ ] Convert docker-compose to Kubernetes manifests (kompose)
- [ ] Set up managed PostgreSQL (Scaleway/AWS RDS)
- [ ] Configure Kubernetes secrets
- [ ] Test in staging environment
- [ ] DNS cutover with zero downtime

---

## Cost Summary

### MVP Phase (Months 1-6)

| Item                        | Monthly Cost    |
| --------------------------- | --------------- |
| Hetzner VPS (CPX31)         | €15             |
| Domain (.fr)                | €1              |
| Cloudflare (free)           | €0              |
| Residential Proxies (~20GB) | €140            |
| **Total**                   | **~€156/month** |

### Growth Phase (6-12 months)

| Item                       | Monthly Cost    |
| -------------------------- | --------------- |
| Hetzner VPS (CPX41 - 16GB) | €30             |
| Managed PostgreSQL         | €25             |
| Cloudflare Pro             | €20             |
| Proxies (~50GB)            | €350            |
| **Total**                  | **~€425/month** |

---

## Definition of Done

- [ ] VPS running with all containers healthy
- [ ] CI/CD deploying on push to main
- [ ] Database backups running daily
- [ ] SSL certificates auto-renewing
- [ ] Uptime monitoring with alerts
- [ ] Health check endpoints responding
- [ ] Logs aggregated and searchable

---

_Estimated Effort: 8 days_  
_Last Updated: Week 0_
