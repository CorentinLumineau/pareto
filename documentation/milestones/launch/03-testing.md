# Phase 03: Testing

> **E2E testing, load testing, final QA**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      03 - Testing                                      ║
║  Initiative: Launch                                            ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     3 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Comprehensive testing before launch: E2E tests, load testing, and manual QA.

## Tasks

- [ ] E2E tests with Playwright
- [ ] API integration tests
- [ ] Load testing with k6
- [ ] Manual QA checklist
- [ ] Cross-browser/device testing

## E2E Tests with Playwright

```typescript
// apps/web/e2e/home.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Home Page', () => {
    test('should display hero and search', async ({ page }) => {
        await page.goto('/')

        await expect(page.locator('h1')).toContainText('Pareto')
        await expect(page.locator('input[type="search"]')).toBeVisible()
    })

    test('should navigate to products page', async ({ page }) => {
        await page.goto('/')
        await page.click('text=Voir tous les produits')

        await expect(page).toHaveURL('/products')
    })

    test('should search for products', async ({ page }) => {
        await page.goto('/')

        await page.fill('input[type="search"]', 'iPhone')
        await page.press('input[type="search"]', 'Enter')

        await expect(page).toHaveURL(/\/search\?q=iPhone/)
        await expect(page.locator('[data-testid="search-results"]')).toBeVisible()
    })
})

// apps/web/e2e/product.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Product Page', () => {
    test('should display product details', async ({ page }) => {
        // Assuming we have a known product ID
        await page.goto('/products/test-product-id')

        await expect(page.locator('h1')).toBeVisible()
        await expect(page.locator('[data-testid="price"]')).toBeVisible()
        await expect(page.locator('[data-testid="offers-table"]')).toBeVisible()
    })

    test('should show price history chart', async ({ page }) => {
        await page.goto('/products/test-product-id')

        await expect(page.locator('[data-testid="price-chart"]')).toBeVisible()
    })

    test('should redirect to retailer on offer click', async ({ page, context }) => {
        await page.goto('/products/test-product-id')

        const [newPage] = await Promise.all([
            context.waitForEvent('page'),
            page.click('[data-testid="offer-link"]:first-child')
        ])

        // Should redirect through /go/ endpoint
        await expect(newPage.url()).toContain('amazon.fr')
    })
})

// apps/web/e2e/compare.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Comparison Page', () => {
    test('should compare multiple products', async ({ page }) => {
        await page.goto('/compare?ids=id1,id2,id3')

        await expect(page.locator('[data-testid="pareto-chart"]')).toBeVisible()
        await expect(page.locator('[data-testid="top-picks"]')).toBeVisible()
    })

    test('should show Pareto frontier products', async ({ page }) => {
        await page.goto('/compare?ids=id1,id2,id3')

        const frontierProducts = page.locator('[data-testid="frontier-product"]')
        await expect(frontierProducts.first()).toBeVisible()
    })
})
```

## API Integration Tests

```go
// apps/api/tests/integration/catalog_test.go
package integration

import (
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/suite"
)

type CatalogTestSuite struct {
    suite.Suite
    server *httptest.Server
}

func (s *CatalogTestSuite) SetupSuite() {
    // Setup test database
    // Setup test server
}

func (s *CatalogTestSuite) TearDownSuite() {
    // Cleanup
}

func (s *CatalogTestSuite) TestListProducts() {
    resp, err := http.Get(s.server.URL + "/api/v1/products")
    assert.NoError(s.T(), err)
    assert.Equal(s.T(), http.StatusOK, resp.StatusCode)
}

func (s *CatalogTestSuite) TestGetProduct() {
    resp, err := http.Get(s.server.URL + "/api/v1/products/test-id")
    assert.NoError(s.T(), err)
    assert.Equal(s.T(), http.StatusOK, resp.StatusCode)
}

func (s *CatalogTestSuite) TestSearchProducts() {
    resp, err := http.Get(s.server.URL + "/api/v1/products/search?q=iPhone")
    assert.NoError(s.T(), err)
    assert.Equal(s.T(), http.StatusOK, resp.StatusCode)
}

func TestCatalogSuite(t *testing.T) {
    suite.Run(t, new(CatalogTestSuite))
}
```

## Load Testing with k6

```javascript
// k6/load-test.js
import http from 'k6/http'
import { check, sleep } from 'k6'

export const options = {
    stages: [
        { duration: '1m', target: 10 },   // Ramp up to 10 users
        { duration: '3m', target: 10 },   // Stay at 10 users
        { duration: '1m', target: 50 },   // Ramp up to 50 users
        { duration: '3m', target: 50 },   // Stay at 50 users
        { duration: '1m', target: 0 },    // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'],  // 95% of requests < 500ms
        http_req_failed: ['rate<0.01'],    // Error rate < 1%
    },
}

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080'

export default function () {
    // Home page
    let response = http.get(`${BASE_URL}/api/v1/products?limit=20`)
    check(response, {
        'products status is 200': (r) => r.status === 200,
        'products response time < 200ms': (r) => r.timings.duration < 200,
    })

    sleep(1)

    // Product detail
    response = http.get(`${BASE_URL}/api/v1/products/test-product-id`)
    check(response, {
        'product status is 200': (r) => r.status === 200,
    })

    sleep(1)

    // Search
    response = http.get(`${BASE_URL}/api/v1/products/search?q=iPhone`)
    check(response, {
        'search status is 200': (r) => r.status === 200,
        'search response time < 300ms': (r) => r.timings.duration < 300,
    })

    sleep(1)

    // Comparison
    response = http.post(`${BASE_URL}/api/v1/compare`, JSON.stringify({
        product_ids: ['id1', 'id2', 'id3'],
    }), {
        headers: { 'Content-Type': 'application/json' },
    })
    check(response, {
        'compare status is 200': (r) => r.status === 200,
        'compare response time < 500ms': (r) => r.timings.duration < 500,
    })

    sleep(2)
}
```

### Run Load Tests

```bash
# Install k6
brew install k6  # macOS
# or
docker run -i grafana/k6 run - < k6/load-test.js

# Run load test
k6 run k6/load-test.js

# Run with custom base URL
k6 run -e BASE_URL=https://api.pareto.fr k6/load-test.js
```

## Manual QA Checklist

### Functional Testing

#### Home Page
- [ ] Search input works
- [ ] Featured products display
- [ ] Navigation links work
- [ ] Responsive on mobile

#### Product List
- [ ] Products load correctly
- [ ] Pagination works
- [ ] Filters work (brand, price)
- [ ] Sort options work
- [ ] Infinite scroll works (mobile)

#### Product Detail
- [ ] All product info displays
- [ ] Offers table shows all retailers
- [ ] Price history chart renders
- [ ] "Buy" buttons redirect correctly
- [ ] Related products show

#### Comparison
- [ ] Pareto chart renders
- [ ] Top picks display correctly
- [ ] Comparison table accurate
- [ ] Score explanations clear

#### Search
- [ ] Results match query
- [ ] No results message shows
- [ ] Recent searches saved (mobile)

### Cross-Browser Testing

| Browser | Version | Status |
|---------|---------|--------|
| Chrome | Latest | [ ] |
| Firefox | Latest | [ ] |
| Safari | Latest | [ ] |
| Edge | Latest | [ ] |

### Mobile Testing

| Device | OS | Status |
|--------|-----|--------|
| iPhone 14 | iOS 17 | [ ] |
| iPhone SE | iOS 17 | [ ] |
| Pixel 7 | Android 14 | [ ] |
| Galaxy S23 | Android 14 | [ ] |

### Performance Checklist

- [ ] Lighthouse Performance > 90
- [ ] LCP < 2.5s
- [ ] FID < 100ms
- [ ] CLS < 0.1
- [ ] TTI < 3.8s

## Deliverables

- [ ] E2E tests passing
- [ ] API integration tests passing
- [ ] Load test results acceptable
- [ ] Manual QA complete
- [ ] Cross-browser testing done
- [ ] Mobile testing done

---

**Previous Phase**: [02-monitoring.md](./02-monitoring.md)
**Next Phase**: [04-go-live.md](./04-go-live.md)
**Back to**: [Launch README](./README.md)
