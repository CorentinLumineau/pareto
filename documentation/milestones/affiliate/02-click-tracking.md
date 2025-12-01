# Phase 02: Click Tracking

> **Analytics and logging**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      02 - Click Tracking                               ║
║  Initiative: Affiliate                                         ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Implement click logging, redirect handling, and analytics storage.

## Tasks

- [ ] Create clicks table with TimescaleDB
- [ ] Implement redirect handler
- [ ] Add click logging
- [ ] Setup continuous aggregates
- [ ] Add analytics queries

## Database Schema

```sql
-- migrations/004_create_clicks.sql

-- Clicks table (TimescaleDB hypertable)
CREATE TABLE clicks (
    time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    offer_id UUID NOT NULL,
    product_id UUID NOT NULL,
    retailer_id VARCHAR(50) NOT NULL,
    network_id VARCHAR(50) NOT NULL,
    user_agent TEXT,
    ip_hash VARCHAR(64),  -- Hashed for privacy
    referer TEXT,
    session_id VARCHAR(100),
    country VARCHAR(2),
    device_type VARCHAR(20)  -- mobile, desktop, tablet
);

-- Convert to hypertable
SELECT create_hypertable('clicks', 'time');

-- Index for analytics
CREATE INDEX idx_clicks_retailer ON clicks(retailer_id, time DESC);
CREATE INDEX idx_clicks_product ON clicks(product_id, time DESC);

-- Daily aggregates
CREATE MATERIALIZED VIEW daily_clicks
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS day,
    retailer_id,
    network_id,
    COUNT(*) AS total_clicks,
    COUNT(DISTINCT session_id) AS unique_sessions,
    COUNT(DISTINCT ip_hash) AS unique_ips
FROM clicks
GROUP BY day, retailer_id, network_id
WITH NO DATA;

-- Refresh policy
SELECT add_continuous_aggregate_policy('daily_clicks',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour'
);

-- Hourly aggregates for real-time dashboard
CREATE MATERIALIZED VIEW hourly_clicks
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS hour,
    retailer_id,
    COUNT(*) AS click_count
FROM clicks
GROUP BY hour, retailer_id
WITH NO DATA;

SELECT add_continuous_aggregate_policy('hourly_clicks',
    start_offset => INTERVAL '2 hours',
    end_offset => INTERVAL '10 minutes',
    schedule_interval => INTERVAL '10 minutes'
);
```

## Click Model

```go
// apps/api/internal/affiliate/models.go
package affiliate

import (
    "time"
    "github.com/google/uuid"
)

type Click struct {
    Time       time.Time `gorm:"not null;default:now()"`
    OfferID    uuid.UUID `gorm:"type:uuid;not null"`
    ProductID  uuid.UUID `gorm:"type:uuid;not null"`
    RetailerID string    `gorm:"type:varchar(50);not null"`
    NetworkID  string    `gorm:"type:varchar(50);not null"`
    UserAgent  string    `gorm:"type:text"`
    IPHash     string    `gorm:"type:varchar(64)"`
    Referer    string    `gorm:"type:text"`
    SessionID  string    `gorm:"type:varchar(100)"`
    Country    string    `gorm:"type:varchar(2)"`
    DeviceType string    `gorm:"type:varchar(20)"`
}

func (Click) TableName() string {
    return "clicks"
}
```

## Click Tracker

```go
// apps/api/internal/affiliate/tracker.go
package affiliate

import (
    "context"
    "crypto/sha256"
    "encoding/hex"
    "strings"

    "github.com/google/uuid"
    "gorm.io/gorm"
)

type ClickTracker struct {
    db *gorm.DB
}

func NewClickTracker(db *gorm.DB) *ClickTracker {
    return &ClickTracker{db: db}
}

type TrackParams struct {
    OfferID    uuid.UUID
    ProductID  uuid.UUID
    RetailerID string
    NetworkID  string
    UserAgent  string
    IP         string
    Referer    string
    SessionID  string
}

func (t *ClickTracker) Track(ctx context.Context, params TrackParams) error {
    click := Click{
        OfferID:    params.OfferID,
        ProductID:  params.ProductID,
        RetailerID: params.RetailerID,
        NetworkID:  params.NetworkID,
        UserAgent:  params.UserAgent,
        IPHash:     hashIP(params.IP),
        Referer:    params.Referer,
        SessionID:  params.SessionID,
        Country:    "", // TODO: GeoIP lookup
        DeviceType: detectDeviceType(params.UserAgent),
    }

    return t.db.WithContext(ctx).Create(&click).Error
}

func hashIP(ip string) string {
    // Hash IP for privacy
    hash := sha256.Sum256([]byte(ip))
    return hex.EncodeToString(hash[:])
}

func detectDeviceType(userAgent string) string {
    ua := strings.ToLower(userAgent)
    switch {
    case strings.Contains(ua, "mobile") || strings.Contains(ua, "android"):
        return "mobile"
    case strings.Contains(ua, "tablet") || strings.Contains(ua, "ipad"):
        return "tablet"
    default:
        return "desktop"
    }
}
```

## Redirect Handler

```go
// apps/api/internal/affiliate/handler.go
package affiliate

import (
    "net/http"

    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "pareto/internal/catalog/repository"
)

type Handler struct {
    offerRepo     repository.OfferRepository
    linkGenerator *LinkGenerator
    tracker       *ClickTracker
}

func NewHandler(
    or repository.OfferRepository,
    lg *LinkGenerator,
    ct *ClickTracker,
) *Handler {
    return &Handler{
        offerRepo:     or,
        linkGenerator: lg,
        tracker:       ct,
    }
}

// Redirect handles /go/:offer_id
func (h *Handler) Redirect(c *gin.Context) {
    offerIDStr := c.Param("offer_id")
    offerID, err := uuid.Parse(offerIDStr)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid offer_id"})
        return
    }

    ctx := c.Request.Context()

    // Fetch offer
    offer, err := h.offerRepo.GetByID(ctx, offerID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "offer not found"})
        return
    }

    // Generate affiliate URL if not cached
    var affiliateURL string
    if offer.AffiliateURL != nil {
        affiliateURL = *offer.AffiliateURL
    } else {
        affiliateURL, err = h.linkGenerator.GenerateAffiliateURL(offer)
        if err != nil {
            // Fallback to direct URL
            affiliateURL = offer.URL
        }
    }

    // Track click (async)
    go func() {
        h.tracker.Track(ctx, TrackParams{
            OfferID:    offer.ID,
            ProductID:  offer.ProductID,
            RetailerID: offer.RetailerID,
            NetworkID:  h.linkGenerator.retailerToNetwork[offer.RetailerID],
            UserAgent:  c.GetHeader("User-Agent"),
            IP:         c.ClientIP(),
            Referer:    c.GetHeader("Referer"),
            SessionID:  c.GetString("session_id"), // From middleware
        })
    }()

    // Redirect to affiliate URL
    c.Redirect(http.StatusFound, affiliateURL)
}
```

## Routes

```go
// apps/api/internal/affiliate/routes.go
package affiliate

import "github.com/gin-gonic/gin"

func RegisterRoutes(r *gin.RouterGroup, h *Handler) {
    // Public redirect endpoint
    r.GET("/go/:offer_id", h.Redirect)

    // API endpoints
    api := r.Group("/api/v1/affiliate")
    api.GET("/stats", h.GetStats)
    api.GET("/stats/daily", h.GetDailyStats)
}
```

## Session Middleware

```go
// apps/api/internal/middleware/session.go
package middleware

import (
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
)

const sessionCookieName = "pareto_session"

func SessionMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        sessionID, err := c.Cookie(sessionCookieName)
        if err != nil || sessionID == "" {
            sessionID = uuid.New().String()
            c.SetCookie(sessionCookieName, sessionID, 86400*30, "/", "", false, true)
        }
        c.Set("session_id", sessionID)
        c.Next()
    }
}
```

## Deliverables

- [ ] Clicks table with TimescaleDB
- [ ] Click tracker service
- [ ] Redirect handler with logging
- [ ] Session tracking middleware
- [ ] Continuous aggregates
- [ ] Privacy-compliant IP handling

---

**Previous Phase**: [01-link-generator.md](./01-link-generator.md)
**Next Phase**: [03-revenue-reports.md](./03-revenue-reports.md)
**Back to**: [Affiliate README](./README.md)
