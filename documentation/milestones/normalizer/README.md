# Normalizer Initiative

> **Parse brand pages and extract structured product data with 40+ attributes**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                          NORMALIZER INITIATIVE                                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     ⏳ PENDING (20% pre-done)                                       ║
║  Effort:     1.5 weeks (7 days)                                              ║
║  Depends:    Scraper                                                         ║
║  Unlocks:    Catalog                                                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Objective

Transform scraped HTML from brand websites into structured, normalized product data. Extract 40+ smartphone attributes and validate data quality.

**Key Change from Original Plan**: With brand-first approach, normalizers focus on **brand-specific parsing** rather than retailer-specific. Much simpler because:
- Brand pages have consistent structure
- All specs available in one place
- No price comparison logic needed (prices come from separate scrapers)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      NORMALIZER FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Brand HTML ─────► Brand Parser ─────► Normalized ─────► DB    │
│   (from scraper)    (Python)            Product         (API)   │
│                                                                 │
│                        │                   │                    │
│                        ▼                   ▼                    │
│                   selectolax          Pydantic                  │
│                   (fast HTML)         (validation)              │
│                                                                 │
│   Brand Parsers:                                                │
│   ├── AppleParser     → iPhone specs page                       │
│   ├── SamsungParser   → Galaxy specs page                       │
│   ├── XiaomiParser    → Mi/Redmi specs                          │
│   ├── GoogleParser    → Pixel specs                             │
│   └── OnePlusParser   → OnePlus specs                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Runtime | Python 3.14 | Main processing |
| Task Queue | Celery | Job processing |
| HTML Parser | selectolax | Fast HTML parsing |
| Validation | Pydantic v2 | Data validation |
| HTTP Client | httpx | Catalog API calls |

## Milestones

| # | Phase | Effort | Status | Description |
|---|-------|--------|--------|-------------|
| M1 | [Core Framework](./01-core.md) | 1d | ✅ Partial | Celery setup, base parser |
| M2 | [Brand Parsers](./02-brand-parsers.md) | 3d | ⏳ Pending | 5 brand-specific parsers |
| M3 | [Validation Pipeline](./03-validation.md) | 2d | ⏳ Pending | Quality checks, schema |
| M4 | [Catalog Integration](./04-catalog-integration.md) | 1d | ⏳ Pending | API integration |

## Progress: 20%

```
M1 Core Framework  [████████░░]  80% (Celery exists, base class needed)
M2 Brand Parsers   [░░░░░░░░░░]   0%
M3 Validation      [░░░░░░░░░░]   0%
M4 Catalog API     [░░░░░░░░░░]   0%
```

## Product Data Model

All smartphone attributes stored in JSONB:

```python
# apps/workers/src/normalizer/models.py
from pydantic import BaseModel, Field
from datetime import datetime

class SmartphoneAttributes(BaseModel):
    """40+ smartphone specifications"""

    # Display
    screen_size: float | None = Field(None, description="Screen size in inches")
    screen_resolution: str | None = Field(None, description="e.g., 2796x1290")
    screen_technology: str | None = Field(None, description="OLED, AMOLED, LCD")
    refresh_rate: int | None = Field(None, description="Hz, e.g., 120")

    # Performance
    chipset: str | None = Field(None, description="e.g., A18 Pro, Snapdragon 8 Gen 3")
    cpu_cores: int | None = Field(None, description="Number of cores")
    cpu_frequency: str | None = Field(None, description="e.g., 3.78 GHz")
    gpu: str | None = Field(None, description="GPU model")

    # Memory
    ram: int | None = Field(None, description="RAM in GB")
    storage: int | None = Field(None, description="Storage in GB")
    storage_expandable: bool | None = Field(None, description="Has SD card slot")

    # Camera
    main_camera_mp: int | None = Field(None, description="Main camera megapixels")
    main_camera_aperture: str | None = Field(None, description="e.g., f/1.8")
    ultrawide_camera_mp: int | None = Field(None, description="Ultrawide megapixels")
    telephoto_camera_mp: int | None = Field(None, description="Telephoto megapixels")
    optical_zoom: str | None = Field(None, description="e.g., 5x")
    front_camera_mp: int | None = Field(None, description="Selfie camera MP")
    video_max_resolution: str | None = Field(None, description="e.g., 4K@60fps")

    # Battery
    battery_capacity: int | None = Field(None, description="mAh")
    fast_charging: int | None = Field(None, description="Wattage, e.g., 45")
    wireless_charging: bool | None = Field(None, description="Supports Qi")

    # Connectivity
    five_g: bool | None = Field(None, description="5G support")
    wifi_version: str | None = Field(None, description="e.g., Wi-Fi 6E")
    bluetooth_version: str | None = Field(None, description="e.g., 5.3")
    nfc: bool | None = Field(None, description="NFC support")
    usb_type: str | None = Field(None, description="e.g., USB-C 3.2")

    # Physical
    weight: float | None = Field(None, description="Weight in grams")
    height: float | None = Field(None, description="Height in mm")
    width: float | None = Field(None, description="Width in mm")
    thickness: float | None = Field(None, description="Thickness in mm")
    water_resistance: str | None = Field(None, description="e.g., IP68")

    # Other
    os_version: str | None = Field(None, description="e.g., iOS 18, Android 15")
    colors: list[str] = Field(default_factory=list, description="Available colors")
    release_date: str | None = Field(None, description="Release date")


class NormalizedProduct(BaseModel):
    """Complete normalized product from brand website"""

    # Identity
    ean: str | None = Field(None, description="EAN/GTIN barcode")
    brand: str = Field(..., description="Brand name")
    model: str = Field(..., description="Model name")
    name: str = Field(..., description="Full product name")

    # Content
    image_url: str | None = Field(None, description="Official product image")
    description: str | None = Field(None, description="Product description")

    # Specs
    attributes: SmartphoneAttributes = Field(default_factory=SmartphoneAttributes)

    # Variants
    variants: list[dict] = Field(default_factory=list, description="Color/storage variants")

    # Metadata
    source_url: str = Field(..., description="Brand page URL")
    scraped_at: datetime = Field(default_factory=datetime.now)
```

## Brand Parser Interface

```python
# apps/workers/src/normalizer/parsers/base.py
from abc import ABC, abstractmethod
from selectolax.parser import HTMLParser

class BrandParser(ABC):
    """Base class for brand-specific HTML parsers"""

    @property
    @abstractmethod
    def brand_name(self) -> str:
        """Return brand name (e.g., 'Apple', 'Samsung')"""
        pass

    @abstractmethod
    def parse_product_list(self, html: str) -> list[str]:
        """Extract product URLs from catalog page"""
        pass

    @abstractmethod
    def parse_product(self, html: str, url: str) -> NormalizedProduct:
        """Parse single product page into normalized data"""
        pass

    def _extract_text(self, node, selector: str) -> str | None:
        """Helper to extract text from selector"""
        element = node.css_first(selector)
        return element.text(strip=True) if element else None

    def _extract_attr(self, node, selector: str, attr: str) -> str | None:
        """Helper to extract attribute from selector"""
        element = node.css_first(selector)
        return element.attributes.get(attr) if element else None
```

## Quality Metrics

| Metric | Target |
|--------|--------|
| EAN extraction rate | >90% |
| Attribute completeness | >80% (32+ of 40 attrs) |
| Validation pass rate | >95% |
| Processing latency | <200ms per product |

## What's Already Done

- Celery worker infrastructure (`apps/workers/`)
- Amazon extractor exists (useful as reference)
- Pydantic already in dependencies
- selectolax ready to use

## Deliverables

- [ ] BrandParser base class
- [ ] 5 brand parsers (Apple, Samsung, Xiaomi, Google, OnePlus)
- [ ] SmartphoneAttributes Pydantic model
- [ ] Validation pipeline with quality checks
- [ ] Catalog API integration (POST /internal/products)

---

**Depends on**: [Scraper](../scraper/)
**Unlocks**: [Catalog](../catalog/)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
