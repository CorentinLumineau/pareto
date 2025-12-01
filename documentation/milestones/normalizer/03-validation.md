# Phase 03: Validation Pipeline

> **Quality checks and schema validation**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      03 - Validation Pipeline                          ║
║  Initiative: Normalizer                                        ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Implement comprehensive validation to ensure data quality before storage in the catalog.

## Tasks

- [ ] Define validation rules per field
- [ ] Implement price sanity checks
- [ ] Add title quality validation
- [ ] Create attribute validators
- [ ] Setup validation metrics/alerts

## Validation Rules

```python
# apps/workers/src/normalizer/validators.py
from pydantic import BaseModel, field_validator, model_validator
from typing import Self
import re

class ValidatedProduct(BaseModel):
    """Product with strict validation rules."""

    external_id: str
    retailer_id: str
    url: str
    title: str
    price: float
    currency: str = "EUR"
    brand: str | None = None
    attributes: dict = {}

    @field_validator("external_id")
    @classmethod
    def validate_external_id(cls, v: str) -> str:
        if len(v) < 3:
            raise ValueError("External ID too short")
        if not re.match(r"^[A-Za-z0-9_-]+$", v):
            raise ValueError("Invalid external ID format")
        return v

    @field_validator("title")
    @classmethod
    def validate_title(cls, v: str) -> str:
        # Min/max length
        if len(v) < 10:
            raise ValueError("Title too short")
        if len(v) > 500:
            raise ValueError("Title too long")

        # Check for garbage characters
        if re.search(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", v):
            raise ValueError("Title contains invalid characters")

        # Check it's not all caps or all lowercase
        if v.isupper() or v.islower():
            v = v.title()

        return v.strip()

    @field_validator("price")
    @classmethod
    def validate_price(cls, v: float) -> float:
        # Smartphones typically 100-3000€
        if v < 50:
            raise ValueError(f"Price suspiciously low: {v}€")
        if v > 5000:
            raise ValueError(f"Price suspiciously high: {v}€")
        return round(v, 2)

    @field_validator("url")
    @classmethod
    def validate_url(cls, v: str) -> str:
        if not v.startswith(("http://", "https://")):
            raise ValueError("Invalid URL scheme")
        return v

    @model_validator(mode="after")
    def check_consistency(self) -> Self:
        """Cross-field validation."""
        # Title should mention brand if known
        if self.brand:
            brand_lower = self.brand.lower()
            title_lower = self.title.lower()
            # Warning only, don't fail
            if brand_lower not in title_lower:
                # Log warning but don't raise
                pass

        return self
```

## Price Sanity Checks

```python
# apps/workers/src/normalizer/validators/price.py
from dataclasses import dataclass
from typing import Optional

@dataclass
class PriceValidation:
    """Price validation result."""
    valid: bool
    price: float
    original: float
    warnings: list[str]

class PriceValidator:
    """Validates and normalizes prices."""

    # Expected ranges by category
    SMARTPHONE_RANGE = (50, 3000)

    # Known price anomalies
    COMMON_ERRORS = {
        0.01: "Placeholder price",
        1.00: "Possible placeholder",
        9999.99: "Out of stock placeholder",
    }

    def validate(self, price: float, title: str = "") -> PriceValidation:
        """Validate a price."""
        warnings = []

        # Check for known error values
        if price in self.COMMON_ERRORS:
            return PriceValidation(
                valid=False,
                price=price,
                original=price,
                warnings=[self.COMMON_ERRORS[price]]
            )

        # Check range
        min_price, max_price = self.SMARTPHONE_RANGE
        if price < min_price:
            warnings.append(f"Price below minimum ({min_price}€)")
        if price > max_price:
            warnings.append(f"Price above maximum ({max_price}€)")

        # Check for decimal issues (e.g., 12299 instead of 1229.99)
        if price > 10000 and price % 100 == 0:
            suggested = price / 100
            if min_price <= suggested <= max_price:
                warnings.append(f"Possible decimal error, suggested: {suggested}€")

        return PriceValidation(
            valid=len(warnings) == 0 or all("above" not in w and "below" not in w for w in warnings),
            price=round(price, 2),
            original=price,
            warnings=warnings
        )
```

## Title Quality Validator

```python
# apps/workers/src/normalizer/validators/title.py
import re
from dataclasses import dataclass

@dataclass
class TitleValidation:
    """Title validation result."""
    valid: bool
    title: str
    original: str
    warnings: list[str]

class TitleValidator:
    """Validates and cleans product titles."""

    # Patterns to remove
    GARBAGE_PATTERNS = [
        r"\s*\|\s*Amazon\.fr.*$",
        r"\s*-\s*Fnac\.com.*$",
        r"\s*\[.*offre.*\]",
        r"\s*\(.*livraison.*\)",
    ]

    # Required keywords for smartphones
    SMARTPHONE_KEYWORDS = ["smartphone", "iphone", "galaxy", "pixel", "xiaomi", "oppo"]

    def validate(self, title: str) -> TitleValidation:
        """Validate and clean a title."""
        warnings = []
        original = title

        # Remove garbage
        for pattern in self.GARBAGE_PATTERNS:
            title = re.sub(pattern, "", title, flags=re.IGNORECASE)

        # Normalize whitespace
        title = re.sub(r"\s+", " ", title).strip()

        # Check minimum quality
        if len(title) < 10:
            return TitleValidation(
                valid=False,
                title=title,
                original=original,
                warnings=["Title too short after cleaning"]
            )

        # Check for smartphone keywords
        title_lower = title.lower()
        has_keyword = any(kw in title_lower for kw in self.SMARTPHONE_KEYWORDS)
        if not has_keyword:
            warnings.append("No smartphone keyword found")

        return TitleValidation(
            valid=True,
            title=title,
            original=original,
            warnings=warnings
        )
```

## Validation Pipeline

```python
# apps/workers/src/normalizer/pipeline.py
from .validators import ValidatedProduct
from .validators.price import PriceValidator
from .validators.title import TitleValidator
from .models import NormalizedProduct
from dataclasses import dataclass

@dataclass
class ValidationResult:
    """Complete validation result."""
    valid: bool
    product: ValidatedProduct | None
    errors: list[str]
    warnings: list[str]

class ValidationPipeline:
    """Runs all validations on a product."""

    def __init__(self):
        self.price_validator = PriceValidator()
        self.title_validator = TitleValidator()

    def validate(self, product: NormalizedProduct) -> ValidationResult:
        """Run full validation pipeline."""
        errors = []
        warnings = []

        # Validate price
        price_result = self.price_validator.validate(product.price, product.title)
        if not price_result.valid:
            errors.extend(price_result.warnings)
        else:
            warnings.extend(price_result.warnings)

        # Validate title
        title_result = self.title_validator.validate(product.title)
        if not title_result.valid:
            errors.extend(title_result.warnings)
        else:
            warnings.extend(title_result.warnings)

        # Create validated product if no errors
        if errors:
            return ValidationResult(
                valid=False,
                product=None,
                errors=errors,
                warnings=warnings
            )

        try:
            validated = ValidatedProduct(
                external_id=product.external_id,
                retailer_id=product.retailer_id,
                url=product.url,
                title=title_result.title,
                price=price_result.price,
                currency=product.currency,
                brand=product.brand,
                attributes=product.attributes,
            )
            return ValidationResult(
                valid=True,
                product=validated,
                errors=[],
                warnings=warnings
            )
        except Exception as e:
            return ValidationResult(
                valid=False,
                product=None,
                errors=[str(e)],
                warnings=warnings
            )
```

## Deliverables

- [ ] Price validation with sanity checks
- [ ] Title cleaning and validation
- [ ] Cross-field consistency checks
- [ ] Validation metrics logging
- [ ] Unit tests for edge cases

---

**Previous Phase**: [02-extractors.md](./02-extractors.md)
**Next Phase**: [04-entity-resolution.md](./04-entity-resolution.md)
**Back to**: [Normalizer README](./README.md)
