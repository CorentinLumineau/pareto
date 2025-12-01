# Phase 01: Scraper Skeleton

> **Go module with interfaces and domain entities**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      01 - Skeleton                                      ║
║  Initiative: Scraper                                            ║
║  Status:     ⏳ PENDING                                         ║
║  Effort:     3 days                                             ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Create the Go module skeleton with interfaces for scraping.

## Tasks

- [ ] Create `apps/api/internal/scraper/` module
- [ ] Define interfaces
- [ ] Implement domain entities
- [ ] Create Dockerfile
- [ ] Write unit tests

## Interfaces

```go
// apps/api/internal/scraper/interfaces.go

type RetailerScraper interface {
    Scrape(ctx context.Context, url string) (*ScrapeResult, error)
    CanHandle(url string) bool
    GetRetailerID() string
}

type ProxyProvider interface {
    GetProxy(ctx context.Context, retailer string) (*Proxy, error)
    ReportSuccess(proxy *Proxy)
    ReportFailure(proxy *Proxy, err error)
}

type JobRepository interface {
    Enqueue(ctx context.Context, job *Job) error
    Dequeue(ctx context.Context) (*Job, error)
    Complete(ctx context.Context, jobID string, result *ScrapeResult) error
    Fail(ctx context.Context, jobID string, err error) error
}
```

## Domain Entities

```go
// apps/api/internal/scraper/entities.go

type Job struct {
    ID         string
    URL        string
    RetailerID string
    Priority   int
    Attempts   int
    MaxRetries int
    Status     JobStatus
    CreatedAt  time.Time
}

type ScrapeResult struct {
    JobID     string
    URL       string
    HTML      string
    Status    int
    Headers   map[string]string
    ScrapedAt time.Time
}
```

## Deliverables

- [ ] Go module compiles
- [ ] Interfaces defined
- [ ] Entities with validation
- [ ] Unit tests >80% coverage

---

**Next Phase**: [02-antibot.md](./02-antibot.md)
**Back to**: [Scraper README](./README.md)
