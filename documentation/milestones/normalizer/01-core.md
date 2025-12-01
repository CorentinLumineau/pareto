# Phase 01: Core Framework

> **Celery setup and base extractor architecture**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      01 - Core Framework                               ║
║  Initiative: Normalizer                                        ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Setup Celery worker infrastructure and create the base extractor framework.

## Tasks

- [ ] Setup Python project structure
- [ ] Configure Celery with Redis broker
- [ ] Create base extractor interface
- [ ] Implement result models with Pydantic
- [ ] Add logging and monitoring

## Project Structure

```
apps/workers/
├── src/
│   ├── __init__.py
│   ├── celery_app.py          # Celery configuration
│   ├── config.py              # Settings from env
│   ├── normalizer/
│   │   ├── __init__.py
│   │   ├── tasks.py           # Celery tasks
│   │   ├── base.py            # Base extractor
│   │   ├── models.py          # Pydantic models
│   │   ├── extractors/        # Retailer-specific
│   │   │   ├── __init__.py
│   │   │   ├── amazon.py
│   │   │   ├── fnac.py
│   │   │   └── ...
│   │   └── utils/
│   │       ├── __init__.py
│   │       └── parsing.py
│   └── pareto/                # Phase M4
│       └── ...
├── tests/
│   └── normalizer/
├── pyproject.toml
├── Dockerfile
└── requirements.txt
```

## Celery Configuration

```python
# apps/workers/src/celery_app.py
from celery import Celery
from .config import settings

app = Celery(
    "pareto_workers",
    broker=settings.redis_url,
    backend=settings.redis_url,
)

app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Europe/Paris",
    enable_utc=True,
    task_routes={
        "normalizer.*": {"queue": "normalizer"},
        "pareto.*": {"queue": "pareto"},
    },
    task_default_retry_delay=60,
    task_max_retries=3,
)
```

## Base Extractor

```python
# apps/workers/src/normalizer/base.py
from abc import ABC, abstractmethod
from selectolax.parser import HTMLParser
from .models import NormalizedProduct, ScrapeInput

class BaseExtractor(ABC):
    """Base class for retailer-specific extractors."""

    retailer_id: str

    def __init__(self):
        self.parser = None

    def extract(self, input: ScrapeInput) -> NormalizedProduct:
        """Main extraction method."""
        self.parser = HTMLParser(input.html)

        return NormalizedProduct(
            external_id=self.extract_external_id(),
            retailer_id=self.retailer_id,
            url=input.url,
            title=self.extract_title(),
            price=self.extract_price(),
            currency="EUR",
            brand=self.extract_brand(),
            model=self.extract_model(),
            attributes=self.extract_attributes(),
            scraped_at=input.scraped_at,
        )

    @abstractmethod
    def extract_external_id(self) -> str:
        """Extract retailer-specific product ID."""
        pass

    @abstractmethod
    def extract_title(self) -> str:
        """Extract product title."""
        pass

    @abstractmethod
    def extract_price(self) -> float:
        """Extract product price."""
        pass

    def extract_brand(self) -> str | None:
        """Extract brand (optional)."""
        return None

    def extract_model(self) -> str | None:
        """Extract model (optional)."""
        return None

    @abstractmethod
    def extract_attributes(self) -> dict:
        """Extract additional attributes."""
        pass
```

## Pydantic Models

```python
# apps/workers/src/normalizer/models.py
from datetime import datetime
from pydantic import BaseModel, Field, field_validator
import re

class ScrapeInput(BaseModel):
    """Input from scraper job."""
    job_id: str
    url: str
    html: str
    retailer_id: str
    scraped_at: datetime

class NormalizedProduct(BaseModel):
    """Normalized product output."""
    external_id: str
    retailer_id: str
    url: str
    title: str = Field(min_length=5, max_length=500)
    price: float = Field(gt=0, lt=100000)
    currency: str = "EUR"
    brand: str | None = None
    model: str | None = None
    attributes: dict = Field(default_factory=dict)
    scraped_at: datetime

    @field_validator("title")
    @classmethod
    def clean_title(cls, v: str) -> str:
        """Remove extra whitespace from title."""
        return re.sub(r"\s+", " ", v.strip())

    @field_validator("price", mode="before")
    @classmethod
    def parse_price(cls, v) -> float:
        """Parse price from various formats."""
        if isinstance(v, str):
            # Handle French format: "1 229,99 €"
            v = v.replace(" ", "").replace("€", "").replace(",", ".")
        return float(v)
```

## Celery Task

```python
# apps/workers/src/normalizer/tasks.py
from celery import shared_task
from .models import ScrapeInput, NormalizedProduct
from .extractors import get_extractor
import httpx

@shared_task(bind=True, max_retries=3)
def normalize_product(self, scrape_result: dict) -> dict:
    """Normalize a scraped product."""
    try:
        input = ScrapeInput(**scrape_result)
        extractor = get_extractor(input.retailer_id)
        product = extractor.extract(input)

        # Send to catalog API
        send_to_catalog(product)

        return product.model_dump()
    except Exception as e:
        self.retry(exc=e, countdown=60 * (self.request.retries + 1))

def send_to_catalog(product: NormalizedProduct):
    """Send normalized product to Go catalog API."""
    with httpx.Client() as client:
        response = client.post(
            "http://api:8080/internal/products",
            json=product.model_dump(),
            timeout=10,
        )
        response.raise_for_status()
```

## Dependencies

```toml
# apps/workers/pyproject.toml
[project]
name = "pareto-workers"
version = "0.1.0"
requires-python = ">=3.11"

dependencies = [
    "celery[redis]>=5.3.0",
    "selectolax>=0.3.17",
    "pydantic>=2.5.0",
    "httpx>=0.25.0",
    "python-dotenv>=1.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.21.0",
]
```

## Deliverables

- [ ] Celery app configured
- [ ] Base extractor class
- [ ] Pydantic models validated
- [ ] Unit tests >80% coverage
- [ ] Docker build working

---

**Next Phase**: [02-extractors.md](./02-extractors.md)
**Back to**: [Normalizer README](./README.md)
