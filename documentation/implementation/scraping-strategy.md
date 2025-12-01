# Scraping Strategy - Brand-First Approach

> **Primary: Brand websites for specs | Secondary: Marketplaces for prices**

## Philosophy

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      BRAND-FIRST SCRAPING STRATEGY                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   "The brand knows their product best. Retailers know their prices."   │
│                                                                         │
│   BRAND WEBSITES (Primary)          MARKETPLACES (Secondary)            │
│   ────────────────────────          ────────────────────────            │
│   • Product catalog                 • Current prices                    │
│   • Official specifications         • Stock availability                │
│   • Canonical names                 • Affiliate links                   │
│   • High-quality images             • Retailer-specific deals           │
│   • EAN/GTIN codes                                                      │
│   • All variants (color, storage)                                       │
│                                                                         │
│   Frequency: Weekly / On release    Frequency: Every 4 hours            │
│   Difficulty: LOW (minimal bot)     Difficulty: HIGH (DataDome, etc.)   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Why Brand-First?

### 1. Data Quality

| Source | Spec Completeness | Accuracy | Consistency |
|--------|-------------------|----------|-------------|
| **Brand Website** | 100% | 100% | ✅ Structured |
| Amazon | 60-80% | 90% | ❌ Varies |
| Fnac | 50-70% | 85% | ❌ Varies |
| Cdiscount | 40-60% | 80% | ❌ Varies |

### 2. Scraping Complexity

| Source | Anti-Bot | Rate Limits | Page Structure |
|--------|----------|-------------|----------------|
| **apple.com** | None | Relaxed | Clean, semantic |
| **samsung.com** | Minimal | Moderate | Structured JSON-LD |
| **amazon.fr** | DataDome | Aggressive | Complex, changes often |
| **fnac.com** | DataDome | Aggressive | Inconsistent |

### 3. Business Logic

```
Brand websites:
├─ Have EVERY product they sell
├─ Have EVERY variant (256GB Blue, 512GB Black, etc.)
├─ Have OFFICIAL specs (not user-submitted)
├─ Update specs when product is announced
└─ Don't change specs after release

Marketplaces:
├─ May not list all variants
├─ Specs often incomplete or wrong
├─ But have REAL PRICES users pay
└─ And have AFFILIATE PROGRAMS for revenue
```

## Architecture

### Data Flow

```
                          BRAND-FIRST DATA FLOW

    ┌─────────────────────────────────────────────────────────────────┐
    │                     1. PRODUCT DISCOVERY                        │
    │                        (Brand Websites)                         │
    └─────────────────────────────────────────────────────────────────┘
                                    │
    ┌───────────┬───────────┬───────┴───────┬───────────┬────────────┐
    │           │           │               │           │            │
    ▼           ▼           ▼               ▼           ▼            ▼
┌───────┐  ┌────────┐  ┌────────┐     ┌────────┐  ┌────────┐  ┌──────────┐
│ Apple │  │Samsung │  │ Xiaomi │     │ Google │  │OnePlus │  │   ...    │
└───┬───┘  └───┬────┘  └───┬────┘     └───┬────┘  └───┬────┘  └────┬─────┘
    │          │           │              │           │            │
    └──────────┴───────────┴──────┬───────┴───────────┴────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │      products table     │
                    │  ─────────────────────  │
                    │  id, name, brand, ean   │
                    │  attributes (JSONB)     │  ← COMPLETE SPECS
                    │  image_url              │
                    │  source: "brand"        │
                    └────────────┬────────────┘
                                 │
                                 │ EAN/GTIN matching
                                 ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                      2. PRICE DISCOVERY                         │
    │                       (Marketplaces)                            │
    └─────────────────────────────────────────────────────────────────┘
                                 │
    ┌──────────┬─────────┬───────┴───────┬──────────┬─────────────────┐
    │          │         │               │          │                 │
    ▼          ▼         ▼               ▼          ▼                 ▼
┌────────┐ ┌──────┐ ┌─────────┐  ┌───────────┐ ┌─────────┐  ┌─────────────┐
│Amazon  │ │ Fnac │ │ Darty   │  │ Boulanger │ │Cdiscount│  │    LDLC     │
└───┬────┘ └──┬───┘ └────┬────┘  └─────┬─────┘ └────┬────┘  └──────┬──────┘
    │         │          │             │            │              │
    └─────────┴──────────┴─────┬───────┴────────────┴──────────────┘
                               │
                               ▼
                    ┌─────────────────────────┐
                    │       offers table      │
                    │  ─────────────────────  │
                    │  product_id (FK)        │
                    │  retailer_id            │
                    │  price                  │  ← REAL PRICES
                    │  in_stock               │
                    │  affiliate_url          │
                    └─────────────────────────┘
```

### Scraping Schedule

```yaml
# Brand websites: Complete catalog scrape
brand_catalog_scrape:
  frequency: weekly
  trigger: also on new product announcement
  scope: full_catalog
  sources:
    - apple.com/fr/shop/iphone
    - samsung.com/fr/smartphones
    - mi.com/fr/phone
    - store.google.com/fr/category/phones
    - oneplus.com/fr/store
  output: products table (INSERT or UPDATE attributes)

# Marketplace: Price-only scrape for KNOWN products
marketplace_price_scrape:
  frequency: every_4_hours
  scope: products_in_database_only  # Only scrape what we know
  sources:
    - amazon.fr
    - fnac.com
    - darty.com
    - boulanger.com
    - cdiscount.com
    - ldlc.com
  strategy: search_by_ean_or_model  # Don't browse, search directly
  output: offers table (UPSERT price, stock)
```

## Brand Extractors

### Supported Brands

| Brand | URL | Products | Anti-Bot | Data Format |
|-------|-----|----------|----------|-------------|
| **Apple** | apple.com/fr | iPhones, iPads, Macs | None | JSON-LD |
| **Samsung** | samsung.com/fr | Galaxy phones, tablets | Minimal | JSON-LD |
| **Xiaomi** | mi.com/fr | Redmi, Poco, Xiaomi | None | HTML |
| **Google** | store.google.com/fr | Pixel phones | None | JSON-LD |
| **OnePlus** | oneplus.com/fr | OnePlus phones | None | JSON-LD |
| **Oppo** | oppo.com/fr | Oppo, Reno | None | HTML |
| **Huawei** | consumer.huawei.com/fr | P series, Mate | Minimal | HTML |
| **Sony** | sony.fr | Xperia | None | HTML |
| **Motorola** | motorola.fr | Edge, Moto G | None | HTML |
| **Nothing** | nothing.tech | Phone 1, 2 | None | HTML |

### Extractor Interface

```python
# apps/workers/src/normalizer/extractors/brand_base.py

class BrandExtractor(ABC):
    """Base class for brand website extractors."""

    brand_name: str
    brand_slug: str
    base_url: str
    catalog_urls: list[str]  # Category pages to scrape

    @abstractmethod
    def extract_catalog(self, html: str) -> list[BrandProduct]:
        """Extract all products from catalog page."""
        pass

    @abstractmethod
    def extract_product(self, html: str) -> BrandProduct | None:
        """Extract full specs from product page."""
        pass

    def get_catalog_urls(self) -> list[str]:
        """URLs to scrape for product discovery."""
        return self.catalog_urls


@dataclass
class BrandProduct:
    """Product data extracted from brand website."""

    # Identifiers
    name: str
    brand: str
    model: str
    ean: str | None  # EAN-13 if available
    sku: str | None  # Brand's internal SKU

    # Media
    image_url: str
    images: list[str]

    # Specs (ALL of them)
    attributes: dict[str, Any]

    # Variants
    variants: list[ProductVariant]  # Color, storage combinations

    # Metadata
    source_url: str
    msrp: float | None  # Official price (not real market price)


@dataclass
class ProductVariant:
    """Product variant (color, storage, etc.)."""

    sku: str
    ean: str | None
    color: str | None
    storage: int | None  # GB
    ram: int | None  # GB
    msrp: float | None
    image_url: str | None
```

### Example: Apple Extractor

```python
# apps/workers/src/normalizer/extractors/apple.py

class AppleExtractor(BrandExtractor):
    """Extractor for Apple.com product pages."""

    brand_name = "Apple"
    brand_slug = "apple"
    base_url = "https://www.apple.com/fr"
    catalog_urls = [
        "/shop/buy-iphone",
        "/shop/buy-ipad",
        "/shop/buy-mac",
    ]

    def extract_product(self, html: str) -> BrandProduct | None:
        soup = BeautifulSoup(html, "lxml")

        # Apple uses JSON-LD structured data
        json_ld = self._extract_json_ld(soup)
        if not json_ld:
            return None

        # Extract from structured data
        name = json_ld.get("name", "")
        sku = json_ld.get("sku", "")
        gtin = json_ld.get("gtin13") or json_ld.get("gtin")

        # Extract ALL specs from tech specs section
        attributes = {}
        specs_section = soup.select(".techspecs-section .techspecs-row")
        for row in specs_section:
            label = row.select_one(".techspecs-row-label")
            value = row.select_one(".techspecs-row-value")
            if label and value:
                key = self._normalize_key(label.get_text())
                attributes[key] = self._parse_value(value.get_text())

        # Extract variants (colors, storage)
        variants = self._extract_variants(soup)

        return BrandProduct(
            name=name,
            brand="Apple",
            model=self._extract_model(name),  # "iPhone 16 Pro"
            ean=gtin,
            sku=sku,
            image_url=json_ld.get("image", ""),
            images=self._extract_gallery(soup),
            attributes=attributes,
            variants=variants,
            source_url=self.current_url,
            msrp=self._extract_price(json_ld),
        )

    def _extract_variants(self, soup: BeautifulSoup) -> list[ProductVariant]:
        """Extract all color/storage variants."""
        variants = []

        # Apple lists variants in product selectors
        storage_options = soup.select("[data-storage-option]")
        color_options = soup.select("[data-color-option]")

        for storage in storage_options:
            for color in color_options:
                variant_sku = f"{storage['data-sku']}-{color['data-color']}"
                variants.append(ProductVariant(
                    sku=variant_sku,
                    ean=storage.get("data-gtin"),
                    color=color.get("data-color"),
                    storage=int(storage.get("data-storage", 0)),
                    ram=None,  # Apple doesn't differentiate RAM
                    msrp=float(storage.get("data-price", 0)),
                    image_url=color.get("data-image"),
                ))

        return variants
```

### Example: Samsung Extractor

```python
# apps/workers/src/normalizer/extractors/samsung.py

class SamsungExtractor(BrandExtractor):
    """Extractor for Samsung.com product pages."""

    brand_name = "Samsung"
    brand_slug = "samsung"
    base_url = "https://www.samsung.com/fr"
    catalog_urls = [
        "/smartphones/tous-les-smartphones/",
        "/tablets/all-tablets/",
    ]

    def extract_product(self, html: str) -> BrandProduct | None:
        soup = BeautifulSoup(html, "lxml")

        # Samsung embeds product data in a script tag
        product_data = self._extract_product_json(soup)
        if not product_data:
            return None

        # Comprehensive specs
        attributes = {
            # Display
            "screen_size": product_data.get("displaySize"),
            "screen_resolution": product_data.get("displayResolution"),
            "screen_technology": product_data.get("displayType"),
            "refresh_rate": product_data.get("refreshRate"),

            # Performance
            "cpu": product_data.get("processor"),
            "ram": product_data.get("memory"),
            "storage": product_data.get("storage"),

            # Camera
            "rear_camera_mp": product_data.get("rearCameraMP"),
            "front_camera_mp": product_data.get("frontCameraMP"),
            "camera_features": product_data.get("cameraFeatures"),

            # Battery
            "battery_mah": product_data.get("batteryCapacity"),
            "fast_charging_w": product_data.get("fastCharging"),
            "wireless_charging": product_data.get("wirelessCharging"),

            # Connectivity
            "5g": product_data.get("5gSupport"),
            "wifi": product_data.get("wifiVersion"),
            "bluetooth": product_data.get("bluetoothVersion"),
            "nfc": product_data.get("nfcSupport"),

            # Physical
            "weight_g": product_data.get("weight"),
            "dimensions": product_data.get("dimensions"),
            "water_resistance": product_data.get("ipRating"),

            # Software
            "os": product_data.get("operatingSystem"),
            "one_ui_version": product_data.get("oneUIVersion"),
        }

        # Remove None values
        attributes = {k: v for k, v in attributes.items() if v is not None}

        return BrandProduct(
            name=product_data.get("name", ""),
            brand="Samsung",
            model=product_data.get("modelName", ""),
            ean=product_data.get("ean"),
            sku=product_data.get("modelCode"),
            image_url=product_data.get("image", ""),
            images=product_data.get("gallery", []),
            attributes=attributes,
            variants=self._extract_variants(product_data),
            source_url=self.current_url,
            msrp=product_data.get("price"),
        )
```

## Marketplace Price Scraping

### Simplified Approach

Since we already KNOW the products (from brand sites), marketplace scraping becomes much simpler:

```python
# apps/workers/src/scraper/price_scraper.py

class MarketplacePriceScraper:
    """Scrape prices for KNOWN products only."""

    def scrape_prices_for_product(self, product: Product) -> list[Offer]:
        """
        Search for a known product on marketplaces.
        Uses EAN or model name to find exact match.
        """
        offers = []

        for retailer in self.retailers:
            # Search by EAN first (most reliable)
            if product.ean:
                offer = retailer.search_by_ean(product.ean)
                if offer:
                    offers.append(offer)
                    continue

            # Fallback: Search by model name
            offer = retailer.search_by_query(
                f"{product.brand} {product.model}"
            )
            if offer and self._is_same_product(product, offer):
                offers.append(offer)

        return offers


class AmazonPriceScraper:
    """Amazon price-only scraper."""

    def search_by_ean(self, ean: str) -> Offer | None:
        """Search Amazon by EAN barcode."""
        # Amazon search: https://www.amazon.fr/s?k={ean}
        url = f"https://www.amazon.fr/s?k={ean}"
        html = self.fetch(url)

        soup = BeautifulSoup(html, "lxml")
        result = soup.select_one("[data-component-type='s-search-result']")

        if not result:
            return None

        price_elem = result.select_one(".a-price .a-offscreen")
        if not price_elem:
            return None

        return Offer(
            retailer="amazon_fr",
            price=self._parse_price(price_elem.text),
            url=self._extract_url(result),
            in_stock=self._check_stock(result),
        )
```

### Price Scraping Flow

```
                    PRICE-ONLY SCRAPING (Every 4h)

    ┌──────────────────────────────────────────────────────────────┐
    │  SELECT id, ean, brand, model FROM products                  │
    │  WHERE ean IS NOT NULL                                       │
    └──────────────────────────────────────────────────────────────┘
                                │
                                ▼
    ┌──────────────────────────────────────────────────────────────┐
    │  For each product:                                           │
    │    1. Search Amazon by EAN → Get price or NULL               │
    │    2. Search Fnac by EAN → Get price or NULL                 │
    │    3. Search Darty by EAN → Get price or NULL                │
    │    4. ... repeat for all retailers                           │
    └──────────────────────────────────────────────────────────────┘
                                │
                                ▼
    ┌──────────────────────────────────────────────────────────────┐
    │  UPSERT INTO offers (product_id, retailer_id, price, ...)   │
    │  INSERT INTO price_history (time, product_id, ...)          │
    └──────────────────────────────────────────────────────────────┘
```

## Benefits of Brand-First

### 1. Complete Attribute Coverage

```
Brand Website Data:
├─ screen_size: 6.3"
├─ screen_resolution: "2622x1206"
├─ screen_technology: "Super Retina XDR OLED"
├─ refresh_rate: 120
├─ peak_brightness: 2000
├─ cpu: "A18 Pro"
├─ cpu_cores: 6
├─ gpu_cores: 6
├─ neural_engine_cores: 16
├─ ram: 8
├─ storage: 256
├─ rear_camera_main: 48
├─ rear_camera_ultrawide: 12
├─ rear_camera_telephoto: 12
├─ front_camera: 12
├─ video_4k_fps: 120
├─ battery_mah: 4685
├─ fast_charging_w: 45
├─ wireless_charging: true
├─ magsafe: true
├─ 5g: true
├─ wifi: "WiFi 7"
├─ bluetooth: "5.3"
├─ uwb: true
├─ nfc: true
├─ satellite: true
├─ usb_type: "USB-C"
├─ usb_version: "3.0"
├─ weight_g: 199
├─ height_mm: 149.6
├─ width_mm: 71.5
├─ depth_mm: 8.25
├─ water_resistance: "IP68"
├─ material: "Titanium"
└─ ... (40+ more attributes)

vs Amazon Data:
├─ screen_size: 6.3"
├─ storage: 256
├─ ram: (often missing)
├─ battery: (often missing)
└─ ... (10-15 attributes, inconsistent)
```

### 2. Better Pareto Optimization

More attributes = More comparison dimensions = Better Pareto frontiers

```python
# With brand data, users can compare on:
objectives = [
    {"name": "price", "sense": "min"},
    {"name": "battery_mah", "sense": "max"},
    {"name": "cpu_benchmark", "sense": "max"},
    {"name": "camera_score", "sense": "max"},
    {"name": "weight_g", "sense": "min"},
    {"name": "screen_brightness", "sense": "max"},
    {"name": "fast_charging_w", "sense": "max"},
    # ... many more options
]
```

### 3. Simpler Marketplace Scraping

```
Before (marketplace-first):
├─ Scrape product pages for specs (complex, anti-bot)
├─ Parse inconsistent HTML structures
├─ Handle missing data
├─ Deduplicate across retailers
└─ Merge incomplete data

After (brand-first):
├─ Product already exists with complete specs
├─ Just search by EAN (simple)
├─ Extract only: price, stock, URL
├─ Much less data to parse
└─ No deduplication needed (EAN is key)
```

## Migration Path

Since you already have the Amazon extractor, here's how to migrate:

### Phase 1: Add Brand Extractors (Week 1-2)
```
1. Create AppleExtractor
2. Create SamsungExtractor
3. Create XiaomiExtractor
4. Run initial catalog scrape
5. Populate products table with complete specs
```

### Phase 2: Simplify Marketplace Scrapers (Week 3)
```
1. Convert AmazonExtractor to price-only mode
2. Add EAN-based search
3. Remove spec extraction (not needed anymore)
4. Repeat for Fnac, Darty, etc.
```

### Phase 3: Update Data Flow (Week 4)
```
1. Brand scraper runs weekly
2. Price scraper runs every 4h
3. Entity resolution simplified (EAN match only)
4. UI shows brand-sourced specs with marketplace prices
```

---

**Last Updated**: 2025-12-01
