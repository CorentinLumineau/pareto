# Milestones - Master Plan & Roadmap

> **The single source of truth for MVP development progress**

## Project Status

```
═══════════════════════════════════════════════════════════════
  PARETO COMPARATOR - MVP ROADMAP
═══════════════════════════════════════════════════════════════

  Status:        PRE-MVP
  Current:       M0 - Foundation (Repository Setup)
  Target:        MVP Launch (Smartphones - France)
  Developer:     Solo (@clumineau)
  Budget:        <30EUR/month

═══════════════════════════════════════════════════════════════
```

## Vision

Build the **best product comparison platform in France** using Pareto optimization to help users find optimal trade-offs, not just the cheapest price.

**MVP Goal**: Validate the concept with **smartphones** from 6 French retailers.

---

## Master Timeline

```
Week  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16
      |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
M0    [=]                                                           Foundation
M1        [=======]                                                 Scraper
M2                [=====]                                           Normalizer
M3                      [=====]                                     Catalog
M4                            [===]                                 Comparison
M5                                [==]                              Affiliate
M6                                    [===========]                 Frontend
M7                                                [=====]           Launch
```

**Estimated Total**: 14-16 weeks

---

## Initiative Overview

| ID | Initiative | Effort | Priority | Status | Dependencies |
|----|------------|--------|----------|--------|--------------|
| **M0** | [Foundation](./initiatives/M0-foundation/) | 1 day | P0 | ⏳ Next | None |
| **M1** | [Scraper Module](./initiatives/M1-scraper/) | 3-4 weeks | P0 | ⏳ Pending | M0 |
| **M2** | [Normalizer Module](./initiatives/M2-normalizer/) | 2 weeks | P0 | ⏳ Pending | M1 |
| **M3** | [Catalog Module](./initiatives/M3-catalog/) | 2 weeks | P0 | ⏳ Pending | M2 |
| **M4** | [Comparison Engine](./initiatives/M4-comparison/) | 1.5 weeks | P0 | ⏳ Pending | M3 |
| **M5** | [Affiliate Module](./initiatives/M5-affiliate/) | 1 week | P1 | ⏳ Pending | M3 |
| **M6** | [Frontend](./initiatives/M6-frontend/) | 4 weeks | P0 | ⏳ Pending | M3, M4, M5 |
| **M7** | [Launch Prep](./initiatives/M7-launch/) | 2 weeks | P0 | ⏳ Pending | All |

---

## Current Focus: M0 Foundation

### Active Tasks

```markdown
Phase 2: Repository Setup (1 day)
- [ ] Create GitHub repository structure
- [ ] Setup monorepo (Go + Python + Next.js)
- [ ] Configure linting and pre-commit hooks
- [ ] Setup CI/CD pipeline (GitHub Actions)
- [ ] Create Dockerfiles and docker-compose.yml
```

### Completed

```markdown
Phase 1: Infrastructure Setup ✅
- [x] Local PC with Dokploy installed
- [x] Domain registered with Cloudflare tunneling
- [x] Database containers ready

Phase 3: Legal Setup (Deferred)
- [ ] SASU registration (after MVP validation)
```

---

## Initiative Details

### M0: Foundation (1 day remaining)

**Goal**: Development environment ready

| Phase | Description | Effort | Status |
|-------|-------------|--------|--------|
| P1 | Infrastructure | - | ✅ Done (local) |
| P2 | Repository Setup | 1 day | ⏳ Active |
| P3 | Legal Setup | - | ⏳ Deferred |

**Next Action**: Create monorepo structure

→ [View M0 Details](./initiatives/M0-foundation/)

---

### M1: Scraper Module (3-4 weeks)

**Goal**: Reliable scraping for 6 French retailers

| Phase | Description | Effort | Status |
|-------|-------------|--------|--------|
| P1 | Scraper Skeleton (Go) | 3 days | ⏳ Pending |
| P2 | Anti-Bot Bypass (Python) | 5 days | ⏳ Pending |
| P3 | Job Queue System | 3 days | ⏳ Pending |
| P4 | First 3 Retailers | 5 days | ⏳ Pending |
| P5 | Additional 3 Retailers | 5 days | ⏳ Pending |

**Success Criteria**: >85% scrape success rate

→ [View M1 Details](./initiatives/M1-scraper/)

---

### M2: Normalizer Module (2 weeks)

**Goal**: Parse HTML, extract structured data, match products

| Phase | Description | Effort | Status |
|-------|-------------|--------|--------|
| P1 | Parser Core (Celery) | 3 days | ⏳ Pending |
| P2 | Retailer Extractors | 5 days | ⏳ Pending |
| P3 | Validation Schema | 2 days | ⏳ Pending |
| P4 | Entity Resolution | 3 days | ⏳ Pending |

**Success Criteria**: >90% extraction accuracy, >85% match accuracy

→ [View M2 Details](./initiatives/M2-normalizer/)

---

### M3: Catalog Module (2 weeks)

**Goal**: Product database with REST API and search

| Phase | Description | Effort | Status |
|-------|-------------|--------|--------|
| P1 | CRUD API | 4 days | ⏳ Pending |
| P2 | Product Matching | 3 days | ⏳ Pending |
| P3 | Category System | 2 days | ⏳ Pending |
| P4 | Search (French) | 3 days | ⏳ Pending |

**Success Criteria**: <200ms API response, French search working

→ [View M3 Details](./initiatives/M3-catalog/)

---

### M4: Comparison Engine (1.5 weeks)

**Goal**: Pareto optimization and ranking - THE DIFFERENTIATOR

| Phase | Description | Effort | Status |
|-------|-------------|--------|--------|
| P1 | Pareto Algorithm | 3 days | ⏳ Pending |
| P2 | Ranking API | 2 days | ⏳ Pending |
| P3 | Caching Strategy | 2 days | ⏳ Pending |

**Success Criteria**: <200ms cached response, correct Pareto frontier

→ [View M4 Details](./initiatives/M4-comparison/)

---

### M5: Affiliate Module (1 week)

**Goal**: Revenue generation via affiliate links

| Phase | Description | Effort | Status |
|-------|-------------|--------|--------|
| P1 | Affiliate Link Generators | 3 days | ⏳ Pending |
| P2 | GDPR-Compliant Tracking | 2 days | ⏳ Pending |

**Success Criteria**: Links generating, clicks tracked, no raw IPs

→ [View M5 Details](./initiatives/M5-affiliate/)

---

### M6: Frontend (4 weeks)

**Goal**: SEO-optimized comparison UI

| Phase | Description | Effort | Status |
|-------|-------------|--------|--------|
| P1 | Core Pages | 5 days | ⏳ Pending |
| P2 | Comparison UI (Pareto Chart) | 5 days | ⏳ Pending |
| P3 | SEO & Legal | 3 days | ⏳ Pending |

**Success Criteria**: Lighthouse >90, mobile responsive, Schema.org valid

→ [View M6 Details](./initiatives/M6-frontend/)

---

### M7: Launch Prep (2 weeks)

**Goal**: Testing, polish, go live

| Phase | Description | Effort | Status |
|-------|-------------|--------|--------|
| P1 | Integration Testing | 3 days | ⏳ Pending |
| P2 | Bug Fixes | 3 days | ⏳ Pending |
| P3 | Soft Launch | 2 days | ⏳ Pending |
| P4 | SEO Submission | 1 day | ⏳ Pending |

**Success Criteria**: Site live, no critical bugs, indexing started

→ [View M7 Details](./initiatives/M7-launch/)

---

## Dependency Graph

```
M0: Foundation
    │
    ▼
M1: Scraper ──────────────────┐
    │                         │
    ▼                         │
M2: Normalizer                │
    │                         │
    ▼                         │
M3: Catalog ◄─────────────────┤
    │                         │
    ├──────────┐              │
    ▼          ▼              ▼
M4: Compare  M5: Affiliate    │
    │          │              │
    └────┬─────┘              │
         ▼                    │
    M6: Frontend ◄────────────┘
         │
         ▼
    M7: Launch
         │
         ▼
    🎉 MVP COMPLETE
```

---

## Progress Tracking

### Overall Progress: 0%

```
M0 Foundation    [▓░░░░░░░░░]  10%  (infra done, repo pending)
M1 Scraper       [░░░░░░░░░░]   0%
M2 Normalizer    [░░░░░░░░░░]   0%
M3 Catalog       [░░░░░░░░░░]   0%
M4 Comparison    [░░░░░░░░░░]   0%
M5 Affiliate     [░░░░░░░░░░]   0%
M6 Frontend      [░░░░░░░░░░]   0%
M7 Launch        [░░░░░░░░░░]   0%
────────────────────────────────
TOTAL            [░░░░░░░░░░]   0%
```

### Metrics Target

| Metric | Target | Current |
|--------|--------|---------|
| Products in DB | >500 | 0 |
| Scrape success rate | >85% | - |
| API response time | <200ms | - |
| Lighthouse score | >90 | - |
| First organic visitor | 1 | 0 |

---

## Risk Register

| Risk | Probability | Impact | Mitigation | Status |
|------|-------------|--------|------------|--------|
| Anti-bot blocks | High | High | Multiple fingerprints, proxies | Monitoring |
| Affiliate rejection | Medium | Medium | Build traffic first, backup networks | Planned |
| Scope creep | High | Medium | Strict YAGNI, single category (smartphones) | Active |
| Solo dev burnout | Medium | High | Realistic pace, defer non-essential | Active |

---

## Budget

| Item | Monthly Cost | Status |
|------|--------------|--------|
| VPS (local PC) | 0EUR | ✅ Using local |
| Domain | ~1EUR/month | ✅ Already owned |
| Proxies | 0-15EUR | ⏳ When needed |
| Affiliate apps | 0EUR | ⏳ After traffic |
| **Total** | **<20EUR** | ✅ Under budget |

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-12-01 | Single category (smartphones) | Focus for MVP validation |
| 2025-12-01 | Local hosting initially | Budget, already have Dokploy |
| 2025-12-01 | Defer legal entity | Validate business first |
| 2025-12-01 | Defer affiliate applications | Need traffic first |

---

## Post-MVP Roadmap

After successful MVP validation:

1. **v1.1 - More Categories**: Laptops, tablets, headphones
2. **v1.2 - User Accounts**: Saved comparisons, price alerts
3. **v2.0 - Scale**: VPS migration, more retailers
4. **v3.0 - International**: Germany, UK expansion

---

## Quick Commands

```bash
# View current initiative
cat documentation/milestones/initiatives/M0-foundation/README.md

# Check progress
grep -r "Status" documentation/milestones/initiatives/*/README.md

# Start development
make dev

# Run tests
make test
```

---

**Last Updated**: 2025-12-01
**Next Review**: After M0 completion
