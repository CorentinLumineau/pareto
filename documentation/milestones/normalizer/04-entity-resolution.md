# Phase 04: Entity Resolution

> **Product deduplication and matching across retailers**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      04 - Entity Resolution                            ║
║  Initiative: Normalizer                                        ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Match products across different retailers to enable price comparison. Same product (e.g., iPhone 15 Pro 256GB) should be linked across Amazon, Fnac, Cdiscount, etc.

## Tasks

- [ ] Implement EAN-based matching
- [ ] Create fuzzy title matching
- [ ] Build product fingerprinting
- [ ] Setup matching API endpoint
- [ ] Add confidence scoring

## Matching Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTITY RESOLUTION FLOW                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   New Product ─────► EAN Match? ─────► YES ─────► Link         │
│                          │                                      │
│                          NO                                     │
│                          │                                      │
│                          ▼                                      │
│                   Fingerprint Match? ─────► YES ─────► Link    │
│                          │                   (high conf)        │
│                          NO                                     │
│                          │                                      │
│                          ▼                                      │
│                   Fuzzy Title Match? ─────► YES ─────► Review  │
│                          │                   (medium conf)      │
│                          NO                                     │
│                          │                                      │
│                          ▼                                      │
│                   Create New Product                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Product Fingerprint

```python
# apps/workers/src/normalizer/entity/fingerprint.py
import re
from dataclasses import dataclass
from typing import Optional

@dataclass
class ProductFingerprint:
    """Unique product identifier components."""
    brand: str
    model: str
    storage: str | None
    color: str | None
    variant: str | None

    def to_key(self) -> str:
        """Generate matching key."""
        parts = [
            self.brand.lower(),
            self.model.lower(),
        ]
        if self.storage:
            parts.append(self.storage.lower())
        return "|".join(parts)

class FingerprintExtractor:
    """Extracts product fingerprints from titles."""

    # Known brands
    BRANDS = ["apple", "samsung", "google", "xiaomi", "oppo", "oneplus", "huawei"]

    # Storage patterns
    STORAGE_PATTERN = r"(\d+)\s*(go|gb|to|tb)"

    # Color patterns (French)
    COLORS = ["noir", "blanc", "bleu", "rouge", "vert", "rose", "violet",
              "titane", "naturel", "black", "white", "blue"]

    def extract(self, title: str, attributes: dict = None) -> ProductFingerprint:
        """Extract fingerprint from title and attributes."""
        title_lower = title.lower()

        # Extract brand
        brand = self._extract_brand(title_lower)

        # Extract model
        model = self._extract_model(title_lower, brand)

        # Extract storage
        storage = self._extract_storage(title_lower, attributes)

        # Extract color
        color = self._extract_color(title_lower, attributes)

        return ProductFingerprint(
            brand=brand,
            model=model,
            storage=storage,
            color=color,
            variant=None
        )

    def _extract_brand(self, title: str) -> str:
        """Extract brand from title."""
        for brand in self.BRANDS:
            if brand in title:
                return brand.capitalize()

        # Check for iPhone specifically
        if "iphone" in title:
            return "Apple"

        return "Unknown"

    def _extract_model(self, title: str, brand: str) -> str:
        """Extract model name."""
        # iPhone patterns
        if brand == "Apple":
            match = re.search(r"iphone\s*(\d+)\s*(pro\s*max|pro|plus|mini)?", title)
            if match:
                model = f"iPhone {match.group(1)}"
                if match.group(2):
                    model += f" {match.group(2).title()}"
                return model

        # Samsung Galaxy
        if brand == "Samsung":
            match = re.search(r"galaxy\s*(s|a|z)\s*(\d+)\s*(ultra|plus|\+)?", title)
            if match:
                model = f"Galaxy {match.group(1).upper()}{match.group(2)}"
                if match.group(3):
                    model += f" {match.group(3).title()}"
                return model

        return "Unknown Model"

    def _extract_storage(self, title: str, attributes: dict = None) -> str | None:
        """Extract storage capacity."""
        # From attributes first
        if attributes:
            for key in ["storage", "capacité", "mémoire"]:
                if key in attributes:
                    return attributes[key]

        # From title
        match = re.search(self.STORAGE_PATTERN, title, re.IGNORECASE)
        if match:
            size = int(match.group(1))
            unit = match.group(2).upper()
            if unit in ["GO", "GB"]:
                return f"{size}GB"
            elif unit in ["TO", "TB"]:
                return f"{size}TB"

        return None

    def _extract_color(self, title: str, attributes: dict = None) -> str | None:
        """Extract color."""
        # From attributes
        if attributes:
            for key in ["color", "couleur"]:
                if key in attributes:
                    return attributes[key]

        # From title
        for color in self.COLORS:
            if color in title:
                return color.capitalize()

        return None
```

## Matching Service

```python
# apps/workers/src/normalizer/entity/matcher.py
from dataclasses import dataclass
from typing import Optional
import httpx
from .fingerprint import FingerprintExtractor, ProductFingerprint

@dataclass
class MatchResult:
    """Product matching result."""
    matched: bool
    product_id: str | None
    confidence: float
    method: str  # "ean", "fingerprint", "fuzzy"

class ProductMatcher:
    """Matches products across retailers."""

    def __init__(self, catalog_api_url: str):
        self.catalog_url = catalog_api_url
        self.fingerprinter = FingerprintExtractor()

    def match(
        self,
        title: str,
        attributes: dict,
        ean: str | None = None
    ) -> MatchResult:
        """Find matching product in catalog."""

        # 1. Try EAN match (highest confidence)
        if ean:
            result = self._match_by_ean(ean)
            if result:
                return MatchResult(
                    matched=True,
                    product_id=result,
                    confidence=1.0,
                    method="ean"
                )

        # 2. Try fingerprint match
        fingerprint = self.fingerprinter.extract(title, attributes)
        result = self._match_by_fingerprint(fingerprint)
        if result:
            return MatchResult(
                matched=True,
                product_id=result["id"],
                confidence=result["confidence"],
                method="fingerprint"
            )

        # 3. Try fuzzy title match
        result = self._match_by_title(title)
        if result and result["confidence"] > 0.85:
            return MatchResult(
                matched=True,
                product_id=result["id"],
                confidence=result["confidence"],
                method="fuzzy"
            )

        return MatchResult(
            matched=False,
            product_id=None,
            confidence=0.0,
            method="none"
        )

    def _match_by_ean(self, ean: str) -> str | None:
        """Match by EAN code."""
        with httpx.Client() as client:
            response = client.get(
                f"{self.catalog_url}/internal/products/by-ean/{ean}"
            )
            if response.status_code == 200:
                return response.json()["id"]
        return None

    def _match_by_fingerprint(self, fp: ProductFingerprint) -> dict | None:
        """Match by product fingerprint."""
        with httpx.Client() as client:
            response = client.post(
                f"{self.catalog_url}/internal/products/match",
                json={
                    "fingerprint": fp.to_key(),
                    "brand": fp.brand,
                    "model": fp.model,
                    "storage": fp.storage,
                }
            )
            if response.status_code == 200:
                data = response.json()
                if data.get("matches"):
                    best = data["matches"][0]
                    return {"id": best["id"], "confidence": best["confidence"]}
        return None

    def _match_by_title(self, title: str) -> dict | None:
        """Fuzzy match by title."""
        with httpx.Client() as client:
            response = client.post(
                f"{self.catalog_url}/internal/products/search",
                json={"query": title, "limit": 1}
            )
            if response.status_code == 200:
                data = response.json()
                if data.get("results"):
                    best = data["results"][0]
                    return {"id": best["id"], "confidence": best["score"]}
        return None
```

## Integration with Normalizer

```python
# Updated task with entity resolution
from .entity.matcher import ProductMatcher

@shared_task(bind=True, max_retries=3)
def normalize_and_match(self, scrape_result: dict) -> dict:
    """Normalize and match product to catalog."""
    try:
        input = ScrapeInput(**scrape_result)
        extractor = get_extractor(input.retailer_id)
        product = extractor.extract(input)

        # Validate
        pipeline = ValidationPipeline()
        validation = pipeline.validate(product)
        if not validation.valid:
            raise ValueError(f"Validation failed: {validation.errors}")

        # Match to existing product
        matcher = ProductMatcher(settings.catalog_api_url)
        match = matcher.match(
            title=product.title,
            attributes=product.attributes,
            ean=product.attributes.get("ean")
        )

        # Send to catalog with match info
        send_to_catalog(product, match)

        return {
            "product": product.model_dump(),
            "match": {
                "matched": match.matched,
                "product_id": match.product_id,
                "confidence": match.confidence,
                "method": match.method,
            }
        }
    except Exception as e:
        self.retry(exc=e, countdown=60 * (self.request.retries + 1))
```

## Deliverables

- [ ] EAN-based exact matching
- [ ] Product fingerprinting system
- [ ] Fuzzy title matching
- [ ] Confidence scoring
- [ ] Catalog API integration
- [ ] Matching metrics dashboard

---

**Previous Phase**: [03-validation.md](./03-validation.md)
**Back to**: [Normalizer README](./README.md)
