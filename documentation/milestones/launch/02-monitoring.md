# Phase 02: Monitoring

> **Uptime monitoring, logs, alerts**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      02 - Monitoring                                   ║
║  Initiative: Launch                                            ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Setup monitoring, logging, and alerting for production services.

## Tasks

- [ ] Setup Uptime Kuma for health checks
- [ ] Configure centralized logging
- [ ] Add error tracking
- [ ] Setup alerts (email/Discord)
- [ ] Create dashboards

## Uptime Kuma Setup

```yaml
# Add to docker-compose.prod.yml
uptime-kuma:
  image: louislam/uptime-kuma:1
  volumes:
    - uptime_kuma_data:/app/data
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.uptime.rule=Host(`status.pareto.fr`)"
    - "traefik.http.routers.uptime.entrypoints=websecure"
    - "traefik.http.routers.uptime.tls=true"
    - "traefik.http.services.uptime.loadbalancer.server.port=3001"
```

### Monitors to Configure

| Monitor | URL | Type | Interval |
|---------|-----|------|----------|
| API Health | `http://api:8080/health` | HTTP | 60s |
| Web | `https://pareto.fr` | HTTP | 60s |
| PostgreSQL | `postgres:5432` | TCP | 60s |
| Redis | `redis:6379` | TCP | 60s |
| Scraper | `http://api:8080/health/scraper` | HTTP | 300s |

## Loki + Grafana for Logs

```yaml
# Add to docker-compose.prod.yml
loki:
  image: grafana/loki:2.9.0
  command: -config.file=/etc/loki/local-config.yaml
  volumes:
    - loki_data:/loki

grafana:
  image: grafana/grafana:10.2.0
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
  volumes:
    - grafana_data:/var/lib/grafana
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.grafana.rule=Host(`grafana.pareto.local`)"

promtail:
  image: grafana/promtail:2.9.0
  volumes:
    - /var/log:/var/log
    - /var/run/docker.sock:/var/run/docker.sock
    - ./promtail-config.yml:/etc/promtail/config.yml
  command: -config.file=/etc/promtail/config.yml
```

### Promtail Configuration

```yaml
# promtail-config.yml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: containers
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
```

## Application Logging

```go
// apps/api/internal/logger/logger.go
package logger

import (
    "os"
    "github.com/rs/zerolog"
    "github.com/rs/zerolog/log"
)

func Init() {
    zerolog.TimeFieldFormat = zerolog.TimeFormatUnix

    // JSON output for production
    if os.Getenv("GIN_MODE") == "release" {
        log.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()
    } else {
        // Pretty console for development
        log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
    }
}

// Structured logging examples
func LogScrapeFailed(retailer, url string, err error) {
    log.Error().
        Str("module", "scraper").
        Str("retailer", retailer).
        Str("url", url).
        Err(err).
        Msg("scrape failed")
}

func LogAPIRequest(method, path string, status int, duration float64) {
    log.Info().
        Str("module", "api").
        Str("method", method).
        Str("path", path).
        Int("status", status).
        Float64("duration_ms", duration).
        Msg("request handled")
}
```

## Error Tracking (Sentry-like with self-hosted)

For budget MVP, we'll use application logging + Grafana alerts rather than paid error tracking.

```go
// Simple error tracking middleware
func ErrorTracker() gin.HandlerFunc {
    return func(c *gin.Context) {
        defer func() {
            if err := recover(); err != nil {
                log.Error().
                    Interface("panic", err).
                    Str("path", c.Request.URL.Path).
                    Str("method", c.Request.Method).
                    Msg("panic recovered")

                c.AbortWithStatus(http.StatusInternalServerError)
            }
        }()
        c.Next()

        // Log errors
        if len(c.Errors) > 0 {
            for _, e := range c.Errors {
                log.Error().
                    Err(e.Err).
                    Str("path", c.Request.URL.Path).
                    Msg("request error")
            }
        }
    }
}
```

## Alert Configuration

### Discord Webhook Alerts

```go
// apps/api/internal/alerting/discord.go
package alerting

import (
    "bytes"
    "encoding/json"
    "net/http"
)

type DiscordAlert struct {
    webhookURL string
}

func NewDiscordAlert(webhookURL string) *DiscordAlert {
    return &DiscordAlert{webhookURL: webhookURL}
}

func (d *DiscordAlert) SendAlert(title, message, severity string) error {
    color := 0x00ff00 // green
    switch severity {
    case "warning":
        color = 0xffff00 // yellow
    case "error":
        color = 0xff0000 // red
    }

    payload := map[string]interface{}{
        "embeds": []map[string]interface{}{
            {
                "title":       title,
                "description": message,
                "color":       color,
                "footer": map[string]string{
                    "text": "Pareto Monitoring",
                },
            },
        },
    }

    body, _ := json.Marshal(payload)
    _, err := http.Post(d.webhookURL, "application/json", bytes.NewReader(body))
    return err
}
```

### Uptime Kuma Alert Rules

Configure in Uptime Kuma UI:
1. Discord webhook notification
2. Alert after 3 consecutive failures
3. Notify on recovery

## Health Check Endpoints

```go
// apps/api/internal/health/handler.go
package health

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "gorm.io/gorm"
    "github.com/redis/go-redis/v9"
)

type Handler struct {
    db    *gorm.DB
    redis *redis.Client
}

func (h *Handler) Health(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "status": "ok",
        "checks": gin.H{
            "database": h.checkDatabase(),
            "redis":    h.checkRedis(),
        },
    })
}

func (h *Handler) checkDatabase() string {
    sqlDB, err := h.db.DB()
    if err != nil {
        return "error"
    }
    if err := sqlDB.Ping(); err != nil {
        return "error"
    }
    return "ok"
}

func (h *Handler) checkRedis() string {
    ctx := context.Background()
    if err := h.redis.Ping(ctx).Err(); err != nil {
        return "error"
    }
    return "ok"
}

// Detailed health for internal monitoring
func (h *Handler) DetailedHealth(c *gin.Context) {
    var productCount int64
    h.db.Model(&models.Product{}).Count(&productCount)

    var offerCount int64
    h.db.Model(&models.Offer{}).Count(&offerCount)

    c.JSON(http.StatusOK, gin.H{
        "status": "ok",
        "metrics": gin.H{
            "products": productCount,
            "offers":   offerCount,
        },
    })
}
```

## Grafana Dashboard

Key panels to create:
1. **Request Rate** - API requests per minute
2. **Error Rate** - 5xx errors over time
3. **Response Time** - p50, p95, p99 latencies
4. **Database Connections** - Active connections
5. **Scraper Success Rate** - Successful scrapes %
6. **Products/Offers Count** - Total catalog size

## Deliverables

- [ ] Uptime Kuma monitoring all services
- [ ] Loki + Grafana for logs
- [ ] Structured logging in all apps
- [ ] Discord alerts configured
- [ ] Health endpoints working
- [ ] Grafana dashboards created

---

**Previous Phase**: [01-deploy.md](./01-deploy.md)
**Next Phase**: [03-testing.md](./03-testing.md)
**Back to**: [Launch README](./README.md)
