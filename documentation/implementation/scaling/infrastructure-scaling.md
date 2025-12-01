# Infrastructure Scaling - VPS to Kubernetes

> **Infrastructure evolution path for Pareto**

## Overview

Pareto's infrastructure scales in stages:
1. **MVP**: Single VPS with Docker Compose (Dokploy)
2. **Growth**: Multi-VPS with load balancing
3. **Scale**: Kubernetes cluster with auto-scaling

## Infrastructure Stages

```
                    INFRASTRUCTURE EVOLUTION

    STAGE 1: MVP                STAGE 2: GROWTH           STAGE 3: SCALE
    ────────────                ───────────────           ──────────────
    Single VPS                  Multi-VPS                 Kubernetes
    Docker Compose              Dokploy Cluster           Auto-scaling

    [Cloudflare]                [Cloudflare]              [Cloudflare]
         │                           │                          │
    [Dokploy VPS]              [Load Balancer]            [K8s Ingress]
         │                      /    │    \                     │
    ┌────┴────┐            [VPS1] [VPS2] [VPS3]         ┌───────┴───────┐
    │ Docker  │                 │                       │   Services    │
    │ Compose │            [Managed DB]                 │ (HPA/VPA)     │
    └─────────┘            [Managed Redis]              └───────────────┘
                                                               │
    Est. Cost: €50/mo       Est. Cost: €300/mo          [Managed DB + Redis]

    Capacity: 100K MAU      Capacity: 500K MAU          Est. Cost: €1000+/mo
                                                        Capacity: Unlimited
```

## Stage 1: MVP (Current)

### Architecture

```yaml
# docker-compose.yml
version: "3.9"

services:
  traefik:
    image: traefik:v3.2
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./traefik:/etc/traefik

  api:
    build: ./apps/api
    expose:
      - "8080"
    labels:
      - "traefik.http.routers.api.rule=Host(`api.pareto.com`)"
    depends_on:
      - postgres
      - redis

  web:
    build: ./apps/web
    expose:
      - "3000"
    labels:
      - "traefik.http.routers.web.rule=Host(`pareto.com`)"

  workers:
    build: ./apps/workers
    depends_on:
      - postgres
      - redis

  postgres:
    image: timescale/timescaledb:2.23.0-pg18
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: pareto
      POSTGRES_USER: pareto
      POSTGRES_PASSWORD: ${DB_PASSWORD}

  redis:
    image: redis:8.4-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Capacity Limits

| Resource | Limit | Trigger |
|----------|-------|---------|
| CPU | 80% sustained | Scale up |
| Memory | 85% used | Scale up |
| Disk | 80% used | Expand or archive |
| Connections | 80/100 | Scale up |
| Response P95 | >500ms | Optimize or scale |

### Cost Estimate

```
VPS (Hetzner CPX31): €15/mo
- 4 vCPU, 8GB RAM, 160GB SSD

Cloudflare Pro: €20/mo
- CDN, WAF, Analytics

Domain: €10/year

Backups: €5/mo

Total: ~€50/mo
```

## Stage 2: Growth

### When to Trigger

- MAU > 100K
- API requests > 100/sec sustained
- Database size > 50GB
- Worker queue consistently > 500

### Architecture

```yaml
# Multi-VPS with managed services

# VPS 1: API + Web
services:
  api:
    replicas: 2
    resources:
      limits:
        cpus: "2"
        memory: 4G

  web:
    replicas: 2
    resources:
      limits:
        cpus: "1"
        memory: 2G

# VPS 2: Workers
services:
  workers:
    replicas: 4
    resources:
      limits:
        cpus: "2"
        memory: 4G

# Managed Services
external:
  postgres:
    provider: Hetzner Managed PostgreSQL
    plan: cx21 (4 vCPU, 16GB RAM)
    features:
      - Automated backups
      - Point-in-time recovery
      - Read replicas

  redis:
    provider: Upstash or Redis Cloud
    plan: 1GB
    features:
      - Persistence
      - Replication
```

### Load Balancing

```yaml
# Cloudflare Load Balancer
load_balancer:
  pool:
    - origin: vps1.pareto.com
      weight: 1
    - origin: vps2.pareto.com
      weight: 1

  health_check:
    path: /health
    interval: 30s
    timeout: 5s

  steering:
    policy: dynamic_latency
```

### Cost Estimate

```
VPS x2 (Hetzner CPX41): €60/mo
- 8 vCPU, 16GB RAM each

Managed PostgreSQL: €50/mo
Managed Redis: €30/mo
Cloudflare Pro: €20/mo
Load Balancer: €10/mo
Backups: €20/mo

Total: ~€300/mo
```

## Stage 3: Scale (Kubernetes)

### When to Trigger

- MAU > 500K
- Need for auto-scaling
- Multi-region deployment
- 99.9% SLA requirement

### Architecture

```yaml
# Kubernetes Deployment

apiVersion: apps/v1
kind: Deployment
metadata:
  name: pareto-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pareto-api
  template:
    metadata:
      labels:
        app: pareto-api
    spec:
      containers:
        - name: api
          image: pareto/api:latest
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "2000m"
              memory: "2Gi"
          ports:
            - containerPort: 8080
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: pareto-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: pareto-api
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

### Worker Scaling with KEDA

```yaml
# KEDA ScaledObject for Celery workers
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: pareto-workers
spec:
  scaleTargetRef:
    name: pareto-workers
  minReplicaCount: 2
  maxReplicaCount: 50
  triggers:
    - type: redis
      metadata:
        address: redis.pareto.svc:6379
        listName: celery
        listLength: "100"  # Scale up when queue > 100
```

### Database Scaling

```yaml
# PostgreSQL with read replicas
database:
  primary:
    type: Managed PostgreSQL
    provider: AWS RDS / GCP Cloud SQL / Hetzner
    size: db.r6g.xlarge
    storage: 500GB SSD

  read_replicas:
    count: 2
    size: db.r6g.large
    regions:
      - eu-west-1
      - eu-central-1

  connection_pooling:
    provider: PgBouncer
    max_connections: 1000
    pool_mode: transaction
```

### Cost Estimate

```
Kubernetes Cluster (3 nodes): €300/mo
- Hetzner Cloud or DigitalOcean

Managed PostgreSQL (HA): €200/mo
Managed Redis (HA): €50/mo
Container Registry: €20/mo
Monitoring (Datadog/Grafana): €100/mo
Cloudflare Enterprise: €200/mo
Backups & DR: €50/mo

Total: ~€1000/mo
```

## Migration Playbooks

### VPS to Multi-VPS

```bash
# 1. Provision new VPS
hcloud server create --name vps2 --type cpx41 --image ubuntu-24.04

# 2. Set up managed database
# Migrate data during low-traffic window
pg_dump -h localhost pareto | psql -h managed-db.example.com pareto

# 3. Update application configs
# Point to external database
export DATABASE_URL="postgres://managed-db.example.com:5432/pareto"

# 4. Deploy to new VPS
dokploy deploy --target vps2

# 5. Update load balancer
# Add vps2 to pool

# 6. Verify and cutover
```

### Multi-VPS to Kubernetes

```bash
# 1. Set up K8s cluster
kubectl create cluster pareto-prod --nodes 3

# 2. Install dependencies
helm install ingress-nginx ingress-nginx/ingress-nginx
helm install cert-manager jetstack/cert-manager
helm install keda kedacore/keda

# 3. Build and push images
docker build -t registry.pareto.com/api:v1.0 ./apps/api
docker push registry.pareto.com/api:v1.0

# 4. Deploy applications
kubectl apply -f k8s/

# 5. Migrate DNS
# Point to K8s ingress

# 6. Scale down old infrastructure
```

## Monitoring & Observability

### Metrics Stack

```yaml
# Prometheus + Grafana
monitoring:
  prometheus:
    scrape_interval: 15s
    retention: 30d

  grafana:
    dashboards:
      - api_performance
      - worker_queues
      - database_metrics
      - business_kpis

  alerting:
    - name: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
      for: 5m
      severity: critical

    - name: HighLatency
      expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 0.5
      for: 5m
      severity: warning

    - name: QueueBacklog
      expr: celery_queue_length > 500
      for: 10m
      severity: warning
```

### Logging Stack

```yaml
# Loki + Promtail
logging:
  format: json
  fields:
    - timestamp
    - level
    - service
    - trace_id
    - message
    - error

  retention: 14d

  alerts:
    - name: ErrorSpike
      query: |
        sum(rate({level="error"}[5m])) > 10
```

## Related Documentation

- [Geographic Expansion](./geographic-expansion.md) - Multi-region considerations
- [Platform Expansion](./platform-expansion.md) - API scaling
- [Original Infrastructure Spec](../../reference/specs/infrastructure.md)

---

**Last Updated**: 2025-12-01
