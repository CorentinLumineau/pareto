# Platform Expansion - API, B2B, White-Label

> **How to evolve Pareto from consumer app to platform**

## Overview

Pareto evolves through platform tiers:
1. **Consumer App** (MVP) - Web + Mobile for end users
2. **Public API** - Developer access to comparison data
3. **B2B Portal** - Enterprise dashboard for partners
4. **White-Label** - Fully customizable embedded solution

## Platform Evolution

```
                      PLATFORM EXPANSION TIERS

    ┌──────────────────────────────────────────────────────────┐
    │                                                          │
    │   TIER 1: CONSUMER APP                                  │
    │   ─────────────────────                                 │
    │   • Web (Next.js)                                       │
    │   • Mobile (Expo)                                       │
    │   • Ad-supported + Affiliate revenue                    │
    │                                                          │
    ├──────────────────────────────────────────────────────────┤
    │                                                          │
    │   TIER 2: PUBLIC API                                    │
    │   ──────────────────                                    │
    │   • REST API with rate limits                           │
    │   • Free tier: 1,000 requests/month                     │
    │   • Paid tiers: Usage-based pricing                     │
    │   • Revenue: API subscriptions                          │
    │                                                          │
    ├──────────────────────────────────────────────────────────┤
    │                                                          │
    │   TIER 3: B2B PORTAL                                    │
    │   ──────────────────                                    │
    │   • Partner dashboard                                    │
    │   • Custom data feeds                                   │
    │   • Embedded widgets                                    │
    │   • Revenue: SaaS subscriptions                         │
    │                                                          │
    ├──────────────────────────────────────────────────────────┤
    │                                                          │
    │   TIER 4: WHITE-LABEL                                   │
    │   ───────────────────                                   │
    │   • Fully branded solution                              │
    │   • Custom domains                                      │
    │   • Own affiliate relationships                         │
    │   • Revenue: License + revenue share                    │
    │                                                          │
    └──────────────────────────────────────────────────────────┘
```

## Tier 2: Public API

### API Design

```yaml
# OpenAPI 3.1 Specification
openapi: 3.1.0
info:
  title: Pareto Comparator API
  version: 1.0.0
  description: Product comparison with Pareto optimization

servers:
  - url: https://api.pareto.com/v1

paths:
  /products:
    get:
      summary: Search products
      parameters:
        - name: category
          in: query
          schema:
            type: string
        - name: country
          in: query
          schema:
            type: string
            default: FR
        - name: q
          in: query
          schema:
            type: string
      responses:
        200:
          description: Product list
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProductList'

  /products/{id}:
    get:
      summary: Get product details
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        200:
          description: Product details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'

  /compare:
    post:
      summary: Compare products with Pareto optimization
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                product_ids:
                  type: array
                  items:
                    type: string
                    format: uuid
                objectives:
                  type: array
                  items:
                    $ref: '#/components/schemas/Objective'
      responses:
        200:
          description: Comparison results
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ComparisonResult'

  /prices/{product_id}:
    get:
      summary: Get price history
      parameters:
        - name: product_id
          in: path
          required: true
          schema:
            type: string
            format: uuid
        - name: days
          in: query
          schema:
            type: integer
            default: 30
      responses:
        200:
          description: Price history
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PriceHistory'

components:
  schemas:
    Product:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        brand:
          type: string
        category:
          type: string
        attributes:
          type: object
        offers:
          type: array
          items:
            $ref: '#/components/schemas/Offer'

    Offer:
      type: object
      properties:
        retailer:
          type: string
        price:
          type: number
        currency:
          type: string
        url:
          type: string
        condition:
          type: string

    Objective:
      type: object
      properties:
        name:
          type: string
        sense:
          type: string
          enum: [min, max]
        weight:
          type: number

    ComparisonResult:
      type: object
      properties:
        pareto_optimal:
          type: array
          items:
            type: string
            format: uuid
        dominated:
          type: array
          items:
            type: string
            format: uuid
        scores:
          type: object
          additionalProperties:
            type: number

  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
```

### Rate Limiting

```go
// apps/api/internal/middleware/ratelimit.go
package middleware

import (
    "net/http"
    "time"

    "github.com/go-chi/chi/v5"
    "github.com/redis/go-redis/v9"
)

type RateLimiter struct {
    redis *redis.Client
    tiers map[string]TierConfig
}

type TierConfig struct {
    RequestsPerMonth int
    RequestsPerMinute int
    BurstSize int
}

var defaultTiers = map[string]TierConfig{
    "free": {
        RequestsPerMonth: 1000,
        RequestsPerMinute: 10,
        BurstSize: 5,
    },
    "starter": {
        RequestsPerMonth: 50000,
        RequestsPerMinute: 100,
        BurstSize: 20,
    },
    "pro": {
        RequestsPerMonth: 500000,
        RequestsPerMinute: 500,
        BurstSize: 50,
    },
    "enterprise": {
        RequestsPerMonth: -1, // Unlimited
        RequestsPerMinute: 2000,
        BurstSize: 200,
    },
}

func (rl *RateLimiter) Middleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        apiKey := r.Header.Get("X-API-Key")
        if apiKey == "" {
            http.Error(w, "API key required", http.StatusUnauthorized)
            return
        }

        tier, err := rl.getTier(r.Context(), apiKey)
        if err != nil {
            http.Error(w, "Invalid API key", http.StatusUnauthorized)
            return
        }

        allowed, remaining, resetAt := rl.checkLimit(r.Context(), apiKey, tier)
        if !allowed {
            w.Header().Set("X-RateLimit-Remaining", "0")
            w.Header().Set("X-RateLimit-Reset", resetAt.Format(time.RFC3339))
            http.Error(w, "Rate limit exceeded", http.StatusTooManyRequests)
            return
        }

        w.Header().Set("X-RateLimit-Remaining", fmt.Sprintf("%d", remaining))
        next.ServeHTTP(w, r)
    })
}
```

### API Key Management

```sql
-- API keys table
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    key_hash TEXT NOT NULL UNIQUE,  -- SHA-256 of actual key
    name TEXT NOT NULL,
    tier TEXT NOT NULL DEFAULT 'free',
    scopes TEXT[] DEFAULT ARRAY['read'],
    enabled BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Usage tracking
CREATE TABLE api_usage (
    time TIMESTAMPTZ NOT NULL,
    api_key_id UUID NOT NULL REFERENCES api_keys(id),
    endpoint TEXT NOT NULL,
    response_code INTEGER NOT NULL,
    latency_ms INTEGER NOT NULL
);
SELECT create_hypertable('api_usage', 'time');
```

### Pricing Tiers

```yaml
# API Pricing
tiers:
  free:
    price: 0
    requests: 1000/month
    rate_limit: 10/min
    features:
      - Product search
      - Basic comparison
      - 7-day price history

  starter:
    price: 29/month
    requests: 50000/month
    rate_limit: 100/min
    features:
      - Everything in Free
      - Full comparison API
      - 90-day price history
      - Webhook notifications

  pro:
    price: 149/month
    requests: 500000/month
    rate_limit: 500/min
    features:
      - Everything in Starter
      - Real-time price updates
      - Custom objectives
      - Priority support

  enterprise:
    price: custom
    requests: unlimited
    rate_limit: 2000/min
    features:
      - Everything in Pro
      - Dedicated support
      - Custom SLA
      - White-label option
```

## Tier 3: B2B Portal

### Partner Dashboard

```typescript
// apps/web/app/dashboard/page.tsx
export default async function DashboardPage() {
  const org = await getOrganization();
  const usage = await getApiUsage(org.id);
  const widgets = await getWidgets(org.id);

  return (
    <div className="dashboard">
      <UsageChart data={usage} />

      <div className="widgets-section">
        <h2>Embedded Widgets</h2>
        {widgets.map(widget => (
          <WidgetCard key={widget.id} widget={widget} />
        ))}
        <CreateWidgetButton orgId={org.id} />
      </div>

      <div className="api-keys-section">
        <h2>API Keys</h2>
        <ApiKeyManager orgId={org.id} />
      </div>
    </div>
  );
}
```

### Embeddable Widgets

```typescript
// Embed script for partners
// Usage: <script src="https://pareto.com/embed.js" data-widget-id="xxx"></script>

(function() {
  const widgetId = document.currentScript.dataset.widgetId;
  const container = document.createElement('div');
  container.id = 'pareto-widget';

  const iframe = document.createElement('iframe');
  iframe.src = `https://pareto.com/widget/${widgetId}`;
  iframe.style.width = '100%';
  iframe.style.border = 'none';

  // Auto-resize iframe
  window.addEventListener('message', (event) => {
    if (event.origin !== 'https://pareto.com') return;
    if (event.data.type === 'resize') {
      iframe.style.height = event.data.height + 'px';
    }
  });

  container.appendChild(iframe);
  document.currentScript.parentNode.insertBefore(
    container,
    document.currentScript
  );
})();
```

### Custom Data Feeds

```yaml
# Partner-specific data feeds
feeds:
  - partner: techblog.example.com
    type: product_feed
    format: json
    frequency: hourly
    categories: [smartphones, laptops]
    fields: [name, brand, price, image, affiliate_url]
    delivery: webhook
    url: https://techblog.example.com/api/products

  - partner: comparateur.example.fr
    type: price_feed
    format: csv
    frequency: daily
    categories: [all]
    fields: [ean, name, retailer, price, currency]
    delivery: sftp
    path: /incoming/pareto/prices.csv
```

## Tier 4: White-Label

### Multi-Tenancy Architecture

```sql
-- Organizations for multi-tenancy
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    tier TEXT NOT NULL DEFAULT 'free',

    -- White-label settings
    custom_domain TEXT,
    branding JSONB DEFAULT '{}',
    theme JSONB DEFAULT '{}',

    -- Affiliate settings
    affiliate_override BOOLEAN DEFAULT false,
    affiliate_config JSONB DEFAULT '{}',

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row-level security
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY org_isolation ON products
    USING (organization_id = current_setting('app.organization_id')::uuid);
```

### Custom Domain Routing

```typescript
// apps/web/middleware.ts
export async function middleware(request: NextRequest) {
  const hostname = request.headers.get('host') || '';

  // Check if custom domain
  if (!hostname.includes('pareto.com')) {
    const org = await getOrgByDomain(hostname);
    if (org) {
      const response = NextResponse.next();
      response.headers.set('x-organization-id', org.id);
      response.headers.set('x-theme', JSON.stringify(org.theme));
      return response;
    }
  }

  return NextResponse.next();
}
```

### White-Label Theming

```typescript
// apps/web/lib/theme/white-label.ts
interface WhiteLabelTheme {
  logo: string;
  favicon: string;
  colors: {
    primary: string;
    secondary: string;
    accent: string;
    background: string;
    text: string;
  };
  fonts: {
    heading: string;
    body: string;
  };
  customCSS?: string;
}

export function applyTheme(theme: WhiteLabelTheme) {
  const root = document.documentElement;

  root.style.setProperty('--color-primary', theme.colors.primary);
  root.style.setProperty('--color-secondary', theme.colors.secondary);
  root.style.setProperty('--color-accent', theme.colors.accent);
  root.style.setProperty('--color-background', theme.colors.background);
  root.style.setProperty('--color-text', theme.colors.text);

  if (theme.customCSS) {
    const style = document.createElement('style');
    style.textContent = theme.customCSS;
    document.head.appendChild(style);
  }
}
```

### White-Label Affiliate Override

```go
// apps/api/internal/affiliate/whitelabel.go
package affiliate

func GetAffiliateURL(
    productURL string,
    retailer string,
    orgID uuid.UUID,
) (string, error) {
    org, err := getOrg(orgID)
    if err != nil {
        return "", err
    }

    // White-label partners can use their own affiliate links
    if org.AffiliateOverride && org.AffiliateConfig != nil {
        config := org.AffiliateConfig[retailer]
        if config != nil {
            return buildAffiliateURL(productURL, config)
        }
    }

    // Default to Pareto's affiliate links with revenue share
    return buildParetoAffiliateURL(productURL, retailer, orgID)
}
```

## Revenue Models

| Tier | Revenue Model | Example |
|------|---------------|---------|
| Consumer | Affiliate + Ads | €0.02-0.50 per click |
| API Free | Lead gen | Convert to paid |
| API Starter | SaaS | €29/month |
| API Pro | SaaS | €149/month |
| Enterprise | Custom | €500+/month |
| White-Label | License + Rev Share | €1000/mo + 20% affiliate |

## Implementation Roadmap

### Phase 1: API Foundation
```markdown
- [ ] API authentication (API keys)
- [ ] Rate limiting middleware
- [ ] Usage tracking
- [ ] Developer documentation
- [ ] Swagger/OpenAPI spec
```

### Phase 2: Self-Service
```markdown
- [ ] Developer portal
- [ ] API key management UI
- [ ] Usage dashboard
- [ ] Billing integration (Stripe)
```

### Phase 3: B2B Features
```markdown
- [ ] Partner dashboard
- [ ] Embeddable widgets
- [ ] Data feeds
- [ ] Webhook notifications
```

### Phase 4: White-Label
```markdown
- [ ] Multi-tenancy DB schema
- [ ] Custom domain routing
- [ ] Theme engine
- [ ] Affiliate override
- [ ] Admin portal
```

## Related Documentation

- [Geographic Expansion](./geographic-expansion.md) - Multi-country
- [Vertical Expansion](./vertical-expansion.md) - Categories
- [Infrastructure Scaling](./infrastructure-scaling.md) - Technical scaling

---

**Last Updated**: 2025-12-01
