# Go 1.24 - Backend API

> **High-performance API server with Chi router**

## Version Info

| Attribute | Value |
|-----------|-------|
| **Version** | 1.24.10 |
| **Release** | February 2025 |
| **EOL** | February 2026 |
| **Context7** | `/golang/go/go1_24_6` |

## Project Structure

```
apps/api/
├── cmd/
│   └── api/
│       └── main.go           # Entry point
├── internal/
│   ├── catalog/              # Product domain
│   │   ├── domain/           # Entities
│   │   ├── repository/       # Data access
│   │   ├── service/          # Business logic
│   │   └── handler/          # HTTP handlers
│   ├── scraper/              # Scraping orchestration
│   ├── compare/              # Pareto comparison
│   ├── affiliate/            # Revenue tracking
│   └── shared/               # Infrastructure
│       ├── database/         # PostgreSQL connection
│       ├── cache/            # Redis client
│       └── config/           # Configuration
├── go.mod
├── go.sum
└── Dockerfile
```

## Go 1.24 Key Features

### Generic Type Aliases

```go
// Now fully supported in Go 1.24
type Result[T any] = struct {
    Data  T
    Error error
}

type ProductResult = Result[Product]
type OfferResult = Result[[]Offer]
```

### Tool Directives in go.mod

```go
// go.mod - No more tools.go workaround
module github.com/pareto/api

go 1.24

require (
    github.com/go-chi/chi/v5 v5.2.0
    github.com/jackc/pgx/v5 v5.7.0
    github.com/redis/go-redis/v9 v9.7.0
)

tool (
    golang.org/x/tools/cmd/goimports
    github.com/golangci/golangci-lint/cmd/golangci-lint
)
```

### Run Tools Directly

```bash
# Go 1.24: Run tools without installation
go tool goimports -w .
go tool golangci-lint run
```

## Chi Router Setup

```go
// internal/shared/router/router.go
package router

import (
    "net/http"
    "time"

    "github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"
    "github.com/go-chi/cors"
)

func New() *chi.Mux {
    r := chi.NewRouter()

    // Middleware stack
    r.Use(middleware.RequestID)
    r.Use(middleware.RealIP)
    r.Use(middleware.Logger)
    r.Use(middleware.Recoverer)
    r.Use(middleware.Timeout(30 * time.Second))

    // CORS for frontend
    r.Use(cors.Handler(cors.Options{
        AllowedOrigins:   []string{"https://pareto.fr", "http://localhost:3000"},
        AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
        ExposedHeaders:   []string{"Link"},
        AllowCredentials: true,
        MaxAge:           300,
    }))

    return r
}
```

## Handler Pattern

```go
// internal/catalog/handler/product_handler.go
package handler

import (
    "encoding/json"
    "net/http"

    "github.com/go-chi/chi/v5"
    "github.com/pareto/api/internal/catalog/service"
)

type ProductHandler struct {
    svc *service.ProductService
}

func NewProductHandler(svc *service.ProductService) *ProductHandler {
    return &ProductHandler{svc: svc}
}

func (h *ProductHandler) Routes() chi.Router {
    r := chi.NewRouter()

    r.Get("/", h.List)
    r.Get("/{slug}", h.GetBySlug)
    r.Get("/{id}/prices", h.GetPriceHistory)
    r.Post("/search", h.Search)

    return r
}

func (h *ProductHandler) List(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    // Parse query params
    limit := parseIntOrDefault(r.URL.Query().Get("limit"), 20)
    offset := parseIntOrDefault(r.URL.Query().Get("offset"), 0)
    category := r.URL.Query().Get("category")

    products, total, err := h.svc.List(ctx, service.ListParams{
        Limit:    limit,
        Offset:   offset,
        Category: category,
    })
    if err != nil {
        respondError(w, http.StatusInternalServerError, err)
        return
    }

    respondJSON(w, http.StatusOK, map[string]any{
        "data":  products,
        "total": total,
        "limit": limit,
        "offset": offset,
    })
}

func (h *ProductHandler) GetBySlug(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    slug := chi.URLParam(r, "slug")

    product, err := h.svc.GetBySlug(ctx, slug)
    if err != nil {
        respondError(w, http.StatusNotFound, err)
        return
    }

    respondJSON(w, http.StatusOK, product)
}
```

## Repository Pattern

```go
// internal/catalog/repository/product_repository.go
package repository

import (
    "context"

    "github.com/jackc/pgx/v5/pgxpool"
    "github.com/pareto/api/internal/catalog/domain"
)

type ProductRepository struct {
    db *pgxpool.Pool
}

func NewProductRepository(db *pgxpool.Pool) *ProductRepository {
    return &ProductRepository{db: db}
}

func (r *ProductRepository) FindBySlug(ctx context.Context, slug string) (*domain.Product, error) {
    query := `
        SELECT id, slug, name, brand, category_id, attributes, created_at, updated_at
        FROM products
        WHERE slug = $1
    `

    var p domain.Product
    err := r.db.QueryRow(ctx, query, slug).Scan(
        &p.ID, &p.Slug, &p.Name, &p.Brand, &p.CategoryID,
        &p.Attributes, &p.CreatedAt, &p.UpdatedAt,
    )
    if err != nil {
        return nil, err
    }

    return &p, nil
}

func (r *ProductRepository) List(ctx context.Context, params ListParams) ([]domain.Product, int, error) {
    countQuery := `SELECT COUNT(*) FROM products WHERE ($1 = '' OR category_id = $1)`

    var total int
    if err := r.db.QueryRow(ctx, countQuery, params.Category).Scan(&total); err != nil {
        return nil, 0, err
    }

    query := `
        SELECT id, slug, name, brand, category_id, attributes, created_at, updated_at
        FROM products
        WHERE ($1 = '' OR category_id = $1)
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3
    `

    rows, err := r.db.Query(ctx, query, params.Category, params.Limit, params.Offset)
    if err != nil {
        return nil, 0, err
    }
    defer rows.Close()

    var products []domain.Product
    for rows.Next() {
        var p domain.Product
        if err := rows.Scan(
            &p.ID, &p.Slug, &p.Name, &p.Brand, &p.CategoryID,
            &p.Attributes, &p.CreatedAt, &p.UpdatedAt,
        ); err != nil {
            return nil, 0, err
        }
        products = append(products, p)
    }

    return products, total, nil
}
```

## Database Connection (pgx v5)

```go
// internal/shared/database/postgres.go
package database

import (
    "context"
    "fmt"
    "time"

    "github.com/jackc/pgx/v5/pgxpool"
)

type Config struct {
    Host     string
    Port     int
    User     string
    Password string
    Database string
    SSLMode  string
}

func NewPool(ctx context.Context, cfg Config) (*pgxpool.Pool, error) {
    dsn := fmt.Sprintf(
        "postgres://%s:%s@%s:%d/%s?sslmode=%s",
        cfg.User, cfg.Password, cfg.Host, cfg.Port, cfg.Database, cfg.SSLMode,
    )

    config, err := pgxpool.ParseConfig(dsn)
    if err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }

    // Connection pool settings
    config.MaxConns = 25
    config.MinConns = 5
    config.MaxConnLifetime = time.Hour
    config.MaxConnIdleTime = 30 * time.Minute
    config.HealthCheckPeriod = time.Minute

    pool, err := pgxpool.NewWithConfig(ctx, config)
    if err != nil {
        return nil, fmt.Errorf("create pool: %w", err)
    }

    // Verify connection
    if err := pool.Ping(ctx); err != nil {
        return nil, fmt.Errorf("ping: %w", err)
    }

    return pool, nil
}
```

## Redis Client (go-redis v9)

```go
// internal/shared/cache/redis.go
package cache

import (
    "context"
    "encoding/json"
    "time"

    "github.com/redis/go-redis/v9"
)

type RedisCache struct {
    client *redis.Client
}

func NewRedisCache(addr string) *RedisCache {
    client := redis.NewClient(&redis.Options{
        Addr:         addr,
        Password:     "",
        DB:           0,
        PoolSize:     100,
        MinIdleConns: 10,
    })

    return &RedisCache{client: client}
}

func (c *RedisCache) Get(ctx context.Context, key string, dest any) error {
    val, err := c.client.Get(ctx, key).Result()
    if err != nil {
        return err
    }
    return json.Unmarshal([]byte(val), dest)
}

func (c *RedisCache) Set(ctx context.Context, key string, value any, ttl time.Duration) error {
    data, err := json.Marshal(value)
    if err != nil {
        return err
    }
    return c.client.Set(ctx, key, data, ttl).Err()
}

func (c *RedisCache) Delete(ctx context.Context, keys ...string) error {
    return c.client.Del(ctx, keys...).Err()
}

// Pattern-based invalidation
func (c *RedisCache) DeletePattern(ctx context.Context, pattern string) error {
    iter := c.client.Scan(ctx, 0, pattern, 0).Iterator()
    var keys []string
    for iter.Next(ctx) {
        keys = append(keys, iter.Val())
    }
    if len(keys) > 0 {
        return c.client.Del(ctx, keys...).Err()
    }
    return nil
}
```

## Error Handling

```go
// internal/shared/errors/errors.go
package errors

import (
    "errors"
    "net/http"
)

var (
    ErrNotFound     = errors.New("resource not found")
    ErrInvalidInput = errors.New("invalid input")
    ErrUnauthorized = errors.New("unauthorized")
    ErrForbidden    = errors.New("forbidden")
)

type APIError struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
}

func (e APIError) Error() string {
    return e.Message
}

func NewAPIError(code int, message string) APIError {
    return APIError{Code: code, Message: message}
}

func HTTPStatus(err error) int {
    switch {
    case errors.Is(err, ErrNotFound):
        return http.StatusNotFound
    case errors.Is(err, ErrInvalidInput):
        return http.StatusBadRequest
    case errors.Is(err, ErrUnauthorized):
        return http.StatusUnauthorized
    case errors.Is(err, ErrForbidden):
        return http.StatusForbidden
    default:
        return http.StatusInternalServerError
    }
}
```

## Structured Logging (zerolog)

```go
// internal/shared/logger/logger.go
package logger

import (
    "os"
    "time"

    "github.com/rs/zerolog"
    "github.com/rs/zerolog/log"
)

func Init(env string) {
    zerolog.TimeFieldFormat = time.RFC3339

    if env == "development" {
        log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
    } else {
        log.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()
    }
}

// Usage examples
func LogRequest(method, path string, status int, duration time.Duration) {
    log.Info().
        Str("method", method).
        Str("path", path).
        Int("status", status).
        Dur("duration", duration).
        Msg("request handled")
}

func LogScrapeError(retailer, url string, err error) {
    log.Error().
        Str("module", "scraper").
        Str("retailer", retailer).
        Str("url", url).
        Err(err).
        Msg("scrape failed")
}
```

## Testing

```go
// internal/catalog/handler/product_handler_test.go
package handler_test

import (
    "context"
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/go-chi/chi/v5"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

func TestProductHandler_GetBySlug(t *testing.T) {
    // Setup
    mockSvc := new(MockProductService)
    handler := NewProductHandler(mockSvc)

    product := &domain.Product{
        ID:   "uuid-123",
        Slug: "iphone-15-pro",
        Name: "iPhone 15 Pro",
    }

    mockSvc.On("GetBySlug", mock.Anything, "iphone-15-pro").Return(product, nil)

    // Create request
    r := chi.NewRouter()
    r.Get("/products/{slug}", handler.GetBySlug)

    req := httptest.NewRequest("GET", "/products/iphone-15-pro", nil)
    w := httptest.NewRecorder()

    // Execute
    r.ServeHTTP(w, req)

    // Assert
    assert.Equal(t, http.StatusOK, w.Code)
    mockSvc.AssertExpectations(t)
}
```

## Configuration

```go
// internal/shared/config/config.go
package config

import (
    "os"
    "strconv"
)

type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    Redis    RedisConfig
}

type ServerConfig struct {
    Port string
    Env  string
}

type DatabaseConfig struct {
    Host     string
    Port     int
    User     string
    Password string
    Database string
}

type RedisConfig struct {
    Addr string
}

func Load() *Config {
    return &Config{
        Server: ServerConfig{
            Port: getEnv("PORT", "8080"),
            Env:  getEnv("GO_ENV", "development"),
        },
        Database: DatabaseConfig{
            Host:     getEnv("DB_HOST", "localhost"),
            Port:     getEnvInt("DB_PORT", 5432),
            User:     getEnv("DB_USER", "pareto"),
            Password: getEnv("DB_PASSWORD", ""),
            Database: getEnv("DB_NAME", "pareto"),
        },
        Redis: RedisConfig{
            Addr: getEnv("REDIS_ADDR", "localhost:6379"),
        },
    }
}

func getEnv(key, fallback string) string {
    if val := os.Getenv(key); val != "" {
        return val
    }
    return fallback
}

func getEnvInt(key string, fallback int) int {
    if val := os.Getenv(key); val != "" {
        if i, err := strconv.Atoi(val); err == nil {
            return i
        }
    }
    return fallback
}
```

## Dockerfile

```dockerfile
# apps/api/Dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /api ./cmd/api

# Production image
FROM alpine:3.21

RUN apk --no-cache add ca-certificates wget

WORKDIR /app

COPY --from=builder /api .

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:8080/health || exit 1

CMD ["./api"]
```

## Commands

```bash
# Development
go run ./cmd/api

# Build
go build -o bin/api ./cmd/api

# Test
go test ./...
go test -v -cover ./internal/...

# Lint
go tool golangci-lint run

# Format
go fmt ./...
go tool goimports -w .

# Generate mocks
go generate ./...
```

---

**See Also**:
- [Python Workers](./python.md)
- [PostgreSQL](./postgresql.md)
- [Redis](./redis.md)
