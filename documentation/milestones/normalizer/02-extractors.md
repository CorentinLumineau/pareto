# Phase 02: Retailer Extractors

> **6 retailer-specific extraction implementations**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      02 - Retailer Extractors                          ║
║  Initiative: Normalizer                                        ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     4 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Implement extractors for all 6 MVP retailers with robust HTML parsing.

## Tasks

- [ ] Amazon.fr extractor (ASIN, price, attributes)
- [ ] Fnac.com extractor (EAN, marketplace handling)
- [ ] Cdiscount.com extractor (SKU, flash sales)
- [ ] Darty.com extractor (CODIC, stock)
- [ ] Boulanger.com extractor (Ref, eco-part)
- [ ] LDLC.com extractor (Ref, variants)
- [ ] Integration tests with real HTML samples

## Extractor Registry

```python
# apps/workers/src/normalizer/extractors/__init__.py
from .amazon import AmazonExtractor
from .fnac import FnacExtractor
from .cdiscount import CdiscountExtractor
from .darty import DartyExtractor
from .boulanger import BoulangerExtractor
from .ldlc import LdlcExtractor
from ..base import BaseExtractor

EXTRACTORS: dict[str, type[BaseExtractor]] = {
    "amazon_fr": AmazonExtractor,
    "fnac": FnacExtractor,
    "cdiscount": CdiscountExtractor,
    "darty": DartyExtractor,
    "boulanger": BoulangerExtractor,
    "ldlc": LdlcExtractor,
}

def get_extractor(retailer_id: str) -> BaseExtractor:
    """Get extractor instance for retailer."""
    if retailer_id not in EXTRACTORS:
        raise ValueError(f"Unknown retailer: {retailer_id}")
    return EXTRACTORS[retailer_id]()
```

## Amazon.fr Extractor

```python
# apps/workers/src/normalizer/extractors/amazon.py
import re
from ..base import BaseExtractor

class AmazonExtractor(BaseExtractor):
    retailer_id = "amazon_fr"

    # Price selectors in priority order
    PRICE_SELECTORS = [
        "#priceblock_ourprice",
        "#priceblock_dealprice",
        ".a-price .a-offscreen",
        "#corePrice_feature_div .a-offscreen",
    ]

    def extract_external_id(self) -> str:
        """Extract ASIN from URL or page."""
        # Try URL pattern first
        url = self.parser.css_first('link[rel="canonical"]')
        if url:
            match = re.search(r"/dp/([A-Z0-9]{10})", url.attributes.get("href", ""))
            if match:
                return match.group(1)

        # Fallback to hidden input
        asin = self.parser.css_first('input[name="ASIN"]')
        if asin:
            return asin.attributes.get("value", "")

        raise ValueError("Could not extract ASIN")

    def extract_title(self) -> str:
        """Extract product title."""
        title = self.parser.css_first("#productTitle")
        if title:
            return title.text(strip=True)
        raise ValueError("Could not extract title")

    def extract_price(self) -> float:
        """Extract price from various locations."""
        for selector in self.PRICE_SELECTORS:
            element = self.parser.css_first(selector)
            if element:
                text = element.text(strip=True)
                # Parse "1 229,99 €" format
                price = re.sub(r"[^\d,.]", "", text).replace(",", ".")
                return float(price)
        raise ValueError("Could not extract price")

    def extract_brand(self) -> str | None:
        """Extract brand from product details."""
        brand = self.parser.css_first("#bylineInfo")
        if brand:
            text = brand.text(strip=True)
            return text.replace("Marque :", "").replace("Visiter la boutique", "").strip()
        return None

    def extract_attributes(self) -> dict:
        """Extract technical attributes."""
        attrs = {}

        # Product details table
        rows = self.parser.css("#productDetails_techSpec_section_1 tr")
        for row in rows:
            th = row.css_first("th")
            td = row.css_first("td")
            if th and td:
                key = th.text(strip=True).lower().replace(" ", "_")
                attrs[key] = td.text(strip=True)

        return attrs
```

## Fnac.com Extractor

```python
# apps/workers/src/normalizer/extractors/fnac.py
import re
from ..base import BaseExtractor

class FnacExtractor(BaseExtractor):
    retailer_id = "fnac"

    def extract_external_id(self) -> str:
        """Extract EAN or Fnac ref."""
        # Try EAN from structured data
        ld_json = self.parser.css_first('script[type="application/ld+json"]')
        if ld_json:
            import json
            data = json.loads(ld_json.text())
            if "gtin13" in data:
                return data["gtin13"]

        # Fallback to URL pattern
        url = self.parser.css_first('link[rel="canonical"]')
        if url:
            match = re.search(r"/a(\d+)/", url.attributes.get("href", ""))
            if match:
                return f"fnac_{match.group(1)}"

        raise ValueError("Could not extract product ID")

    def extract_title(self) -> str:
        """Extract product title."""
        title = self.parser.css_first(".f-productHeader-Title")
        if title:
            return title.text(strip=True)
        raise ValueError("Could not extract title")

    def extract_price(self) -> float:
        """Extract price, preferring direct Fnac price over marketplace."""
        # Direct Fnac price
        fnac_price = self.parser.css_first(".f-priceBox-price.f-priceBox-price--priceMember")
        if fnac_price:
            return self._parse_price(fnac_price.text())

        # Standard price
        price = self.parser.css_first(".f-priceBox-price")
        if price:
            return self._parse_price(price.text())

        raise ValueError("Could not extract price")

    def _parse_price(self, text: str) -> float:
        """Parse French price format."""
        clean = re.sub(r"[^\d,.]", "", text).replace(",", ".")
        return float(clean)

    def extract_attributes(self) -> dict:
        """Extract product characteristics."""
        attrs = {}

        # Tech specs section
        specs = self.parser.css(".f-productCharacteristics-item")
        for spec in specs:
            label = spec.css_first(".f-productCharacteristics-label")
            value = spec.css_first(".f-productCharacteristics-value")
            if label and value:
                key = label.text(strip=True).lower().replace(" ", "_")
                attrs[key] = value.text(strip=True)

        return attrs
```

## Cdiscount Extractor

```python
# apps/workers/src/normalizer/extractors/cdiscount.py
import re
from ..base import BaseExtractor

class CdiscountExtractor(BaseExtractor):
    retailer_id = "cdiscount"

    def extract_external_id(self) -> str:
        """Extract Cdiscount SKU."""
        sku = self.parser.css_first('[data-productid]')
        if sku:
            return sku.attributes.get("data-productid", "")

        # URL pattern fallback
        url = self.parser.css_first('link[rel="canonical"]')
        if url:
            match = re.search(r"f-(\d+)-", url.attributes.get("href", ""))
            if match:
                return f"cds_{match.group(1)}"

        raise ValueError("Could not extract SKU")

    def extract_title(self) -> str:
        """Extract product title."""
        title = self.parser.css_first("h1.fpDesMA")
        if title:
            return title.text(strip=True)
        raise ValueError("Could not extract title")

    def extract_price(self) -> float:
        """Extract price, handling flash sales."""
        # Flash sale price
        flash = self.parser.css_first(".fpPrice .fpPricePromo")
        if flash:
            return self._parse_price(flash.text())

        # Regular price
        price = self.parser.css_first(".fpPrice .fpPMain")
        if price:
            return self._parse_price(price.text())

        raise ValueError("Could not extract price")

    def _parse_price(self, text: str) -> float:
        clean = re.sub(r"[^\d,.]", "", text).replace(",", ".")
        return float(clean)

    def extract_attributes(self) -> dict:
        return {}  # Cdiscount has limited structured data
```

## Testing with Real HTML

```python
# apps/workers/tests/normalizer/test_extractors.py
import pytest
from pathlib import Path
from src.normalizer.extractors import get_extractor
from src.normalizer.models import ScrapeInput
from datetime import datetime

FIXTURES_DIR = Path(__file__).parent / "fixtures"

@pytest.fixture
def amazon_html():
    return (FIXTURES_DIR / "amazon_iphone.html").read_text()

def test_amazon_extraction(amazon_html):
    input = ScrapeInput(
        job_id="test123",
        url="https://amazon.fr/dp/B0ABCD1234",
        html=amazon_html,
        retailer_id="amazon_fr",
        scraped_at=datetime.now(),
    )

    extractor = get_extractor("amazon_fr")
    product = extractor.extract(input)

    assert product.external_id == "B0ABCD1234"
    assert "iPhone" in product.title
    assert product.price > 0
    assert product.currency == "EUR"
```

## Deliverables

- [ ] 6 extractors implemented
- [ ] Test fixtures for each retailer
- [ ] >90% extraction success rate
- [ ] Edge cases handled (missing data, format variations)

---

**Previous Phase**: [01-core.md](./01-core.md)
**Next Phase**: [03-validation.md](./03-validation.md)
**Back to**: [Normalizer README](./README.md)
