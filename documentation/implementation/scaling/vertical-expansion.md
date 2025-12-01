# Vertical Expansion - Category Scaling

> **How to add new product categories to Pareto**

## Overview

Pareto's architecture supports unlimited product verticals through:
- Flexible JSONB attribute schemas
- Category-specific comparison objectives
- Pluggable normalizer architecture
- Dynamic frontend rendering

## Vertical Roadmap

```
PHASE 1 (MVP)              PHASE 2                  PHASE 3
─────────────              ───────                  ───────
Smartphones                Laptops                  Smart Home
                          Tablets                   Wearables
                          Headphones                Gaming
                          Monitors                  Cameras

PHASE 4                    PHASE 5                  PHASE 6
───────                    ───────                  ───────
SaaS Tools                 Insurance                Banking
  - CRM                      - Auto                   - Credit Cards
  - Project Mgmt             - Home                   - Savings
  - Cloud Storage            - Health                 - Loans
  - Email Marketing          - Travel                 - Investments
```

## Architecture for Verticals

### Schema-Driven Categories

```sql
-- Each category has its own attribute schema
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    parent_id UUID REFERENCES categories(id),

    -- JSON Schema for validation
    attribute_schema JSONB NOT NULL,

    -- Pareto comparison configuration
    comparison_objectives JSONB NOT NULL,

    -- Display configuration
    display_config JSONB DEFAULT '{}',

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Example: Smartphone Schema

```json
{
  "slug": "smartphones",
  "name": "Smartphones",
  "attribute_schema": {
    "type": "object",
    "required": ["screen_size", "storage", "ram", "battery"],
    "properties": {
      "screen_size": {
        "type": "number",
        "unit": "inches",
        "min": 4,
        "max": 8
      },
      "storage": {
        "type": "integer",
        "unit": "GB",
        "enum": [64, 128, 256, 512, 1024]
      },
      "ram": {
        "type": "integer",
        "unit": "GB",
        "min": 4,
        "max": 24
      },
      "battery": {
        "type": "integer",
        "unit": "mAh",
        "min": 2000,
        "max": 7000
      },
      "refresh_rate": {
        "type": "integer",
        "unit": "Hz",
        "enum": [60, 90, 120, 144]
      },
      "camera_mp": {
        "type": "integer",
        "unit": "MP"
      },
      "5g": {
        "type": "boolean"
      },
      "nfc": {
        "type": "boolean"
      }
    }
  },
  "comparison_objectives": [
    {"name": "price", "sense": "min", "weight": 1.5, "required": true},
    {"name": "storage", "sense": "max", "weight": 1.0},
    {"name": "ram", "sense": "max", "weight": 1.0},
    {"name": "battery", "sense": "max", "weight": 1.0},
    {"name": "camera_mp", "sense": "max", "weight": 0.5}
  ]
}
```

### Example: Laptop Schema

```json
{
  "slug": "laptops",
  "name": "Laptops",
  "attribute_schema": {
    "type": "object",
    "required": ["screen_size", "storage", "ram", "cpu_benchmark"],
    "properties": {
      "screen_size": {
        "type": "number",
        "unit": "inches",
        "enum": [13, 14, 15, 16, 17]
      },
      "storage": {
        "type": "integer",
        "unit": "GB",
        "enum": [256, 512, 1024, 2048]
      },
      "storage_type": {
        "type": "string",
        "enum": ["SSD", "HDD", "SSD+HDD"]
      },
      "ram": {
        "type": "integer",
        "unit": "GB",
        "enum": [8, 16, 32, 64]
      },
      "cpu_benchmark": {
        "type": "integer",
        "description": "PassMark score"
      },
      "gpu_benchmark": {
        "type": "integer",
        "description": "3DMark score"
      },
      "battery_hours": {
        "type": "number",
        "unit": "hours"
      },
      "weight": {
        "type": "number",
        "unit": "kg"
      },
      "display_resolution": {
        "type": "string",
        "enum": ["FHD", "QHD", "4K"]
      }
    }
  },
  "comparison_objectives": [
    {"name": "price", "sense": "min", "weight": 1.5, "required": true},
    {"name": "cpu_benchmark", "sense": "max", "weight": 1.2},
    {"name": "ram", "sense": "max", "weight": 1.0},
    {"name": "storage", "sense": "max", "weight": 0.8},
    {"name": "battery_hours", "sense": "max", "weight": 1.0},
    {"name": "weight", "sense": "min", "weight": 0.7}
  ]
}
```

### Example: SaaS Tools Schema

```json
{
  "slug": "saas-crm",
  "name": "CRM Software",
  "attribute_schema": {
    "type": "object",
    "required": ["pricing_model", "price_per_user"],
    "properties": {
      "pricing_model": {
        "type": "string",
        "enum": ["per_user", "flat", "usage_based", "freemium"]
      },
      "price_per_user": {
        "type": "number",
        "unit": "EUR/month"
      },
      "min_users": {
        "type": "integer"
      },
      "max_users": {
        "type": "integer"
      },
      "storage_gb": {
        "type": "integer",
        "unit": "GB"
      },
      "api_included": {
        "type": "boolean"
      },
      "integrations_count": {
        "type": "integer"
      },
      "support_level": {
        "type": "string",
        "enum": ["community", "email", "chat", "phone", "dedicated"]
      },
      "uptime_sla": {
        "type": "number",
        "unit": "percent"
      },
      "gdpr_compliant": {
        "type": "boolean"
      },
      "features": {
        "type": "array",
        "items": {"type": "string"}
      }
    }
  },
  "comparison_objectives": [
    {"name": "price_per_user", "sense": "min", "weight": 1.5, "required": true},
    {"name": "integrations_count", "sense": "max", "weight": 1.0},
    {"name": "storage_gb", "sense": "max", "weight": 0.8},
    {"name": "uptime_sla", "sense": "max", "weight": 1.2}
  ]
}
```

### Example: Banking Products Schema

```json
{
  "slug": "credit-cards",
  "name": "Credit Cards",
  "attribute_schema": {
    "type": "object",
    "required": ["annual_fee", "apr"],
    "properties": {
      "annual_fee": {
        "type": "number",
        "unit": "EUR"
      },
      "apr": {
        "type": "number",
        "unit": "percent"
      },
      "cashback_rate": {
        "type": "number",
        "unit": "percent"
      },
      "rewards_program": {
        "type": "string",
        "enum": ["none", "points", "miles", "cashback"]
      },
      "welcome_bonus": {
        "type": "number",
        "unit": "EUR"
      },
      "foreign_transaction_fee": {
        "type": "number",
        "unit": "percent"
      },
      "credit_limit_min": {
        "type": "integer",
        "unit": "EUR"
      },
      "credit_limit_max": {
        "type": "integer",
        "unit": "EUR"
      },
      "contactless": {
        "type": "boolean"
      },
      "insurance_included": {
        "type": "array",
        "items": {"type": "string"}
      }
    }
  },
  "comparison_objectives": [
    {"name": "annual_fee", "sense": "min", "weight": 1.2, "required": true},
    {"name": "apr", "sense": "min", "weight": 1.5},
    {"name": "cashback_rate", "sense": "max", "weight": 1.0},
    {"name": "welcome_bonus", "sense": "max", "weight": 0.5},
    {"name": "foreign_transaction_fee", "sense": "min", "weight": 0.8}
  ]
}
```

## Adding a New Vertical

### Step 1: Define Schema

```python
# apps/workers/src/schemas/laptops.py
LAPTOP_SCHEMA = {
    "slug": "laptops",
    "name": "Laptops",
    "attribute_schema": {...},
    "comparison_objectives": [...]
}
```

### Step 2: Create Normalizer

```python
# apps/workers/src/normalizer/laptops.py
from .base import BaseNormalizer

class LaptopNormalizer(BaseNormalizer):
    """Extract laptop attributes from retailer HTML."""

    def extract_attributes(self, html: str, retailer: str) -> dict:
        """Parse retailer-specific HTML to extract attributes."""
        parser = self.get_parser(retailer)

        return {
            "screen_size": parser.extract_screen_size(html),
            "storage": parser.extract_storage(html),
            "ram": parser.extract_ram(html),
            "cpu_benchmark": self.lookup_benchmark(
                parser.extract_cpu_model(html)
            ),
            "battery_hours": parser.extract_battery(html),
            "weight": parser.extract_weight(html),
        }

    def validate(self, attributes: dict) -> bool:
        """Validate against schema."""
        return self.schema_validator.validate(
            attributes,
            LAPTOP_SCHEMA["attribute_schema"]
        )
```

### Step 3: Configure Retailers

```yaml
# apps/workers/config/retailers/laptops.yaml
retailers:
  - name: amazon_fr
    base_url: https://www.amazon.fr
    category_paths:
      - /gp/browse.html?node=429879031  # Laptops
    selectors:
      title: "#productTitle"
      price: ".a-price-whole"
      specs:
        screen_size: "#productDetails_techSpec_section_1 tr:contains('Taille')"
        storage: "#productDetails_techSpec_section_1 tr:contains('Stockage')"
        ram: "#productDetails_techSpec_section_1 tr:contains('RAM')"

  - name: fnac_fr
    base_url: https://www.fnac.com
    category_paths:
      - /Informatique/Ordinateur-portable
    selectors:
      title: ".f-productHeader-Title"
      price: ".f-priceBox-price"
```

### Step 4: Add Affiliate Programs

```yaml
# apps/api/config/affiliates/laptops.yaml
affiliates:
  - retailer: amazon_fr
    program: amazon_associates
    tracking_param: tag
    tracking_id: pareto-laptop-21
    commission_rate: 0.03

  - retailer: fnac_fr
    program: awin
    tracking_param: awc
    tracking_id: "123456_laptop"
    commission_rate: 0.04
```

### Step 5: Frontend Integration

```typescript
// apps/web/lib/categories/laptops.ts
export const LAPTOP_CATEGORY: CategoryConfig = {
  slug: "laptops",
  name: "Laptops",
  icon: "laptop",

  // Filters shown in sidebar
  filters: [
    { key: "screen_size", type: "range", min: 13, max: 17, step: 1 },
    { key: "ram", type: "select", options: [8, 16, 32, 64] },
    { key: "storage", type: "select", options: [256, 512, 1024, 2048] },
    { key: "brand", type: "multi-select", dynamic: true },
  ],

  // Columns shown in comparison table
  columns: [
    { key: "name", label: "Model", sortable: true },
    { key: "price", label: "Price", sortable: true, format: "currency" },
    { key: "screen_size", label: "Screen", sortable: true, format: "inches" },
    { key: "cpu_benchmark", label: "CPU Score", sortable: true },
    { key: "ram", label: "RAM", sortable: true, format: "gb" },
    { key: "battery_hours", label: "Battery", sortable: true, format: "hours" },
  ],

  // Default Pareto objectives
  defaultObjectives: [
    { name: "price", sense: "min", weight: 1.5 },
    { name: "cpu_benchmark", sense: "max", weight: 1.2 },
    { name: "battery_hours", sense: "max", weight: 1.0 },
  ],
};
```

## Vertical-Specific Considerations

### Hardware Verticals
- **Data Source**: Retailer scraping + manufacturer specs
- **Pricing**: Real-time from retailers
- **Affiliate**: Per-retailer programs (Amazon Associates, Awin, etc.)
- **Comparison**: Spec-based Pareto optimization

### SaaS Verticals
- **Data Source**: Official pricing pages + G2/Capterra reviews
- **Pricing**: Often complex (tiers, usage-based)
- **Affiliate**: SaaS affiliate programs (PartnerStack, Impact)
- **Comparison**: Feature matrix + pricing calculator

### Financial Verticals
- **Data Source**: Official product pages + regulatory filings
- **Pricing**: APR, fees, rates (regulated disclosure)
- **Affiliate**: Financial lead generation (CPA model)
- **Comparison**: Rate comparison + eligibility check
- **Compliance**: Heavy regulation (MiFID II, consumer credit directives)

## Migration Checklist

When adding a new vertical:

```markdown
- [ ] Schema defined in `apps/workers/src/schemas/`
- [ ] Normalizer implemented in `apps/workers/src/normalizer/`
- [ ] Retailer config in `apps/workers/config/retailers/`
- [ ] Affiliate config in `apps/api/config/affiliates/`
- [ ] Category created in database
- [ ] Frontend config in `apps/web/lib/categories/`
- [ ] Tests for normalizer accuracy
- [ ] Test Pareto calculation with sample data
- [ ] Affiliate tracking verified
- [ ] SEO pages generated
```

## Related Documentation

- [Geographic Expansion](./geographic-expansion.md) - Multi-country support
- [Platform Expansion](./platform-expansion.md) - API and B2B
- [Pareto Optimization](../../domain/pareto-optimization.md) - Algorithm details

---

**Last Updated**: 2025-12-01
