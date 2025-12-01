# Scraper Module Specification

## Go-based Web Scraping with Anti-Bot Bypass

---

## Module Overview

| Aspect             | Detail                                                                |
| ------------------ | --------------------------------------------------------------------- |
| **Language**       | Go (orchestration) + Python (curl_cffi for complex sites)             |
| **Location**       | `internal/scraper/`                                                   |
| **Responsibility** | Fetch raw HTML from French retailers, manage proxies, handle anti-bot |
| **Dependencies**   | Redis (job queue), PostgreSQL (job status)                            |

---

## Architecture

```mermaid
flowchart TB
    subgraph ScraperModule["Scraper Module"]
        direction TB

        subgraph Domain["Domain Layer"]
            Job[Job Entity]
            Retailer[Retailer Entity]
            Result[ScrapeResult Entity]
        end

        subgraph Service["Service Layer"]
            Orchestrator[Orchestrator Service]
            ProxyManager[Proxy Manager]
            RetryHandler[Retry Handler]
        end

        subgraph Adapters["Adapter Layer"]
            direction LR
            AmazonAdapter[Amazon Adapter\ncurl_cffi + chrome136]
            FnacAdapter[Fnac Adapter\ncurl_cffi]
            CdiscountAdapter[Cdiscount Adapter\ncurl_cffi + rotating FP]
            SimpleAdapter[Simple Adapter\nColly/net-http]
        end

        subgraph Ports["Port Interfaces"]
            IRetailerScraper[IRetailerScraper]
            IProxyProvider[IProxyProvider]
            IJobRepository[IJobRepository]
        end
    end

    subgraph External["External"]
        Redis[(Redis Queue)]
        Proxy[(Proxy Provider\nIPRoyal)]
        Sites[(Retailer Sites)]
    end

    Orchestrator --> IRetailerScraper
    IRetailerScraper --> AmazonAdapter
    IRetailerScraper --> FnacAdapter
    IRetailerScraper --> CdiscountAdapter
    IRetailerScraper --> SimpleAdapter

    ProxyManager --> IProxyProvider
    IProxyProvider --> Proxy

    Orchestrator --> IJobRepository
    IJobRepository --> Redis

    AmazonAdapter --> Sites
    FnacAdapter --> Sites
    CdiscountAdapter --> Sites
    SimpleAdapter --> Sites
```

---

## Milestones

### S1-M1: Scraper Skeleton (3 days)

**Goal**: Basic Go module structure with interfaces defined

```mermaid
flowchart LR
    Start([Start]) --> Define[Define Interfaces]
    Define --> Implement[Implement Skeleton]
    Implement --> Docker[Dockerize]
    Docker --> Test[Health Check]
    Test --> Done([Done])
```

**Deliverables**:

- [ ] `internal/scraper/domain/` entities
- [ ] `internal/scraper/ports/` interfaces
- [ ] `internal/scraper/service/orchestrator.go` skeleton
- [ ] Dockerfile with health check
- [ ] Unit tests for domain entities

**Interface Definitions**:

```go
// internal/scraper/ports/scraper.go
package ports

import "context"

type ScrapeRequest struct {
    URL        string
    RetailerID string
    Priority   int
    Metadata   map[string]string
}

type ScrapeResult struct {
    URL         string
    HTML        []byte
    StatusCode  int
    ScrapedAt   time.Time
    RetailerID  string
    Error       error
}

type IRetailerScraper interface {
    // Scrape fetches a single URL
    Scrape(ctx context.Context, req ScrapeRequest) (*ScrapeResult, error)

    // SupportedRetailer returns the retailer ID this scraper handles
    SupportedRetailer() string

    // CanHandle checks if this scraper can handle the URL
    CanHandle(url string) bool
}
```

```go
// internal/scraper/ports/proxy.go
package ports

type Proxy struct {
    URL      string
    Type     string // "residential", "datacenter"
    Country  string
    LastUsed time.Time
    Failures int
}

type IProxyProvider interface {
    // GetProxy returns a proxy suitable for the retailer
    GetProxy(ctx context.Context, retailerID string) (*Proxy, error)

    // MarkFailed records a proxy failure
    MarkFailed(ctx context.Context, proxy *Proxy) error

    // Release returns proxy to pool
    Release(ctx context.Context, proxy *Proxy) error
}
```

```go
// internal/scraper/ports/job.go
package ports

type JobStatus string

const (
    JobPending   JobStatus = "pending"
    JobRunning   JobStatus = "running"
    JobCompleted JobStatus = "completed"
    JobFailed    JobStatus = "failed"
)

type Job struct {
    ID         string
    RetailerID string
    URLs       []string
    Status     JobStatus
    Priority   int
    CreatedAt  time.Time
    StartedAt  *time.Time
    FinishedAt *time.Time
    Error      string
}

type IJobRepository interface {
    Enqueue(ctx context.Context, job *Job) error
    Dequeue(ctx context.Context) (*Job, error)
    UpdateStatus(ctx context.Context, jobID string, status JobStatus, err string) error
    GetJob(ctx context.Context, jobID string) (*Job, error)
}
```

---

### S1-M2: Anti-Bot Bypass (5 days)

**Goal**: Successfully scrape DataDome-protected sites

```mermaid
flowchart TB
    subgraph Detection["Anti-Bot Detection Methods"]
        TLS[TLS Fingerprinting]
        HTTP2[HTTP/2 Frame Order]
        JS[JavaScript Challenges]
        Behavior[Behavioral Analysis]
    end

    subgraph Bypass["Bypass Strategies"]
        curl_cffi[curl_cffi\nchrome136 impersonation]
        Residential[Residential Proxies\nFrench IPs]
        Delays[Human-like Delays\n2-5 seconds]
        Rotation[Fingerprint Rotation]
    end

    TLS --> curl_cffi
    HTTP2 --> curl_cffi
    JS --> Residential
    Behavior --> Delays
    Behavior --> Rotation
```

**Python Worker for Complex Sites** (`workers/src/fetcher/fetcher.py`):

```python
"""
Anti-bot bypass fetcher using curl_cffi
"""
from curl_cffi import requests
from curl_cffi.requests import AsyncSession
import asyncio
import random
from typing import Optional
from dataclasses import dataclass
import time

@dataclass
class FetchResult:
    url: str
    html: bytes
    status_code: int
    retailer_id: str
    scraped_at: float
    error: Optional[str] = None

class RetailerFetcher:
    """Fetcher with retailer-specific anti-bot configurations"""

    RETAILER_CONFIGS = {
        "amazon": {
            "impersonate": "chrome136",
            "min_delay": 3.0,
            "max_delay": 5.0,
            "needs_residential": True,
        },
        "fnac": {
            "impersonate": "chrome136",
            "min_delay": 2.0,
            "max_delay": 4.0,
            "needs_residential": True,
        },
        "cdiscount": {
            "impersonate": "chrome136",  # Rotate fingerprints
            "min_delay": 2.0,
            "max_delay": 3.0,
            "needs_residential": True,
            "rotate_fingerprint": True,
        },
        "darty": {
            "impersonate": "chrome120",
            "min_delay": 1.5,
            "max_delay": 3.0,
            "needs_residential": False,
        },
        "boulanger": {
            "impersonate": "chrome120",
            "min_delay": 1.5,
            "max_delay": 3.0,
            "needs_residential": False,
        },
        "ldlc": {
            "impersonate": "chrome120",
            "min_delay": 1.0,
            "max_delay": 2.0,
            "needs_residential": False,
        },
    }

    FINGERPRINTS = ["chrome120", "chrome124", "chrome131", "chrome136"]

    def __init__(self, proxy_url: str):
        self.proxy = {"https": proxy_url, "http": proxy_url}
        self._last_request_time: dict[str, float] = {}

    async def fetch(self, url: str, retailer_id: str) -> FetchResult:
        """Fetch URL with retailer-specific anti-bot handling"""
        config = self.RETAILER_CONFIGS.get(retailer_id, self.RETAILER_CONFIGS["ldlc"])

        # Enforce delay between requests to same retailer
        await self._enforce_delay(retailer_id, config)

        # Select fingerprint
        fingerprint = config["impersonate"]
        if config.get("rotate_fingerprint"):
            fingerprint = random.choice(self.FINGERPRINTS)

        try:
            async with AsyncSession() as session:
                response = await session.get(
                    url,
                    impersonate=fingerprint,
                    proxies=self.proxy if config["needs_residential"] else None,
                    timeout=30,
                    headers=self._get_headers(retailer_id),
                )

                self._last_request_time[retailer_id] = time.time()

                if response.status_code == 200:
                    return FetchResult(
                        url=url,
                        html=response.content,
                        status_code=response.status_code,
                        retailer_id=retailer_id,
                        scraped_at=time.time(),
                    )
                else:
                    return FetchResult(
                        url=url,
                        html=b"",
                        status_code=response.status_code,
                        retailer_id=retailer_id,
                        scraped_at=time.time(),
                        error=f"HTTP {response.status_code}",
                    )

        except Exception as e:
            return FetchResult(
                url=url,
                html=b"",
                status_code=0,
                retailer_id=retailer_id,
                scraped_at=time.time(),
                error=str(e),
            )

    async def _enforce_delay(self, retailer_id: str, config: dict):
        """Ensure minimum delay between requests to same retailer"""
        last_time = self._last_request_time.get(retailer_id, 0)
        elapsed = time.time() - last_time
        min_delay = config["min_delay"]
        max_delay = config["max_delay"]

        required_delay = random.uniform(min_delay, max_delay)
        if elapsed < required_delay:
            await asyncio.sleep(required_delay - elapsed)

    def _get_headers(self, retailer_id: str) -> dict:
        """Get retailer-specific headers"""
        base_headers = {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7",
            "Accept-Encoding": "gzip, deflate, br",
            "DNT": "1",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
        }

        # Add retailer-specific headers if needed
        if retailer_id == "amazon":
            base_headers["Accept-Language"] = "fr-FR,fr;q=0.9"

        return base_headers
```

**Deliverables**:

- [ ] curl_cffi fetcher with fingerprint impersonation
- [ ] Retailer-specific configurations
- [ ] Delay enforcement between requests
- [ ] Integration tests against live sites (manual verification)
- [ ] Success rate monitoring

**Success Criteria**:

- Amazon.fr: >90% success rate
- Fnac.com: >90% success rate
- Cdiscount.com: >85% success rate

---

### S1-M3: Job Queue System (3 days)

**Goal**: Reliable job queuing with retries

```mermaid
sequenceDiagram
    participant API as API Handler
    participant Orch as Orchestrator
    participant Redis as Redis Queue
    participant Worker as Python Worker
    participant Store as Result Store

    API->>Orch: Queue scrape job
    Orch->>Redis: LPUSH job:pending
    Orch-->>API: Job ID

    loop Process Jobs
        Worker->>Redis: BRPOPLPUSH job:pending job:processing
        Worker->>Worker: Fetch URL
        alt Success
            Worker->>Store: Store HTML
            Worker->>Redis: LREM job:processing
        else Failure (retryable)
            Worker->>Redis: LPUSH job:pending (with backoff)
        else Failure (permanent)
            Worker->>Redis: LPUSH job:failed
        end
    end
```

**Job Queue Implementation** (`internal/scraper/adapters/redis_job.go`):

```go
package adapters

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/redis/go-redis/v9"
    "comparateur/internal/scraper/ports"
)

type RedisJobRepository struct {
    client *redis.Client
    prefix string
}

func NewRedisJobRepository(client *redis.Client) *RedisJobRepository {
    return &RedisJobRepository{
        client: client,
        prefix: "scraper:job:",
    }
}

func (r *RedisJobRepository) Enqueue(ctx context.Context, job *ports.Job) error {
    data, err := json.Marshal(job)
    if err != nil {
        return fmt.Errorf("marshal job: %w", err)
    }

    // Use sorted set for priority queue
    score := float64(job.Priority)*1e12 + float64(job.CreatedAt.UnixNano())

    return r.client.ZAdd(ctx, r.prefix+"pending", redis.Z{
        Score:  score,
        Member: data,
    }).Err()
}

func (r *RedisJobRepository) Dequeue(ctx context.Context) (*ports.Job, error) {
    // Pop highest priority (lowest score)
    results, err := r.client.ZPopMin(ctx, r.prefix+"pending", 1).Result()
    if err != nil {
        return nil, err
    }
    if len(results) == 0 {
        return nil, nil // No jobs available
    }

    var job ports.Job
    if err := json.Unmarshal([]byte(results[0].Member.(string)), &job); err != nil {
        return nil, fmt.Errorf("unmarshal job: %w", err)
    }

    // Mark as processing
    job.Status = ports.JobRunning
    now := time.Now()
    job.StartedAt = &now

    data, _ := json.Marshal(job)
    r.client.HSet(ctx, r.prefix+"processing", job.ID, data)

    return &job, nil
}

func (r *RedisJobRepository) UpdateStatus(ctx context.Context, jobID string, status ports.JobStatus, errMsg string) error {
    // Get job from processing
    data, err := r.client.HGet(ctx, r.prefix+"processing", jobID).Result()
    if err != nil {
        return err
    }

    var job ports.Job
    json.Unmarshal([]byte(data), &job)

    job.Status = status
    job.Error = errMsg
    now := time.Now()
    job.FinishedAt = &now

    // Move to appropriate set
    r.client.HDel(ctx, r.prefix+"processing", jobID)

    updatedData, _ := json.Marshal(job)
    switch status {
    case ports.JobCompleted:
        r.client.HSet(ctx, r.prefix+"completed", jobID, updatedData)
    case ports.JobFailed:
        r.client.HSet(ctx, r.prefix+"failed", jobID, updatedData)
    }

    return nil
}

func (r *RedisJobRepository) GetJob(ctx context.Context, jobID string) (*ports.Job, error) {
    // Check all possible locations
    for _, key := range []string{"processing", "completed", "failed"} {
        data, err := r.client.HGet(ctx, r.prefix+key, jobID).Result()
        if err == nil {
            var job ports.Job
            json.Unmarshal([]byte(data), &job)
            return &job, nil
        }
    }
    return nil, fmt.Errorf("job not found: %s", jobID)
}
```

**Deliverables**:

- [ ] Redis job queue with priority support
- [ ] Retry logic with exponential backoff
- [ ] Dead letter queue for permanent failures
- [ ] Job status API endpoints
- [ ] Integration tests

---

### S1-M4: First 3 Retailers (5 days)

**Goal**: Working scrapers for Amazon, Fnac, Cdiscount

```mermaid
flowchart TB
    subgraph Amazon["Amazon.fr"]
        A1[Product Page] --> A2[Extract: Title, Price, ASIN]
        A2 --> A3[Handle: Variants, Stock]
    end

    subgraph Fnac["Fnac.com"]
        F1[Product Page] --> F2[Extract: Title, Price, EAN]
        F2 --> F3[Handle: Marketplace offers]
    end

    subgraph Cdiscount["Cdiscount.com"]
        C1[Product Page] --> C2[Extract: Title, Price, SKU]
        C2 --> C3[Handle: Flash sales]
    end
```

**Retailer URL Patterns**:

| Retailer  | Product URL Pattern                    | Example                                  |
| --------- | -------------------------------------- | ---------------------------------------- |
| Amazon.fr | `amazon.fr/dp/{ASIN}`                  | `amazon.fr/dp/B0CHX3QBCH`                |
| Fnac.com  | `fnac.com/{slug}/a{product_id}`        | `fnac.com/Casque/a12345`                 |
| Cdiscount | `cdiscount.com/{category}/{slug}.html` | `cdiscount.com/informatique/casque.html` |

**Deliverables**:

- [ ] Amazon adapter with ASIN extraction
- [ ] Fnac adapter with marketplace handling
- [ ] Cdiscount adapter with flash sale detection
- [ ] URL pattern matching for each retailer
- [ ] Success rate >90% on sample URLs

---

### S1-M5: Additional 3 Retailers (5 days)

**Goal**: Add Darty, Boulanger, LDLC

| Retailer  | Protection Level    | Strategy           |
| --------- | ------------------- | ------------------ |
| Darty     | Medium (Cloudflare) | Standard curl_cffi |
| Boulanger | Medium (Cloudflare) | Standard curl_cffi |
| LDLC      | Low                 | Simple Go Colly    |

**Deliverables**:

- [ ] Darty adapter
- [ ] Boulanger adapter
- [ ] LDLC adapter (Go native)
- [ ] All 6 retailers integrated
- [ ] End-to-end test: queue job → fetch → store HTML

---

## Proxy Management

```mermaid
flowchart TB
    subgraph ProxyPool["Proxy Pool Manager"]
        direction TB
        Config[Configuration]
        Health[Health Checker]
        Rotation[Rotation Logic]
    end

    subgraph Providers["Proxy Providers"]
        IPRoyal[IPRoyal\nResidential FR]
        Datacenter[Datacenter\nBackup]
    end

    subgraph Assignment["Assignment Logic"]
        Amazon[Amazon → Residential]
        Fnac[Fnac → Residential]
        Cdiscount[Cdiscount → Residential]
        Others[Others → Datacenter OK]
    end

    Config --> Providers
    Health --> Rotation
    Rotation --> Assignment
```

**Configuration** (`config/scraper.yaml`):

```yaml
proxy:
  providers:
    residential:
      url: "http://user:pass@proxy.iproyal.com:12321"
      type: "residential"
      country: "FR"
      max_concurrent: 10
      cost_per_gb: 7.0

    datacenter:
      url: "http://user:pass@dc-proxy.example.com:8080"
      type: "datacenter"
      max_concurrent: 50
      cost_per_gb: 0.5

retailers:
  amazon:
    proxy_type: "residential"
    rate_limit_per_minute: 12

  fnac:
    proxy_type: "residential"
    rate_limit_per_minute: 15

  cdiscount:
    proxy_type: "residential"
    rate_limit_per_minute: 20

  ldlc:
    proxy_type: "datacenter"
    rate_limit_per_minute: 30
```

---

## Error Handling Strategy

```mermaid
flowchart TB
    Error[Error Occurred] --> Classify{Classify Error}

    Classify -->|Blocked/403/503| Blocked[Anti-Bot Block]
    Classify -->|Timeout| Timeout[Network Timeout]
    Classify -->|404| NotFound[Page Not Found]
    Classify -->|5xx| ServerError[Server Error]
    Classify -->|Parse Error| ParseError[Invalid HTML]

    Blocked --> RotateProxy[Rotate Proxy]
    RotateProxy --> Retry{Retry < 3?}

    Timeout --> Retry
    ServerError --> Retry

    NotFound --> MarkInvalid[Mark URL Invalid]
    ParseError --> StoreRaw[Store Raw for Debug]

    Retry -->|Yes| Backoff[Exponential Backoff]
    Backoff --> Fetch[Retry Fetch]

    Retry -->|No| Fail[Mark Job Failed]
```

---

## Monitoring & Alerts

**Key Metrics** (Prometheus format):

```
# Success rate per retailer
scraper_requests_total{retailer="amazon", status="success"} 1234
scraper_requests_total{retailer="amazon", status="blocked"} 12
scraper_requests_total{retailer="amazon", status="error"} 5

# Latency histogram
scraper_request_duration_seconds_bucket{retailer="amazon", le="1"} 100
scraper_request_duration_seconds_bucket{retailer="amazon", le="5"} 150

# Proxy usage
scraper_proxy_usage_bytes{provider="iproyal"} 5368709120

# Queue depth
scraper_job_queue_depth{status="pending"} 45
scraper_job_queue_depth{status="processing"} 3
```

**Alerts**:

| Alert           | Condition          | Severity |
| --------------- | ------------------ | -------- |
| High Block Rate | >20% blocked in 1h | Critical |
| Queue Backlog   | >100 pending jobs  | Warning  |
| Proxy Exhausted | 0 healthy proxies  | Critical |
| Slow Scraping   | P95 latency >10s   | Warning  |

---

## Testing Strategy

```mermaid
flowchart LR
    subgraph Unit["Unit Tests"]
        Domain[Domain Entity Tests]
        Service[Service Logic Tests]
        Mock[Mocked Adapters]
    end

    subgraph Integration["Integration Tests"]
        Redis[Redis Queue Tests]
        RealFetch[Real Fetch Tests\nManual/Nightly]
    end

    subgraph E2E["E2E Tests"]
        FullPipeline[Queue → Fetch → Store]
    end

    Unit --> Integration --> E2E
```

**Test Commands**:

```bash
# Unit tests (fast, run on every commit)
make test-unit

# Integration tests (requires Redis)
make test-integration

# E2E with real sites (manual, costs proxy $)
make test-e2e-live RETAILER=amazon
```

---

## Definition of Done

- [ ] All 6 retailers scraping with >85% success rate
- [ ] Job queue handles 1000+ URLs/hour
- [ ] Proxy rotation working with cost tracking
- [ ] Retry logic handles transient failures
- [ ] Metrics exposed for monitoring
- [ ] Error classification and logging
- [ ] Docker container with health check
- [ ] CI pipeline passing

---

_Module Owner: Dev_  
_Last Updated: Week 0_  
_Estimated Effort: 21 days_
