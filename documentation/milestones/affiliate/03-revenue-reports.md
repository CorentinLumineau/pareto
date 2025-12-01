# Phase 03: Revenue Reports

> **Dashboard data and analytics**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      03 - Revenue Reports                              ║
║  Initiative: Affiliate                                         ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     1 day                                             ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Create analytics endpoints and revenue estimation for the admin dashboard.

## Tasks

- [ ] Implement stats repository
- [ ] Create stats API endpoints
- [ ] Add revenue estimation
- [ ] Build trending products query

## Stats Repository

```go
// apps/api/internal/affiliate/stats.go
package affiliate

import (
    "context"
    "time"

    "gorm.io/gorm"
)

type StatsRepository struct {
    db *gorm.DB
}

func NewStatsRepository(db *gorm.DB) *StatsRepository {
    return &StatsRepository{db: db}
}

// DailyStats represents daily click statistics
type DailyStats struct {
    Day            time.Time `json:"day"`
    RetailerID     string    `json:"retailer_id"`
    TotalClicks    int       `json:"total_clicks"`
    UniqueSessions int       `json:"unique_sessions"`
    UniqueIPs      int       `json:"unique_ips"`
}

// GetDailyStats returns daily click statistics
func (r *StatsRepository) GetDailyStats(ctx context.Context, days int) ([]DailyStats, error) {
    var stats []DailyStats

    err := r.db.WithContext(ctx).
        Table("daily_clicks").
        Where("day > NOW() - INTERVAL '? days'", days).
        Order("day DESC").
        Find(&stats).Error

    return stats, err
}

// TotalStats represents overall statistics
type TotalStats struct {
    TotalClicks      int64   `json:"total_clicks"`
    TotalSessions    int64   `json:"total_sessions"`
    ClicksToday      int64   `json:"clicks_today"`
    ClicksThisWeek   int64   `json:"clicks_this_week"`
    ClicksThisMonth  int64   `json:"clicks_this_month"`
    TopRetailer      string  `json:"top_retailer"`
    EstimatedRevenue float64 `json:"estimated_revenue"`
}

// GetTotalStats returns overall statistics
func (r *StatsRepository) GetTotalStats(ctx context.Context) (*TotalStats, error) {
    stats := &TotalStats{}

    // Total clicks all time
    r.db.WithContext(ctx).
        Table("clicks").
        Count(&stats.TotalClicks)

    // Clicks today
    r.db.WithContext(ctx).
        Table("clicks").
        Where("time > NOW() - INTERVAL '1 day'").
        Count(&stats.ClicksToday)

    // Clicks this week
    r.db.WithContext(ctx).
        Table("clicks").
        Where("time > NOW() - INTERVAL '7 days'").
        Count(&stats.ClicksThisWeek)

    // Clicks this month
    r.db.WithContext(ctx).
        Table("clicks").
        Where("time > NOW() - INTERVAL '30 days'").
        Count(&stats.ClicksThisMonth)

    // Top retailer
    var topRetailer struct {
        RetailerID string
        Count      int64
    }
    r.db.WithContext(ctx).
        Table("clicks").
        Select("retailer_id, COUNT(*) as count").
        Where("time > NOW() - INTERVAL '30 days'").
        Group("retailer_id").
        Order("count DESC").
        Limit(1).
        Scan(&topRetailer)
    stats.TopRetailer = topRetailer.RetailerID

    // Estimated revenue (based on average conversion and commission)
    stats.EstimatedRevenue = r.estimateRevenue(stats.ClicksThisMonth)

    return stats, nil
}

// Revenue estimation constants
const (
    avgConversionRate = 0.02   // 2% of clicks convert to sales
    avgOrderValue     = 500.0  // Average smartphone price
    avgCommissionRate = 0.03   // 3% average commission
)

func (r *StatsRepository) estimateRevenue(clicks int64) float64 {
    conversions := float64(clicks) * avgConversionRate
    revenue := conversions * avgOrderValue * avgCommissionRate
    return revenue
}

// RetailerStats represents per-retailer statistics
type RetailerStats struct {
    RetailerID       string  `json:"retailer_id"`
    RetailerName     string  `json:"retailer_name"`
    TotalClicks      int64   `json:"total_clicks"`
    ClicksThisMonth  int64   `json:"clicks_this_month"`
    ConversionRate   float64 `json:"conversion_rate"` // Placeholder
    EstimatedRevenue float64 `json:"estimated_revenue"`
}

// GetRetailerStats returns per-retailer statistics
func (r *StatsRepository) GetRetailerStats(ctx context.Context) ([]RetailerStats, error) {
    var results []struct {
        RetailerID      string
        TotalClicks     int64
        ClicksThisMonth int64
    }

    err := r.db.WithContext(ctx).Raw(`
        SELECT
            retailer_id,
            COUNT(*) as total_clicks,
            COUNT(*) FILTER (WHERE time > NOW() - INTERVAL '30 days') as clicks_this_month
        FROM clicks
        GROUP BY retailer_id
        ORDER BY total_clicks DESC
    `).Scan(&results).Error

    if err != nil {
        return nil, err
    }

    retailerNames := map[string]string{
        "amazon_fr": "Amazon France",
        "fnac":      "Fnac",
        "cdiscount": "Cdiscount",
        "darty":     "Darty",
        "boulanger": "Boulanger",
        "ldlc":      "LDLC",
    }

    stats := make([]RetailerStats, len(results))
    for i, r := range results {
        stats[i] = RetailerStats{
            RetailerID:       r.RetailerID,
            RetailerName:     retailerNames[r.RetailerID],
            TotalClicks:      r.TotalClicks,
            ClicksThisMonth:  r.ClicksThisMonth,
            ConversionRate:   avgConversionRate, // Placeholder until real data
            EstimatedRevenue: float64(r.ClicksThisMonth) * avgConversionRate * avgOrderValue * avgCommissionRate,
        }
    }

    return stats, nil
}

// TrendingProduct represents a trending product by clicks
type TrendingProduct struct {
    ProductID   string `json:"product_id"`
    ProductName string `json:"product_name"`
    ClickCount  int64  `json:"click_count"`
}

// GetTrendingProducts returns most clicked products
func (r *StatsRepository) GetTrendingProducts(ctx context.Context, limit int) ([]TrendingProduct, error) {
    var results []TrendingProduct

    err := r.db.WithContext(ctx).Raw(`
        SELECT
            c.product_id,
            p.title as product_name,
            COUNT(*) as click_count
        FROM clicks c
        JOIN products p ON p.id = c.product_id
        WHERE c.time > NOW() - INTERVAL '7 days'
        GROUP BY c.product_id, p.title
        ORDER BY click_count DESC
        LIMIT ?
    `, limit).Scan(&results).Error

    return results, err
}
```

## Stats Handler

```go
// apps/api/internal/affiliate/handler.go (additions)

// GetStats returns overall statistics
func (h *Handler) GetStats(c *gin.Context) {
    stats, err := h.statsRepo.GetTotalStats(c.Request.Context())
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, stats)
}

// GetDailyStats returns daily statistics
func (h *Handler) GetDailyStats(c *gin.Context) {
    days, _ := strconv.Atoi(c.DefaultQuery("days", "30"))
    if days > 365 {
        days = 365
    }

    stats, err := h.statsRepo.GetDailyStats(c.Request.Context(), days)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"stats": stats})
}

// GetRetailerStats returns per-retailer statistics
func (h *Handler) GetRetailerStats(c *gin.Context) {
    stats, err := h.statsRepo.GetRetailerStats(c.Request.Context())
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"retailers": stats})
}

// GetTrendingProducts returns most clicked products
func (h *Handler) GetTrendingProducts(c *gin.Context) {
    limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
    if limit > 50 {
        limit = 50
    }

    products, err := h.statsRepo.GetTrendingProducts(c.Request.Context(), limit)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"trending": products})
}
```

## API Response Examples

```json
// GET /api/v1/affiliate/stats
{
    "total_clicks": 15423,
    "total_sessions": 8234,
    "clicks_today": 127,
    "clicks_this_week": 892,
    "clicks_this_month": 3456,
    "top_retailer": "amazon_fr",
    "estimated_revenue": 1036.80
}

// GET /api/v1/affiliate/stats/retailers
{
    "retailers": [
        {
            "retailer_id": "amazon_fr",
            "retailer_name": "Amazon France",
            "total_clicks": 8234,
            "clicks_this_month": 1823,
            "conversion_rate": 0.02,
            "estimated_revenue": 546.90
        },
        {
            "retailer_id": "fnac",
            "retailer_name": "Fnac",
            "total_clicks": 3421,
            "clicks_this_month": 756,
            "conversion_rate": 0.02,
            "estimated_revenue": 226.80
        }
    ]
}

// GET /api/v1/affiliate/trending
{
    "trending": [
        {
            "product_id": "abc123",
            "product_name": "iPhone 15 Pro 256GB",
            "click_count": 234
        },
        {
            "product_id": "def456",
            "product_name": "Samsung Galaxy S24 Ultra",
            "click_count": 189
        }
    ]
}
```

## Deliverables

- [ ] Stats repository
- [ ] Total stats endpoint
- [ ] Daily stats endpoint
- [ ] Per-retailer stats endpoint
- [ ] Trending products endpoint
- [ ] Revenue estimation

---

**Previous Phase**: [02-click-tracking.md](./02-click-tracking.md)
**Back to**: [Affiliate README](./README.md)
