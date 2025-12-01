# Cloudflare - CDN & Tunnel

> **Edge network, CDN, and secure tunnel for VPS deployment**

## Services Used

| Service | Purpose |
|---------|---------|
| **Cloudflare Tunnel** | Secure connection to Dokploy VPS |
| **CDN** | Static asset caching |
| **DNS** | Domain management |
| **WAF** | Web Application Firewall |
| **Analytics** | Traffic insights |

## Cloudflare Tunnel Setup

### Architecture

```
                    [Users]
                       |
                       v
              [Cloudflare Edge]
                       |
                       | (encrypted tunnel)
                       v
              [cloudflared daemon]
                       |
                       v
              [Dokploy VPS - Traefik]
                       |
        +------+-------+-------+
        |      |               |
   [Next.js] [Go API]    [Python Workers]
```

### Installation on VPS

```bash
# Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create pareto

# Configure tunnel
cat > ~/.cloudflared/config.yml << EOF
tunnel: <TUNNEL_ID>
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  # Main website
  - hostname: pareto.fr
    service: http://localhost:3000
    originRequest:
      noTLSVerify: true

  # API
  - hostname: api.pareto.fr
    service: http://localhost:8080
    originRequest:
      noTLSVerify: true

  # Catch-all
  - service: http_status:404
EOF

# Run as service
cloudflared service install
systemctl enable cloudflared
systemctl start cloudflared
```

### Docker Integration

```yaml
# docker-compose.prod.yml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: pareto-cloudflared
    command: tunnel run
    environment:
      TUNNEL_TOKEN: ${CLOUDFLARE_TUNNEL_TOKEN}
    restart: unless-stopped
    networks:
      - pareto-network
    depends_on:
      - web
      - api
```

### DNS Configuration

```bash
# Route DNS through tunnel
cloudflared tunnel route dns pareto pareto.fr
cloudflared tunnel route dns pareto api.pareto.fr
cloudflared tunnel route dns pareto www.pareto.fr
```

## CDN Configuration

### Page Rules

```yaml
# Cloudflare Dashboard: Rules > Page Rules

# Cache static assets aggressively
- URL: pareto.fr/_next/static/*
  Settings:
    - Cache Level: Cache Everything
    - Edge Cache TTL: 1 month
    - Browser Cache TTL: 1 year

# Cache images
- URL: pareto.fr/images/*
  Settings:
    - Cache Level: Cache Everything
    - Edge Cache TTL: 1 week
    - Polish: Lossy
    - WebP: On

# Don't cache API
- URL: api.pareto.fr/*
  Settings:
    - Cache Level: Bypass
    - Security Level: High
```

### Cache Rules (New)

```yaml
# Cloudflare Dashboard: Caching > Cache Rules

rules:
  # Static assets
  - name: "Cache Next.js Static"
    expression: |
      (http.host eq "pareto.fr" and starts_with(http.request.uri.path, "/_next/static/"))
    action:
      edge_ttl: 2592000  # 30 days
      browser_ttl: 31536000  # 1 year
      cache_eligible: true

  # Product images
  - name: "Cache Product Images"
    expression: |
      (http.host eq "pareto.fr" and starts_with(http.request.uri.path, "/images/products/"))
    action:
      edge_ttl: 604800  # 7 days
      browser_ttl: 86400  # 1 day
      cache_eligible: true

  # API bypass
  - name: "Bypass API Cache"
    expression: |
      (http.host eq "api.pareto.fr")
    action:
      cache_eligible: false
```

### Transform Rules

```yaml
# Add security headers
rules:
  - name: "Security Headers"
    expression: "true"
    action:
      set_headers:
        - name: "X-Content-Type-Options"
          value: "nosniff"
        - name: "X-Frame-Options"
          value: "DENY"
        - name: "Referrer-Policy"
          value: "strict-origin-when-cross-origin"
        - name: "Permissions-Policy"
          value: "camera=(), microphone=(), geolocation=()"
```

## WAF Configuration

### Custom Rules

```yaml
# Cloudflare Dashboard: Security > WAF > Custom Rules

rules:
  # Block aggressive bots
  - name: "Block Bad Bots"
    expression: |
      (cf.client.bot) or
      (http.user_agent contains "curl") or
      (http.user_agent contains "wget") and
      not (cf.client.bot eq "verified")
    action: block

  # Rate limit API
  - name: "API Rate Limit"
    expression: |
      (http.host eq "api.pareto.fr")
    action:
      rate_limit:
        requests: 100
        period: 60  # per minute
        characteristics:
          - cf.colo.id
          - ip.src

  # Protect comparison endpoint
  - name: "Compare Rate Limit"
    expression: |
      (http.host eq "api.pareto.fr" and http.request.uri.path eq "/compare")
    action:
      rate_limit:
        requests: 10
        period: 60
        characteristics:
          - ip.src

  # Block non-FR traffic (optional, for MVP)
  - name: "FR Only"
    expression: |
      (ip.geoip.country ne "FR") and
      not (cf.client.bot eq "verified")
    action: challenge
```

### Managed Rules

```yaml
# Enable managed rulesets
managed_rules:
  - Cloudflare Managed Ruleset
  - Cloudflare OWASP Core Ruleset
  - Cloudflare Exposed Credentials Check
```

## Performance Optimization

### Speed Settings

```yaml
# Cloudflare Dashboard: Speed > Optimization

auto_minify:
  javascript: true
  css: true
  html: true

brotli: true
early_hints: true
rocket_loader: off  # Conflicts with Next.js
mirage: off  # For mobile image optimization
polish: lossy
webp: true

http2: true
http3: true
0-rtt: true
```

### Argo Smart Routing (Optional)

```yaml
# Premium feature - routes through fastest path
argo:
  enabled: true
  tiered_caching: true
```

## Workers (Optional)

### A/B Testing

```javascript
// workers/ab-test.js
export default {
  async fetch(request) {
    const url = new URL(request.url)

    // 10% of users see variant B
    const variant = Math.random() < 0.1 ? 'B' : 'A'

    // Pass variant to origin
    const modifiedRequest = new Request(request, {
      headers: new Headers(request.headers),
    })
    modifiedRequest.headers.set('X-AB-Variant', variant)

    const response = await fetch(modifiedRequest)

    // Add variant to response for client
    const modifiedResponse = new Response(response.body, response)
    modifiedResponse.headers.set('X-AB-Variant', variant)

    return modifiedResponse
  },
}
```

### Geo-Redirect

```javascript
// workers/geo-redirect.js
export default {
  async fetch(request) {
    const country = request.cf?.country || 'FR'

    // Redirect non-FR to appropriate domain (future)
    if (country !== 'FR') {
      return Response.redirect('https://pareto.fr?from=' + country, 302)
    }

    return fetch(request)
  },
}
```

## Analytics

### Web Analytics

```html
<!-- Add to Next.js layout -->
<script
  defer
  src='https://static.cloudflareinsights.com/beacon.min.js'
  data-cf-beacon='{"token": "YOUR_TOKEN"}'
></script>
```

### Logpush (Optional)

```yaml
# Push logs to R2 or external service
logpush:
  destination: "r2://pareto-logs"
  dataset: "http_requests"
  filter: |
    {
      "where": {
        "and": [
          {"key": "ClientRequestHost", "operator": "eq", "value": "api.pareto.fr"}
        ]
      }
    }
```

## DNS Records

```yaml
# Cloudflare Dashboard: DNS

records:
  # Main domain (proxied through tunnel)
  - type: CNAME
    name: pareto.fr
    content: <TUNNEL_ID>.cfargotunnel.com
    proxied: true

  - type: CNAME
    name: www
    content: pareto.fr
    proxied: true

  - type: CNAME
    name: api
    content: <TUNNEL_ID>.cfargotunnel.com
    proxied: true

  # Email (MX records)
  - type: MX
    name: pareto.fr
    content: mx.zoho.eu
    priority: 10

  # SPF
  - type: TXT
    name: pareto.fr
    content: "v=spf1 include:zoho.eu ~all"

  # DKIM (from email provider)
  - type: TXT
    name: zmail._domainkey
    content: "v=DKIM1; k=rsa; p=..."
```

## SSL/TLS Configuration

```yaml
# Cloudflare Dashboard: SSL/TLS

ssl_mode: full_strict  # Verify origin certificate

edge_certificates:
  always_use_https: true
  automatic_https_rewrites: true
  min_tls_version: "1.2"
  tls_1_3: true

hsts:
  enabled: true
  max_age: 31536000
  include_subdomains: true
  preload: true
```

## Monitoring

### Health Checks

```yaml
# Cloudflare Dashboard: Traffic > Health Checks

health_checks:
  - name: "API Health"
    address: api.pareto.fr
    path: /health
    type: HTTPS
    interval: 60
    retries: 2
    timeout: 5
    expected_codes: "200"

  - name: "Web Health"
    address: pareto.fr
    path: /
    type: HTTPS
    interval: 60
    retries: 2
    timeout: 10
    expected_codes: "200"
```

### Alerts

```yaml
# Cloudflare Dashboard: Notifications

alerts:
  - name: "High Error Rate"
    type: "http_error_rate"
    threshold: 5  # 5% errors
    duration: 5m
    notify:
      - email: alerts@pareto.fr

  - name: "Origin Down"
    type: "health_check"
    status: "unhealthy"
    notify:
      - email: alerts@pareto.fr
```

## Wrangler CLI

```bash
# Install
npm install -g wrangler

# Login
wrangler login

# Deploy worker
wrangler deploy

# Tail logs
wrangler tail

# Manage secrets
wrangler secret put API_KEY
```

---

**See Also**:
- [Docker](./docker.md)
- [Cloudflare Docs](https://developers.cloudflare.com/)
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
