# Redis 8.4 - Cache & Message Queue

> **In-memory data store with JSON, Query Engine, and Pub/Sub**

## Version Info

| Attribute | Value |
|-----------|-------|
| **Version** | 8.4.0 |
| **Release** | November 2025 |
| **Protocol** | RESP3 |

## Redis 8 Key Features

### Unified Redis (OSS + Stack)

Redis 8 merges Redis OSS and Redis Stack:
- **RedisJSON**: Native JSON data type
- **RediSearch**: Full-text search and secondary indexes
- **RedisTimeSeries**: Time-series data (alternative to TimescaleDB)

### Built-in JSON Support

```bash
# JSON.SET - Store JSON document
JSON.SET product:123 $ '{"name":"iPhone 15 Pro","brand":"Apple","price":1199}'

# JSON.GET - Retrieve JSON
JSON.GET product:123 $.name
# "iPhone 15 Pro"

# JSON.MGET - Multiple keys
JSON.MGET product:123 product:456 $.price

# JSON.NUMINCRBY - Atomic increment
JSON.NUMINCRBY product:123 $.views 1
```

### Query Engine (RediSearch)

```bash
# Create index
FT.CREATE idx:products
  ON JSON
  PREFIX 1 product:
  SCHEMA
    $.name AS name TEXT WEIGHT 5.0
    $.brand AS brand TEXT WEIGHT 2.0
    $.category AS category TAG
    $.price AS price NUMERIC SORTABLE

# Search
FT.SEARCH idx:products "@brand:Apple @category:{smartphones}" SORTBY price ASC

# Aggregate
FT.AGGREGATE idx:products "*"
  GROUPBY 1 @brand
  REDUCE COUNT 0 AS count
  REDUCE MIN 1 @price AS min_price
  SORTBY 2 @count DESC
```

## Data Structures

### Caching Products

```go
// Go: Product caching with go-redis v9
package cache

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/redis/go-redis/v9"
)

type ProductCache struct {
    client *redis.Client
    ttl    time.Duration
}

func NewProductCache(client *redis.Client, ttl time.Duration) *ProductCache {
    return &ProductCache{client: client, ttl: ttl}
}

func (c *ProductCache) key(slug string) string {
    return fmt.Sprintf("product:%s", slug)
}

func (c *ProductCache) Get(ctx context.Context, slug string) (*Product, error) {
    val, err := c.client.Get(ctx, c.key(slug)).Result()
    if err == redis.Nil {
        return nil, nil // Cache miss
    }
    if err != nil {
        return nil, err
    }

    var product Product
    if err := json.Unmarshal([]byte(val), &product); err != nil {
        return nil, err
    }
    return &product, nil
}

func (c *ProductCache) Set(ctx context.Context, product *Product) error {
    data, err := json.Marshal(product)
    if err != nil {
        return err
    }
    return c.client.Set(ctx, c.key(product.Slug), data, c.ttl).Err()
}

func (c *ProductCache) Invalidate(ctx context.Context, slug string) error {
    return c.client.Del(ctx, c.key(slug)).Err()
}

// Bulk invalidation by pattern
func (c *ProductCache) InvalidateCategory(ctx context.Context, category string) error {
    pattern := fmt.Sprintf("product:%s:*", category)
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

### Session Storage

```go
// Session management
type SessionStore struct {
    client *redis.Client
    ttl    time.Duration
}

func (s *SessionStore) Create(ctx context.Context, userID string) (string, error) {
    sessionID := uuid.New().String()
    key := fmt.Sprintf("session:%s", sessionID)

    session := map[string]interface{}{
        "user_id":    userID,
        "created_at": time.Now().Unix(),
    }

    data, _ := json.Marshal(session)
    if err := s.client.Set(ctx, key, data, s.ttl).Err(); err != nil {
        return "", err
    }

    return sessionID, nil
}

func (s *SessionStore) Get(ctx context.Context, sessionID string) (*Session, error) {
    key := fmt.Sprintf("session:%s", sessionID)
    val, err := s.client.Get(ctx, key).Result()
    if err == redis.Nil {
        return nil, ErrSessionNotFound
    }
    if err != nil {
        return nil, err
    }

    var session Session
    json.Unmarshal([]byte(val), &session)

    // Extend TTL on access
    s.client.Expire(ctx, key, s.ttl)

    return &session, nil
}
```

### Rate Limiting

```go
// Sliding window rate limiter
func (c *RedisCache) CheckRateLimit(ctx context.Context, key string, limit int, window time.Duration) (bool, int, error) {
    now := time.Now().UnixMicro()
    windowStart := now - window.Microseconds()
    rateLimitKey := fmt.Sprintf("ratelimit:%s", key)

    pipe := c.client.Pipeline()

    // Remove old entries
    pipe.ZRemRangeByScore(ctx, rateLimitKey, "0", fmt.Sprintf("%d", windowStart))

    // Count current entries
    countCmd := pipe.ZCard(ctx, rateLimitKey)

    // Add current request
    pipe.ZAdd(ctx, rateLimitKey, redis.Z{Score: float64(now), Member: now})

    // Set expiry
    pipe.Expire(ctx, rateLimitKey, window)

    _, err := pipe.Exec(ctx)
    if err != nil {
        return false, 0, err
    }

    count := int(countCmd.Val())
    remaining := limit - count - 1

    if count >= limit {
        return false, 0, nil // Rate limited
    }

    return true, remaining, nil
}
```

### Job Queue (Celery-compatible)

```go
// Publish scraping job to Celery
func (q *JobQueue) PublishScrapeJob(ctx context.Context, job ScrapeJob) error {
    // Celery message format
    message := map[string]interface{}{
        "id":   uuid.New().String(),
        "task": "workers.scraper.scrape_url",
        "args": []interface{}{job.URL, job.RetailerID},
        "kwargs": map[string]interface{}{
            "proxy": job.Proxy,
        },
        "retries":  0,
        "eta":      nil,
        "expires":  nil,
    }

    data, _ := json.Marshal(message)

    // Push to Celery queue
    return q.client.LPush(ctx, "celery", data).Err()
}

// Subscribe to results
func (q *JobQueue) SubscribeResults(ctx context.Context, handler func(result ScrapeResult)) error {
    pubsub := q.client.Subscribe(ctx, "scrape_results")
    defer pubsub.Close()

    ch := pubsub.Channel()
    for msg := range ch {
        var result ScrapeResult
        if err := json.Unmarshal([]byte(msg.Payload), &result); err != nil {
            continue
        }
        handler(result)
    }

    return nil
}
```

## Pub/Sub Patterns

### Real-time Price Updates

```go
// Publisher: Python worker publishes price updates
// Redis: PUBLISH price_updates '{"product_id":"123","price":999}'

// Subscriber: Go API subscribes
func (s *PriceSubscriber) Subscribe(ctx context.Context) error {
    pubsub := s.client.Subscribe(ctx, "price_updates")
    defer pubsub.Close()

    ch := pubsub.Channel()
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case msg := <-ch:
            var update PriceUpdate
            if err := json.Unmarshal([]byte(msg.Payload), &update); err != nil {
                log.Error().Err(err).Msg("failed to parse price update")
                continue
            }

            // Invalidate cache
            s.cache.Invalidate(ctx, update.ProductID)

            // Notify WebSocket clients
            s.wsHub.Broadcast(update)
        }
    }
}
```

### Comparison Progress

```go
// Track comparison progress
type ComparisonTracker struct {
    client *redis.Client
}

func (t *ComparisonTracker) StartComparison(ctx context.Context, comparisonID string, totalProducts int) error {
    key := fmt.Sprintf("comparison:%s:progress", comparisonID)
    return t.client.HSet(ctx, key,
        "total", totalProducts,
        "completed", 0,
        "status", "in_progress",
    ).Err()
}

func (t *ComparisonTracker) UpdateProgress(ctx context.Context, comparisonID string) (int, int, error) {
    key := fmt.Sprintf("comparison:%s:progress", comparisonID)

    completed, err := t.client.HIncrBy(ctx, key, "completed", 1).Result()
    if err != nil {
        return 0, 0, err
    }

    total, _ := t.client.HGet(ctx, key, "total").Int()

    // Publish progress update
    t.client.Publish(ctx, fmt.Sprintf("comparison:%s", comparisonID), fmt.Sprintf("%d/%d", completed, total))

    return int(completed), total, nil
}

func (t *ComparisonTracker) SubscribeProgress(ctx context.Context, comparisonID string, handler func(progress string)) error {
    pubsub := t.client.Subscribe(ctx, fmt.Sprintf("comparison:%s", comparisonID))
    defer pubsub.Close()

    ch := pubsub.Channel()
    for msg := range ch {
        handler(msg.Payload)
    }

    return nil
}
```

## Lua Scripts

```lua
-- Atomic cache-aside pattern
-- KEYS[1]: cache key
-- ARGV[1]: TTL in seconds
-- Returns cached value or nil (then caller fetches from DB)

local cached = redis.call('GET', KEYS[1])
if cached then
    -- Extend TTL on hit
    redis.call('EXPIRE', KEYS[1], ARGV[1])
    return cached
end
return nil
```

```go
// Execute Lua script
var cacheAsideScript = redis.NewScript(`
local cached = redis.call('GET', KEYS[1])
if cached then
    redis.call('EXPIRE', KEYS[1], ARGV[1])
    return cached
end
return nil
`)

func (c *Cache) GetWithExtend(ctx context.Context, key string, ttl time.Duration) (string, error) {
    result, err := cacheAsideScript.Run(ctx, c.client, []string{key}, int(ttl.Seconds())).Result()
    if err == redis.Nil {
        return "", nil
    }
    if err != nil {
        return "", err
    }
    return result.(string), nil
}
```

## Configuration

```go
// Redis client configuration
func NewRedisClient(addr, password string) *redis.Client {
    return redis.NewClient(&redis.Options{
        Addr:     addr,
        Password: password,
        DB:       0,

        // Connection pool
        PoolSize:     100,
        MinIdleConns: 10,
        PoolTimeout:  30 * time.Second,

        // Timeouts
        DialTimeout:  5 * time.Second,
        ReadTimeout:  3 * time.Second,
        WriteTimeout: 3 * time.Second,

        // Retry
        MaxRetries:      3,
        MinRetryBackoff: 8 * time.Millisecond,
        MaxRetryBackoff: 512 * time.Millisecond,
    })
}

// Cluster configuration (production)
func NewRedisCluster(addrs []string, password string) *redis.ClusterClient {
    return redis.NewClusterClient(&redis.ClusterOptions{
        Addrs:        addrs,
        Password:     password,
        PoolSize:     100,
        MinIdleConns: 10,

        // Enable read from replicas
        ReadOnly:       true,
        RouteRandomly:  true,
    })
}
```

## Python Integration (Celery)

```python
# workers/src/config/celery.py
from celery import Celery

app = Celery('pareto_workers')

app.conf.update(
    broker_url='redis://localhost:6379/0',
    result_backend='redis://localhost:6379/0',

    # Task settings
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='Europe/Paris',
    enable_utc=True,

    # Routing
    task_routes={
        'workers.scraper.*': {'queue': 'scraper'},
        'workers.normalizer.*': {'queue': 'normalizer'},
        'workers.pareto.*': {'queue': 'pareto'},
    },

    # Rate limiting
    task_annotations={
        'workers.scraper.scrape_url': {
            'rate_limit': '10/m',
        },
    },
)

# Publish result back to Go API
@app.task(bind=True)
def scrape_url(self, url: str, retailer_id: str, proxy: str = None):
    # ... scraping logic ...

    # Publish result via Redis Pub/Sub
    import redis
    r = redis.Redis()
    r.publish('scrape_results', json.dumps({
        'task_id': self.request.id,
        'product_id': result.product_id,
        'price': result.price,
        'status': 'success',
    }))

    return result
```

## Docker Configuration

```yaml
# docker-compose.yml
services:
  redis:
    image: redis/redis-stack:latest
    container_name: pareto-redis
    ports:
      - "6379:6379"
      - "8001:8001"  # RedisInsight
    volumes:
      - redis_data:/data
    environment:
      - REDIS_ARGS=--appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  redis_data:
```

## Commands

```bash
# Connect
redis-cli

# Common operations
SET key value
GET key
DEL key
EXPIRE key 3600

# JSON operations
JSON.SET product:123 $ '{"name":"test"}'
JSON.GET product:123

# Pub/Sub
SUBSCRIBE channel
PUBLISH channel message

# Monitoring
INFO
MONITOR
CLIENT LIST

# Memory
MEMORY USAGE key
MEMORY DOCTOR
```

---

**See Also**:
- [PostgreSQL](./postgresql.md)
- [Go Redis](https://redis.uptrace.dev/)
- [Redis Docs](https://redis.io/docs/)
