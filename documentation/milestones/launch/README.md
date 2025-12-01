# Launch Initiative

> **MVP launch preparation and go-live**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                            LAUNCH INITIATIVE                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     ⏳ PENDING                                                       ║
║  Effort:     2 weeks (10 days)                                               ║
║  Depends:    All previous initiatives                                        ║
║  Unlocks:    🎉 MVP COMPLETE                                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Objective

Final preparations for MVP launch: production deployment, monitoring, testing, and go-live.

## Architecture (Production)

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRODUCTION SETUP                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                        [Internet]                               │
│                            │                                    │
│                     [Cloudflare]                                │
│                     (DNS, CDN, DDoS)                            │
│                            │                                    │
│                  [Cloudflare Tunnel]                            │
│                            │                                    │
│              ┌─────────────┴─────────────┐                      │
│              │        [Dokploy]          │                      │
│              │         Traefik           │                      │
│              │    (SSL, Load Balance)    │                      │
│              └─────────────┬─────────────┘                      │
│                            │                                    │
│      ┌─────────────────────┼─────────────────────┐              │
│      │                     │                     │              │
│   [Web]               [API]              [Workers]              │
│  Next.js 15         Go + Gin          Python Celery             │
│      │                     │                     │              │
│      └─────────────────────┼─────────────────────┘              │
│                            │                                    │
│              ┌─────────────┴─────────────┐                      │
│              │                           │                      │
│         [PostgreSQL]              [Redis]                       │
│         + TimescaleDB             (Cache + Queue)               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack (Production)

| Component | Service | Purpose |
|-----------|---------|---------|
| Hosting | Local PC + Dokploy | All services |
| Proxy | Traefik | SSL, routing |
| CDN | Cloudflare | Caching, DDoS |
| Tunnel | Cloudflare Tunnel | Secure ingress |
| Database | PostgreSQL 17 | Data storage |
| Time-series | TimescaleDB | Price history |
| Cache | Redis 7.4 | Caching, queue |
| Monitoring | Uptime Kuma | Health checks |
| Logs | Loki + Grafana | Log aggregation |

## Phases

| # | Phase | Effort | Description |
|---|-------|--------|-------------|
| 01 | [Production Deploy](./01-deploy.md) | 3d | Docker, Dokploy, HTTPS |
| 02 | [Monitoring](./02-monitoring.md) | 2d | Uptime, logs, alerts |
| 03 | [Testing](./03-testing.md) | 3d | E2E, load testing |
| 04 | [Go-Live](./04-go-live.md) | 2d | Launch checklist |

## Pre-Launch Checklist

### Infrastructure
- [ ] Dokploy configured on local PC
- [ ] Cloudflare Tunnel active
- [ ] SSL certificates (via Cloudflare)
- [ ] Domain pointing correctly
- [ ] Database backups configured

### Security
- [ ] Environment variables secured
- [ ] API rate limiting enabled
- [ ] CORS configured correctly
- [ ] SQL injection protection
- [ ] XSS protection headers

### Performance
- [ ] Database indexes optimized
- [ ] Redis caching active
- [ ] Next.js static generation
- [ ] Image optimization
- [ ] Gzip compression

### Legal
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] Cookie consent (GDPR)
- [ ] Affiliate disclosure

### Content
- [ ] >500 products scraped
- [ ] All 6 retailers working
- [ ] Price history > 7 days
- [ ] Homepage content ready

## Launch Milestones

```
Week 1: Production Setup
├── Day 1-2: Deploy to Dokploy
├── Day 3: Configure monitoring
├── Day 4-5: E2E testing
└── Day 6-7: Fix critical bugs

Week 2: Launch
├── Day 8: Final testing
├── Day 9: Soft launch (friends & family)
├── Day 10: 🚀 Public launch
└── Day 10+: Monitor and iterate
```

## Success Criteria

| Metric | Target |
|--------|--------|
| Products in DB | >500 |
| Scrape success rate | >85% |
| API response time | <200ms |
| Web Lighthouse | >90 |
| Uptime | >99% |
| First organic visitor | 1 |

## Rollback Plan

If critical issues arise:
1. Rollback to previous Docker image
2. Disable problematic features via config
3. Scale down scrapers if blocking occurs
4. Enable maintenance mode if needed

## Post-Launch

1. **Monitor** metrics and errors
2. **Respond** to user feedback
3. **Fix** bugs quickly
4. **Iterate** based on data
5. **Apply** for affiliate programs (once traffic)

---

**Depends on**: All previous initiatives
**Result**: 🎉 MVP COMPLETE
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
