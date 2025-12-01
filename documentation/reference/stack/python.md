# Python 3.14 - Workers

> **Celery workers for scraping, parsing, and Pareto calculation**

## Version Info

| Attribute | Value |
|-----------|-------|
| **Version** | 3.14.0 |
| **Release** | October 2025 |
| **EOL** | October 2030 |
| **Key Features** | Template strings, deferred annotations, Zstandard |

## Project Structure

```
apps/workers/
├── src/
│   ├── __init__.py
│   ├── celery_app.py          # Celery configuration
│   ├── config.py              # Settings
│   │
│   ├── fetcher/               # Anti-bot HTTP client
│   │   ├── __init__.py
│   │   └── fetcher.py         # curl_cffi wrapper
│   │
│   ├── normalizer/            # HTML parsing
│   │   ├── __init__.py
│   │   ├── base_extractor.py  # Abstract base
│   │   ├── schemas.py         # Pydantic models
│   │   └── extractors/        # Per-retailer
│   │       ├── amazon.py
│   │       ├── fnac.py
│   │       ├── cdiscount.py
│   │       ├── darty.py
│   │       ├── boulanger.py
│   │       └── ldlc.py
│   │
│   ├── pareto/                # Pareto optimization
│   │   ├── __init__.py
│   │   ├── calculator.py      # paretoset wrapper
│   │   └── scoring.py         # Z-score normalization
│   │
│   └── tasks/                 # Celery tasks
│       ├── __init__.py
│       ├── scrape_tasks.py
│       ├── normalize_tasks.py
│       └── pareto_tasks.py
│
├── tests/
├── pyproject.toml
├── requirements.txt
└── Dockerfile
```

## Python 3.14 Key Features

### Template Strings (PEP 750)

```python
# New in Python 3.14: Template string literals
from string import Template

# Old way
name = "iPhone 15"
price = 999.99
message = f"Product: {name} at {price}EUR"

# New way with t-strings (template strings)
template = t"Product: {name} at {price}EUR"
# Can be processed before rendering
processed = template.render(price=f"{price:.2f}")
```

### Deferred Evaluation of Annotations (PEP 649)

```python
# Annotations now evaluated lazily - no more __future__ import needed
class Product:
    name: str
    offers: list["Offer"]  # Forward reference works naturally

class Offer:
    product: "Product"
    price: float
```

### Improved Free-Threaded Mode

```python
# Better GIL-free performance for CPU-bound tasks
# ~5-10% overhead vs regular Python (down from 40%+)
import sys
print(f"Free-threaded: {sys._is_gil_enabled()}")
```

## Celery Configuration

```python
# src/celery_app.py
from celery import Celery
from kombu import Queue

from .config import settings

app = Celery(
    "pareto_workers",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
)

app.conf.update(
    # Task settings
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Europe/Paris",
    enable_utc=True,

    # Concurrency
    worker_concurrency=4,
    worker_prefetch_multiplier=1,

    # Task routing
    task_queues=(
        Queue("scrape", routing_key="scrape.#"),
        Queue("normalize", routing_key="normalize.#"),
        Queue("pareto", routing_key="pareto.#"),
    ),
    task_routes={
        "tasks.scrape_tasks.*": {"queue": "scrape"},
        "tasks.normalize_tasks.*": {"queue": "normalize"},
        "tasks.pareto_tasks.*": {"queue": "pareto"},
    },

    # Rate limiting
    task_annotations={
        "tasks.scrape_tasks.scrape_url": {"rate_limit": "10/m"},
    },

    # Retries
    task_acks_late=True,
    task_reject_on_worker_lost=True,
)

# Auto-discover tasks
app.autodiscover_tasks(["src.tasks"])
```

## Anti-Bot Fetcher (curl_cffi)

```python
# src/fetcher/fetcher.py
from curl_cffi.requests import Session, BrowserType
from typing import Optional
import random
import time

class AntiBotFetcher:
    """HTTP client with TLS fingerprint impersonation."""

    IMPERSONATES = [
        BrowserType.chrome136,
        BrowserType.chrome131,
        BrowserType.safari18_0,
    ]

    def __init__(
        self,
        proxy: Optional[str] = None,
        timeout: int = 30,
    ):
        self.proxy = proxy
        self.timeout = timeout
        self._session: Optional[Session] = None

    def _get_session(self) -> Session:
        """Create session with random browser fingerprint."""
        if self._session is None:
            self._session = Session(
                impersonate=random.choice(self.IMPERSONATES),
                timeout=self.timeout,
            )
            if self.proxy:
                self._session.proxies = {
                    "http": self.proxy,
                    "https": self.proxy,
                }
        return self._session

    def fetch(
        self,
        url: str,
        headers: Optional[dict] = None,
        retry: int = 3,
    ) -> str:
        """Fetch URL with anti-bot bypass."""
        session = self._get_session()

        default_headers = {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7",
            "Accept-Encoding": "gzip, deflate, br",
            "DNT": "1",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
        }

        if headers:
            default_headers.update(headers)

        last_error = None
        for attempt in range(retry):
            try:
                response = session.get(url, headers=default_headers)
                response.raise_for_status()
                return response.text
            except Exception as e:
                last_error = e
                if attempt < retry - 1:
                    # Exponential backoff with jitter
                    sleep_time = (2 ** attempt) + random.uniform(0, 1)
                    time.sleep(sleep_time)
                    # Rotate fingerprint
                    self._session = None

        raise last_error


# Singleton with proxy rotation
class FetcherPool:
    """Pool of fetchers with proxy rotation."""

    def __init__(self, proxies: list[str]):
        self.fetchers = [AntiBotFetcher(proxy=p) for p in proxies]
        self._index = 0

    def get(self) -> AntiBotFetcher:
        fetcher = self.fetchers[self._index]
        self._index = (self._index + 1) % len(self.fetchers)
        return fetcher
```

## Pydantic Schemas

```python
# src/normalizer/schemas.py
from pydantic import BaseModel, Field, field_validator
from typing import Optional
from decimal import Decimal
from datetime import datetime

class NormalizedProduct(BaseModel):
    """Normalized product data from scraping."""

    # Identifiers
    retailer: str
    retailer_sku: str
    url: str

    # Product info
    title: str = Field(min_length=3, max_length=500)
    brand: Optional[str] = None
    ean: Optional[str] = Field(None, pattern=r"^\d{13}$")

    # Pricing
    price: Decimal = Field(gt=0, le=100000)
    original_price: Optional[Decimal] = None
    currency: str = "EUR"

    # Availability
    in_stock: bool = True
    shipping_cost: Optional[Decimal] = None

    # Attributes (category-specific)
    attributes: dict = Field(default_factory=dict)

    # Metadata
    scraped_at: datetime = Field(default_factory=datetime.utcnow)

    @field_validator("price", "original_price", "shipping_cost", mode="before")
    @classmethod
    def parse_price(cls, v):
        if v is None:
            return None
        if isinstance(v, str):
            # Clean price string: "1 299,99 €" -> 1299.99
            v = v.replace(" ", "").replace("€", "").replace(",", ".")
            v = "".join(c for c in v if c.isdigit() or c == ".")
        return Decimal(str(v))

    @field_validator("ean")
    @classmethod
    def validate_ean(cls, v):
        if v is None:
            return None
        # EAN-13 checksum validation
        if len(v) != 13:
            return None
        digits = [int(d) for d in v]
        checksum = sum(d * (1 if i % 2 == 0 else 3) for i, d in enumerate(digits[:-1]))
        expected = (10 - (checksum % 10)) % 10
        if digits[-1] != expected:
            return None
        return v

class SmartphoneAttributes(BaseModel):
    """Smartphone-specific attributes."""

    storage_gb: Optional[int] = None
    ram_gb: Optional[int] = None
    screen_size_inches: Optional[float] = None
    battery_mah: Optional[int] = None
    camera_mp: Optional[int] = None
    color: Optional[str] = None
    model_year: Optional[int] = None
```

## Base Extractor

```python
# src/normalizer/base_extractor.py
from abc import ABC, abstractmethod
from bs4 import BeautifulSoup
from typing import Optional
import re

from .schemas import NormalizedProduct

class BaseExtractor(ABC):
    """Abstract base class for retailer-specific extractors."""

    RETAILER: str = ""

    def __init__(self, html: str, url: str):
        self.soup = BeautifulSoup(html, "lxml")
        self.url = url

    def extract(self) -> Optional[NormalizedProduct]:
        """Main extraction method."""
        try:
            return NormalizedProduct(
                retailer=self.RETAILER,
                retailer_sku=self.extract_sku(),
                url=self.url,
                title=self.extract_title(),
                brand=self.extract_brand(),
                ean=self.extract_ean(),
                price=self.extract_price(),
                original_price=self.extract_original_price(),
                in_stock=self.extract_availability(),
                shipping_cost=self.extract_shipping(),
                attributes=self.extract_attributes(),
            )
        except Exception as e:
            # Log but don't crash
            return None

    @abstractmethod
    def extract_title(self) -> str:
        pass

    @abstractmethod
    def extract_price(self) -> str:
        pass

    @abstractmethod
    def extract_sku(self) -> str:
        pass

    def extract_brand(self) -> Optional[str]:
        return None

    def extract_ean(self) -> Optional[str]:
        return None

    def extract_original_price(self) -> Optional[str]:
        return None

    def extract_availability(self) -> bool:
        return True

    def extract_shipping(self) -> Optional[str]:
        return None

    def extract_attributes(self) -> dict:
        return {}

    # Helper methods
    def select_text(self, selector: str) -> Optional[str]:
        """Extract text from CSS selector."""
        el = self.soup.select_one(selector)
        return el.get_text(strip=True) if el else None

    def select_attr(self, selector: str, attr: str) -> Optional[str]:
        """Extract attribute from CSS selector."""
        el = self.soup.select_one(selector)
        return el.get(attr) if el else None

    def extract_json_ld(self) -> Optional[dict]:
        """Extract JSON-LD structured data."""
        script = self.soup.select_one('script[type="application/ld+json"]')
        if script:
            import json
            try:
                return json.loads(script.string)
            except json.JSONDecodeError:
                pass
        return None
```

## Amazon Extractor Example

```python
# src/normalizer/extractors/amazon.py
from typing import Optional
import re
import json

from ..base_extractor import BaseExtractor

class AmazonExtractor(BaseExtractor):
    RETAILER = "amazon"

    def extract_title(self) -> str:
        return self.select_text("#productTitle") or ""

    def extract_price(self) -> str:
        # Try multiple selectors
        selectors = [
            ".a-price .a-offscreen",
            "#priceblock_ourprice",
            "#priceblock_dealprice",
            ".a-price-whole",
        ]
        for selector in selectors:
            if price := self.select_text(selector):
                return price
        return "0"

    def extract_sku(self) -> str:
        # ASIN from URL or page
        if match := re.search(r"/dp/([A-Z0-9]{10})", self.url):
            return match.group(1)
        if asin := self.select_attr('input[name="ASIN"]', "value"):
            return asin
        return ""

    def extract_brand(self) -> Optional[str]:
        return self.select_text("#bylineInfo") or self.select_text(".po-brand .a-span9")

    def extract_ean(self) -> Optional[str]:
        # Try to find in tech specs table
        for row in self.soup.select("#productDetails_techSpec_section_1 tr"):
            header = row.select_one("th")
            value = row.select_one("td")
            if header and value:
                if "EAN" in header.get_text() or "GTIN" in header.get_text():
                    ean = re.sub(r"\D", "", value.get_text())
                    if len(ean) == 13:
                        return ean
        return None

    def extract_original_price(self) -> Optional[str]:
        return self.select_text(".a-text-price .a-offscreen")

    def extract_availability(self) -> bool:
        availability = self.select_text("#availability")
        if availability:
            return "en stock" in availability.lower() or "in stock" in availability.lower()
        return True

    def extract_attributes(self) -> dict:
        attrs = {}

        # Extract from tech specs
        for row in self.soup.select("#productDetails_techSpec_section_1 tr"):
            header = row.select_one("th")
            value = row.select_one("td")
            if header and value:
                key = header.get_text(strip=True).lower()
                val = value.get_text(strip=True)

                if "stockage" in key or "storage" in key:
                    if match := re.search(r"(\d+)\s*(?:Go|GB)", val, re.I):
                        attrs["storage_gb"] = int(match.group(1))
                elif "ram" in key:
                    if match := re.search(r"(\d+)\s*(?:Go|GB)", val, re.I):
                        attrs["ram_gb"] = int(match.group(1))
                elif "écran" in key or "screen" in key:
                    if match := re.search(r"(\d+[.,]?\d*)\s*(?:pouces|inches|\")", val, re.I):
                        attrs["screen_size_inches"] = float(match.group(1).replace(",", "."))

        return attrs
```

## Pareto Calculator

```python
# src/pareto/calculator.py
from paretoset import paretoset
import numpy as np
from typing import TypedDict
from dataclasses import dataclass

class ObjectiveConfig(TypedDict):
    name: str
    sense: str  # "min" or "max"
    weight: float

@dataclass
class ParetoResult:
    frontier_ids: list[str]
    dominated_ids: list[str]
    scores: dict[str, float]

class ParetoCalculator:
    """Calculate Pareto frontier and scores."""

    def __init__(self, objectives: list[ObjectiveConfig]):
        self.objectives = objectives
        self.sense = [o["sense"] for o in objectives]

    def calculate(self, products: list[dict]) -> ParetoResult:
        """
        Calculate Pareto frontier for products.

        Args:
            products: List of dicts with 'id' and objective values

        Returns:
            ParetoResult with frontier/dominated IDs and scores
        """
        if not products:
            return ParetoResult([], [], {})

        # Build data matrix
        ids = [p["id"] for p in products]
        data = np.array([
            [p.get(obj["name"], 0) for obj in self.objectives]
            for p in products
        ])

        # Calculate Pareto mask
        mask = paretoset(data, sense=self.sense)

        # Split into frontier and dominated
        frontier_ids = [ids[i] for i, is_pareto in enumerate(mask) if is_pareto]
        dominated_ids = [ids[i] for i, is_pareto in enumerate(mask) if not is_pareto]

        # Calculate scores using z-score normalization
        scores = self._calculate_scores(products, data)

        return ParetoResult(
            frontier_ids=frontier_ids,
            dominated_ids=dominated_ids,
            scores=scores,
        )

    def _calculate_scores(self, products: list[dict], data: np.ndarray) -> dict[str, float]:
        """Calculate weighted utility scores using z-score normalization."""
        scores = {}

        # Z-score normalize each column
        means = np.mean(data, axis=0)
        stds = np.std(data, axis=0)
        stds[stds == 0] = 1  # Avoid division by zero

        z_scores = (data - means) / stds

        # Flip sign for minimization objectives
        for i, obj in enumerate(self.objectives):
            if obj["sense"] == "min":
                z_scores[:, i] = -z_scores[:, i]

        # Calculate weighted sum
        weights = np.array([obj["weight"] for obj in self.objectives])
        weighted_scores = np.dot(z_scores, weights) / weights.sum()

        # Normalize to 0-100 scale
        min_score = weighted_scores.min()
        max_score = weighted_scores.max()
        if max_score > min_score:
            normalized = (weighted_scores - min_score) / (max_score - min_score) * 100
        else:
            normalized = np.full_like(weighted_scores, 50.0)

        for i, product in enumerate(products):
            scores[product["id"]] = round(float(normalized[i]), 1)

        return scores
```

## Celery Tasks

```python
# src/tasks/scrape_tasks.py
from celery import shared_task
from ..fetcher.fetcher import AntiBotFetcher
from ..config import settings
import redis

@shared_task(
    bind=True,
    max_retries=3,
    default_retry_delay=60,
)
def scrape_url(self, url: str, retailer: str) -> dict:
    """Scrape a URL and store raw HTML in Redis."""
    try:
        fetcher = AntiBotFetcher(proxy=settings.PROXY_URL)
        html = fetcher.fetch(url)

        # Store in Redis with 24h TTL
        r = redis.from_url(settings.REDIS_URL)
        key = f"html:{retailer}:{url}"
        r.setex(key, 86400, html)

        # Trigger normalization
        from .normalize_tasks import normalize_html
        normalize_html.delay(key, url, retailer)

        return {"status": "success", "url": url}

    except Exception as e:
        raise self.retry(exc=e)


# src/tasks/normalize_tasks.py
from celery import shared_task
from ..normalizer.extractors import get_extractor
from ..config import settings
import redis
import httpx

@shared_task
def normalize_html(redis_key: str, url: str, retailer: str) -> dict:
    """Parse HTML and send to catalog API."""
    r = redis.from_url(settings.REDIS_URL)
    html = r.get(redis_key)

    if not html:
        return {"status": "error", "message": "HTML not found"}

    # Get retailer-specific extractor
    extractor_class = get_extractor(retailer)
    extractor = extractor_class(html.decode(), url)

    product = extractor.extract()
    if not product:
        return {"status": "error", "message": "Extraction failed"}

    # Send to catalog API
    response = httpx.post(
        f"{settings.CATALOG_API_URL}/internal/products",
        json=product.model_dump(mode="json"),
        headers={"Authorization": f"Bearer {settings.INTERNAL_TOKEN}"},
    )
    response.raise_for_status()

    return {"status": "success", "product_id": response.json().get("id")}


# src/tasks/pareto_tasks.py
from celery import shared_task
from ..pareto.calculator import ParetoCalculator, ObjectiveConfig

@shared_task
def calculate_pareto(
    products: list[dict],
    objectives: list[dict],
) -> dict:
    """Calculate Pareto frontier for products."""
    obj_configs = [ObjectiveConfig(**o) for o in objectives]
    calculator = ParetoCalculator(obj_configs)
    result = calculator.calculate(products)

    return {
        "frontier_ids": result.frontier_ids,
        "dominated_ids": result.dominated_ids,
        "scores": result.scores,
    }
```

## pyproject.toml

```toml
[project]
name = "pareto-workers"
version = "1.0.0"
description = "Celery workers for Pareto Comparator"
requires-python = ">=3.14"
dependencies = [
    "celery[redis]>=5.5.0",
    "redis>=5.2.0",
    "curl-cffi>=0.8.0",
    "beautifulsoup4>=4.12.0",
    "lxml>=5.3.0",
    "paretoset>=1.2.0",
    "numpy>=2.2.0",
    "pydantic>=2.11.0",
    "httpx>=0.28.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.0",
    "pytest-cov>=6.0.0",
    "pytest-asyncio>=0.24.0",
    "ruff>=0.8.0",
    "mypy>=1.13.0",
]

[tool.ruff]
target-version = "py314"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

[tool.mypy]
python_version = "3.14"
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
```

## Dockerfile

```dockerfile
# apps/workers/Dockerfile
FROM python:3.14-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY src ./src

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Run Celery worker
CMD ["celery", "-A", "src.celery_app", "worker", "--loglevel=info"]
```

## Commands

```bash
# Development
celery -A src.celery_app worker --loglevel=debug

# Production (with concurrency)
celery -A src.celery_app worker --loglevel=info -c 4

# Beat scheduler (for periodic tasks)
celery -A src.celery_app beat --loglevel=info

# Flower monitoring
celery -A src.celery_app flower --port=5555

# Test
pytest tests/ -v --cov=src

# Lint
ruff check src/
ruff format src/

# Type check
mypy src/
```

---

**See Also**:
- [Go API](./go.md)
- [Redis](./redis.md)
