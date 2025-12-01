# Phase 02: Anti-Bot Bypass

> **Python fetcher with curl_cffi for TLS fingerprint impersonation**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      02 - Anti-Bot Bypass                               ║
║  Initiative: Scraper                                            ║
║  Status:     ⏳ PENDING                                         ║
║  Effort:     5 days                                             ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Bypass anti-bot protection using Python curl_cffi with TLS fingerprint impersonation.

## Tasks

- [ ] Setup Python fetcher service
- [ ] Implement TLS fingerprint impersonation (chrome136)
- [ ] Configure retailer-specific settings
- [ ] Implement delay enforcement
- [ ] Test against live sites

## Implementation

```python
# apps/workers/src/fetcher/client.py
from curl_cffi import requests

class AntiDetectClient:
    def __init__(self, impersonate: str = "chrome136"):
        self.session = requests.Session(impersonate=impersonate)

    async def fetch(self, url: str, proxy: str = None) -> dict:
        response = self.session.get(
            url,
            proxy=proxy,
            timeout=30,
        )
        return {
            "status": response.status_code,
            "html": response.text,
            "headers": dict(response.headers)
        }
```

## Retailer Configuration

| Retailer | Anti-Bot | Rate Limit |
|----------|----------|------------|
| Amazon.fr | In-house | 2s |
| Fnac.com | Cloudflare | 3s |
| Cdiscount | DataDome | 3s |
| Darty.com | PerimeterX | 2s |
| Boulanger | Light | 1s |
| LDLC.com | Light | 1s |

## Deliverables

- [ ] curl_cffi fetcher working
- [ ] >90% success rate on test URLs
- [ ] Proxy integration tested
- [ ] HTTP API for Go communication

---

**Previous**: [01-skeleton.md](./01-skeleton.md)
**Next**: [03-queue.md](./03-queue.md)
**Back to**: [Scraper README](./README.md)
