"""Base extractor for all retailers."""

from abc import ABC, abstractmethod
from typing import Any

from pydantic import BaseModel


class ExtractedProduct(BaseModel):
    """Extracted product data."""

    name: str
    price: float
    shipping: float | None = None
    currency: str = "EUR"
    in_stock: bool = True
    url: str
    image_url: str | None = None
    gtin: str | None = None
    brand: str | None = None
    model: str | None = None
    attributes: dict[str, Any] = {}
    raw_html: str | None = None


class BaseExtractor(ABC):
    """Base class for retailer extractors."""

    retailer_name: str = "base"
    retailer_slug: str = "base"

    def __init__(self, html: str, url: str) -> None:
        """Initialize extractor with HTML content and URL."""
        self.html = html
        self.url = url

    @abstractmethod
    def extract(self) -> ExtractedProduct | None:
        """Extract product data from HTML. Must be implemented by subclass."""
        pass

    @abstractmethod
    def extract_list(self) -> list[ExtractedProduct]:
        """Extract multiple products from a listing page."""
        pass

    def clean_price(self, price_str: str) -> float:
        """Clean and parse price string to float."""
        if not price_str:
            return 0.0

        # Remove currency symbols and normalize
        cleaned = price_str.replace("€", "").replace("EUR", "")
        cleaned = cleaned.replace("\xa0", "").replace(" ", "")
        cleaned = cleaned.replace(",", ".")

        # Handle price ranges (take first price)
        if "-" in cleaned:
            cleaned = cleaned.split("-")[0]

        try:
            return float(cleaned.strip())
        except ValueError:
            return 0.0

    def clean_text(self, text: str | None) -> str:
        """Clean text by removing extra whitespace."""
        if not text:
            return ""
        return " ".join(text.split())
