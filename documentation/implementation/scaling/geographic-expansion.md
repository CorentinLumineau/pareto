# Geographic Expansion - Multi-Country Architecture

> **How to scale Pareto across countries and regions**

## Overview

Pareto starts in France and expands systematically:
1. **France** (MVP) - Validate product-market fit
2. **EU Core** (Phase 2) - Germany, Spain, Italy, UK
3. **EU Extended** (Phase 3) - Benelux, Nordics, Austria, Switzerland
4. **Global** (Phase 4) - US, Canada, Australia, APAC

## Expansion Roadmap

```
                    GEOGRAPHIC EXPANSION TIMELINE

Q1 2025                Q2 2025               Q3 2025             Q4 2025+
────────               ────────              ────────            ─────────
FRANCE                 GERMANY               EU EXTENDED         GLOBAL
- FR retailers         - DE retailers        - NL, BE, LU        - US
- EUR                  - EUR                 - AT, CH            - CA
- French locale        - German locale       - SE, NO, DK, FI    - AU/NZ

                       SPAIN
                       - ES retailers
                       - EUR
                       - Spanish locale

                       ITALY                 UK
                       - IT retailers        - UK retailers
                       - EUR                 - GBP
                       - Italian locale      - English locale
```

## Architecture for Multi-Country

### Database Schema

```sql
-- Countries table
CREATE TABLE countries (
    code CHAR(2) PRIMARY KEY,  -- ISO 3166-1 alpha-2
    name TEXT NOT NULL,
    currency_code CHAR(3) NOT NULL,  -- ISO 4217
    locale TEXT NOT NULL,  -- IETF BCP 47
    timezone TEXT NOT NULL,
    enabled BOOLEAN DEFAULT false,
    launched_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert initial countries
INSERT INTO countries VALUES
    ('FR', 'France', 'EUR', 'fr-FR', 'Europe/Paris', true, NOW()),
    ('DE', 'Germany', 'EUR', 'de-DE', 'Europe/Berlin', false, NULL),
    ('ES', 'Spain', 'EUR', 'es-ES', 'Europe/Madrid', false, NULL),
    ('IT', 'Italy', 'EUR', 'it-IT', 'Europe/Rome', false, NULL),
    ('GB', 'United Kingdom', 'GBP', 'en-GB', 'Europe/London', false, NULL);

-- Retailers are country-specific
CREATE TABLE retailers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code CHAR(2) NOT NULL REFERENCES countries(code),
    slug TEXT NOT NULL,
    name TEXT NOT NULL,
    base_url TEXT NOT NULL,
    affiliate_program TEXT,
    enabled BOOLEAN DEFAULT true,
    UNIQUE(country_code, slug)
);

-- Prices include currency
CREATE TABLE offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id),
    retailer_id UUID NOT NULL REFERENCES retailers(id),
    price DECIMAL(10,2) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    condition TEXT DEFAULT 'new',
    url TEXT NOT NULL,
    affiliate_url TEXT,
    scraped_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(product_id, retailer_id, condition)
);

-- Price history with TimescaleDB
CREATE TABLE price_history (
    time TIMESTAMPTZ NOT NULL,
    product_id UUID NOT NULL,
    retailer_id UUID NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    currency_code CHAR(3) NOT NULL
);
SELECT create_hypertable('price_history', 'time');
```

### Currency Handling

```go
// apps/api/internal/shared/currency/converter.go
package currency

import (
    "context"
    "time"
)

type Converter struct {
    rates map[string]float64  // Rates vs EUR base
    lastUpdate time.Time
}

// Convert between currencies
func (c *Converter) Convert(amount float64, from, to string) (float64, error) {
    if from == to {
        return amount, nil
    }

    // Convert to EUR first
    eurAmount := amount / c.rates[from]
    // Then to target currency
    return eurAmount * c.rates[to], nil
}

// NormalizeToEUR for Pareto comparison
func (c *Converter) NormalizeToEUR(price float64, currency string) float64 {
    if currency == "EUR" {
        return price
    }
    return price / c.rates[currency]
}
```

### Retailer Registry

```yaml
# apps/workers/config/retailers/registry.yaml

# France
retailers:
  fr:
    - slug: amazon_fr
      name: Amazon France
      url: https://www.amazon.fr
      affiliate: amazon_associates
      categories: [smartphones, laptops, tablets, headphones]

    - slug: fnac
      name: Fnac
      url: https://www.fnac.com
      affiliate: awin
      categories: [smartphones, laptops, tablets]

    - slug: darty
      name: Darty
      url: https://www.darty.com
      affiliate: awin
      categories: [smartphones, laptops, tablets]

    - slug: boulanger
      name: Boulanger
      url: https://www.boulanger.com
      affiliate: tradedoubler
      categories: [smartphones, laptops, tablets, headphones]

    - slug: cdiscount
      name: Cdiscount
      url: https://www.cdiscount.com
      affiliate: awin
      categories: [smartphones, laptops, tablets]

# Germany
  de:
    - slug: amazon_de
      name: Amazon Deutschland
      url: https://www.amazon.de
      affiliate: amazon_associates
      categories: [smartphones, laptops, tablets, headphones]

    - slug: mediamarkt
      name: MediaMarkt
      url: https://www.mediamarkt.de
      affiliate: awin
      categories: [smartphones, laptops, tablets]

    - slug: saturn
      name: Saturn
      url: https://www.saturn.de
      affiliate: awin
      categories: [smartphones, laptops, tablets]

    - slug: otto
      name: Otto
      url: https://www.otto.de
      affiliate: awin
      categories: [smartphones, laptops]

# Spain
  es:
    - slug: amazon_es
      name: Amazon España
      url: https://www.amazon.es
      affiliate: amazon_associates
      categories: [smartphones, laptops, tablets]

    - slug: pccomponentes
      name: PcComponentes
      url: https://www.pccomponentes.com
      affiliate: awin
      categories: [smartphones, laptops, tablets, headphones]

    - slug: mediamarkt_es
      name: MediaMarkt España
      url: https://www.mediamarkt.es
      affiliate: awin
      categories: [smartphones, laptops, tablets]

# UK
  gb:
    - slug: amazon_uk
      name: Amazon UK
      url: https://www.amazon.co.uk
      affiliate: amazon_associates
      categories: [smartphones, laptops, tablets, headphones]

    - slug: currys
      name: Currys
      url: https://www.currys.co.uk
      affiliate: awin
      categories: [smartphones, laptops, tablets]

    - slug: argos
      name: Argos
      url: https://www.argos.co.uk
      affiliate: awin
      categories: [smartphones, laptops, tablets]

    - slug: johnlewis
      name: John Lewis
      url: https://www.johnlewis.com
      affiliate: awin
      categories: [smartphones, laptops, tablets]
```

### Internationalization (i18n)

```typescript
// apps/web/lib/i18n/config.ts
export const locales = ['fr', 'de', 'es', 'it', 'en'] as const;
export type Locale = typeof locales[number];

export const localeConfig: Record<Locale, {
  country: string;
  currency: string;
  dateFormat: string;
  numberFormat: Intl.NumberFormatOptions;
}> = {
  fr: {
    country: 'FR',
    currency: 'EUR',
    dateFormat: 'dd/MM/yyyy',
    numberFormat: { style: 'currency', currency: 'EUR' },
  },
  de: {
    country: 'DE',
    currency: 'EUR',
    dateFormat: 'dd.MM.yyyy',
    numberFormat: { style: 'currency', currency: 'EUR' },
  },
  es: {
    country: 'ES',
    currency: 'EUR',
    dateFormat: 'dd/MM/yyyy',
    numberFormat: { style: 'currency', currency: 'EUR' },
  },
  it: {
    country: 'IT',
    currency: 'EUR',
    dateFormat: 'dd/MM/yyyy',
    numberFormat: { style: 'currency', currency: 'EUR' },
  },
  en: {
    country: 'GB',
    currency: 'GBP',
    dateFormat: 'dd/MM/yyyy',
    numberFormat: { style: 'currency', currency: 'GBP' },
  },
};
```

```typescript
// apps/web/lib/i18n/messages/fr.json
{
  "common": {
    "search": "Rechercher",
    "compare": "Comparer",
    "price": "Prix",
    "best_price": "Meilleur prix"
  },
  "comparison": {
    "pareto_optimal": "Choix optimal Pareto",
    "dominated": "Dominé par d'autres produits",
    "objectives": "Critères de comparaison"
  },
  "categories": {
    "smartphones": "Smartphones",
    "laptops": "Ordinateurs portables",
    "tablets": "Tablettes"
  }
}
```

### URL Structure

```
# Country-specific subdomains
https://fr.pareto.com/smartphones
https://de.pareto.com/smartphones
https://es.pareto.com/smartphones
https://uk.pareto.com/smartphones

# Or path-based (alternative)
https://pareto.com/fr/smartphones
https://pareto.com/de/smartphones
```

```typescript
// apps/web/middleware.ts (Next.js 16)
import { NextRequest, NextResponse } from 'next/server';
import { locales, Locale } from './lib/i18n/config';

export function middleware(request: NextRequest) {
  // Get country from subdomain or path
  const hostname = request.headers.get('host') || '';
  const subdomain = hostname.split('.')[0];

  let locale: Locale = 'fr'; // Default

  if (locales.includes(subdomain as Locale)) {
    locale = subdomain as Locale;
  }

  // Set locale header for server components
  const response = NextResponse.next();
  response.headers.set('x-locale', locale);

  return response;
}
```

## Compliance Per Region

### GDPR (All EU)
```yaml
gdpr:
  cookie_consent: required
  data_retention_days: 730
  right_to_deletion: true
  data_portability: true
  dpo_email: dpo@pareto.com
```

### Country-Specific
```yaml
# France
fr:
  legal_entity: SAS
  vat_rate: 0.20
  consumer_protection: "Loi Hamon"
  price_display: "TTC obligatoire"

# Germany
de:
  legal_entity: GmbH
  vat_rate: 0.19
  consumer_protection: "Widerrufsrecht"
  price_display: "Bruttopreis"
  impressum: required

# UK (post-Brexit)
gb:
  legal_entity: Ltd
  vat_rate: 0.20
  consumer_protection: "Consumer Rights Act 2015"
  cookies: "UK GDPR + PECR"
```

## Adding a New Country

### Step 1: Enable Country
```sql
UPDATE countries SET enabled = true, launched_at = NOW()
WHERE code = 'DE';
```

### Step 2: Configure Retailers
```bash
# Add retailer configs to registry
vim apps/workers/config/retailers/registry.yaml

# Add scraper configs
vim apps/workers/config/scrapers/de/amazon_de.yaml
vim apps/workers/config/scrapers/de/mediamarkt.yaml
```

### Step 3: Configure Affiliates
```bash
# Sign up for affiliate programs
# Amazon DE: associates.amazon.de
# Awin DE: awin.com (MediaMarkt, Saturn, Otto)

# Add affiliate configs
vim apps/api/config/affiliates/de.yaml
```

### Step 4: Add Translations
```bash
# Add translation file
vim apps/web/lib/i18n/messages/de.json

# Add locale config
vim apps/web/lib/i18n/config.ts
```

### Step 5: Deploy
```bash
# Add subdomain to Cloudflare
# de.pareto.com -> VPS

# Update DNS
# Enable feature flag
```

### Checklist
```markdown
- [ ] Country enabled in database
- [ ] Retailers configured and tested
- [ ] Affiliate programs active
- [ ] Translations complete
- [ ] Legal compliance reviewed
- [ ] DNS configured
- [ ] SSL certificate issued
- [ ] Feature flag enabled
- [ ] Launch announcement
```

## Multi-Country Pareto Comparison

### Cross-Border Price Comparison

```python
# apps/workers/src/pareto/multi_country.py
def compare_across_countries(
    product_ids: list[str],
    countries: list[str],
    user_country: str,
    objectives: list[Objective]
) -> ComparisonResult:
    """
    Compare products across countries.
    Normalize prices to user's currency.
    """
    offers = fetch_offers(product_ids, countries)

    # Convert all prices to user's currency
    normalized_offers = []
    for offer in offers:
        price_eur = currency_converter.to_eur(
            offer.price, offer.currency
        )
        price_user = currency_converter.from_eur(
            price_eur, user_country_currency(user_country)
        )
        normalized_offers.append({
            **offer,
            "price_normalized": price_user,
            "includes_shipping": estimate_shipping(
                offer.country, user_country
            )
        })

    return calculate_pareto(normalized_offers, objectives)
```

## Related Documentation

- [Vertical Expansion](./vertical-expansion.md) - Category scaling
- [Platform Expansion](./platform-expansion.md) - API and B2B
- [Infrastructure Scaling](./infrastructure-scaling.md) - VPS to K8s

---

**Last Updated**: 2025-12-01
