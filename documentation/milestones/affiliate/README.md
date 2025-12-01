# Affiliate Initiative

> **Revenue generation through affiliate link tracking**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                           AFFILIATE INITIATIVE                                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     ⏳ PENDING                                                       ║
║  Effort:     1 week (5 days)                                                 ║
║  Depends:    Catalog                                                         ║
║  Unlocks:    Frontend                                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Objective

Implement affiliate link generation and click tracking for revenue monetization. Each retailer has different affiliate programs that we'll integrate.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     AFFILIATE MODULE                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   User Click ─────► Redirect ─────► Retailer                    │
│       │              Service          Site                      │
│       │                │                                        │
│       ▼                ▼                                        │
│   Click Log       URL Builder                                   │
│   (analytics)     (per network)                                 │
│                                                                 │
│   Networks:                                                     │
│   ├── Amazon Associates                                         │
│   ├── Awin (Fnac, Darty, Boulanger)                            │
│   └── Effinity (Cdiscount)                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| API | Go + Gin | Link generation, redirects |
| Database | PostgreSQL | Click tracking |
| Analytics | TimescaleDB | Click time-series |

## Phases

| # | Phase | Effort | Description |
|---|-------|--------|-------------|
| 01 | [Link Generator](./01-link-generator.md) | 2d | URL building per network |
| 02 | [Click Tracking](./02-click-tracking.md) | 2d | Analytics and logging |
| 03 | [Revenue Reports](./03-revenue-reports.md) | 1d | Dashboard data |

## Affiliate Networks

| Retailer | Network | Commission | Cookie |
|----------|---------|------------|--------|
| Amazon.fr | Amazon Associates | 1-10% | 24h |
| Fnac.com | Awin | 2-4% | 30d |
| Cdiscount | Effinity | 2-3% | 30d |
| Darty.com | Awin | 2-4% | 30d |
| Boulanger | Awin | 2-4% | 30d |
| LDLC.com | Awin | 2% | 30d |

## URL Format Examples

```
Amazon Associates:
https://www.amazon.fr/dp/B0ABC123?tag=pareto-21

Awin (Fnac, Darty, Boulanger):
https://www.awin1.com/cread.php?awinmid=XXXXX&awinaffid=YYYYY&ued=https://fnac.com/product

Effinity (Cdiscount):
https://track.effiliation.com/servlet/effi.click?id_compteur=XXXXX&url=https://cdiscount.com/product
```

## Click Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                       CLICK FLOW                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. User clicks "Acheter" on product page                      │
│      └─► GET /go/:offer_id                                      │
│                                                                 │
│   2. Server logs click                                          │
│      └─► INSERT INTO clicks (offer_id, user_agent, ip, ...)    │
│                                                                 │
│   3. Server builds affiliate URL                                │
│      └─► network.BuildURL(offer.URL, affiliateParams)          │
│                                                                 │
│   4. Server redirects (302)                                     │
│      └─► Location: https://awin1.com/...                       │
│                                                                 │
│   5. User lands on retailer site with tracking cookie           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Data Model

```sql
-- Clicks table (TimescaleDB hypertable)
CREATE TABLE clicks (
    time TIMESTAMPTZ NOT NULL,
    offer_id UUID NOT NULL REFERENCES offers(id),
    product_id UUID NOT NULL,
    retailer_id VARCHAR(50) NOT NULL,
    user_agent TEXT,
    ip_address INET,
    referer TEXT,
    session_id VARCHAR(100)
);

SELECT create_hypertable('clicks', 'time');

-- Daily aggregates
CREATE MATERIALIZED VIEW daily_clicks
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS day,
    retailer_id,
    COUNT(*) AS click_count,
    COUNT(DISTINCT session_id) AS unique_sessions
FROM clicks
GROUP BY day, retailer_id
WITH NO DATA;
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/go/:offer_id` | Redirect to affiliate URL |
| GET | `/api/v1/affiliate/stats` | Click statistics |
| GET | `/api/v1/affiliate/earnings` | Estimated earnings |

## Success Metrics

| Metric | Target |
|--------|--------|
| Click-through rate | >5% |
| Redirect latency | <100ms |
| Click logging | 100% |
| Affiliate attribution | >90% |

## Deliverables

- [ ] Link generator per network
- [ ] Click redirect endpoint
- [ ] Click tracking database
- [ ] Analytics dashboard data
- [ ] Revenue estimation

---

**Depends on**: [Catalog](../catalog/)
**Unlocks**: [Frontend](../frontend/)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
