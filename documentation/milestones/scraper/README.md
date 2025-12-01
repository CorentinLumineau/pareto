# Scraper Initiative

> **Reliable web scraping for 6 French retailers with anti-bot bypass**

```
╔════════════════════════════════════════════════════════════════╗
║  Initiative: SCRAPER                                            ║
║  Status:     ⏳ PENDING                                         ║
║  Priority:   P0 - Critical                                      ║
║  Effort:     3-4 weeks                                          ║
║  Depends:    Foundation                                         ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Build reliable scraping infrastructure for 6 French retailers:
- Amazon.fr, Fnac.com, Cdiscount.com
- Darty.com, Boulanger.com, LDLC.com

## Milestones

| # | Milestone | Effort | Status | File |
|---|-----------|--------|--------|------|
| M1 | Scraper Skeleton (Go) | 3 days | ⏳ | [01-skeleton.md](./01-skeleton.md) |
| M2 | Anti-Bot Bypass (Python) | 5 days | ⏳ | [02-antibot.md](./02-antibot.md) |
| M3 | Job Queue System | 3 days | ⏳ | [03-queue.md](./03-queue.md) |
| M4 | First 3 Retailers | 5 days | ⏳ | [04-retailers-1.md](./04-retailers-1.md) |
| M5 | Additional 3 Retailers | 5 days | ⏳ | [05-retailers-2.md](./05-retailers-2.md) |

## Progress: 0%

```
M1 Skeleton   [░░░░░░░░░░]   0%
M2 Anti-Bot   [░░░░░░░░░░]   0%
M3 Queue      [░░░░░░░░░░]   0%
M4 Retail 1-3 [░░░░░░░░░░]   0%
M5 Retail 4-6 [░░░░░░░░░░]   0%
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    apps/api/internal/scraper/                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   [Scheduler] ──▶ [Job Queue (Redis)]                       │
│                          │                                   │
│                          ▼                                   │
│   [Go Orchestrator] ──▶ [Python Fetcher (curl_cffi)]        │
│                          │                                   │
│                          ▼                                   │
│                    [Raw HTML Store]                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Key Technical Decisions

- **Go** for orchestration (job management, retries)
- **Python** for fetching (curl_cffi anti-bot bypass)
- **Redis** for job queue
- **Direct imports** between Go modules

## Success Criteria

- [ ] 6 retailers scraping
- [ ] >85% success rate per retailer
- [ ] <5% duplicate detection
- [ ] Retry logic with backoff
- [ ] Dead letter queue for failures

---

**Previous**: [Foundation](../foundation/)
**Next**: [Normalizer](../normalizer/)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
