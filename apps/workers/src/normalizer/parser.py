"""HTML parsing utilities using BeautifulSoup."""

from typing import Any

from bs4 import BeautifulSoup
from pydantic import BaseModel


class ParsedProduct(BaseModel):
    """Parsed product data from HTML."""

    name: str
    price: float
    currency: str = "EUR"
    in_stock: bool = True
    url: str
    image_url: str | None = None
    gtin: str | None = None
    attributes: dict[str, Any] = {}


class HTMLParser:
    """Base HTML parser using BeautifulSoup."""

    def __init__(self, html: str) -> None:
        """Initialize parser with HTML content."""
        self.soup = BeautifulSoup(html, "lxml")

    def select_one(self, selector: str) -> BeautifulSoup | None:
        """Select a single element by CSS selector."""
        return self.soup.select_one(selector)

    def select(self, selector: str) -> list[BeautifulSoup]:
        """Select multiple elements by CSS selector."""
        return self.soup.select(selector)

    def get_text(self, selector: str, default: str = "") -> str:
        """Get text content of an element."""
        element = self.select_one(selector)
        if element:
            return element.get_text(strip=True)
        return default

    def get_attr(self, selector: str, attr: str, default: str = "") -> str:
        """Get attribute value of an element."""
        element = self.select_one(selector)
        if element and element.has_attr(attr):
            return str(element[attr])
        return default

    def parse_price(self, price_str: str) -> float:
        """Parse price string to float."""
        # Remove currency symbols and normalize decimal separator
        cleaned = price_str.replace("€", "").replace("EUR", "")
        cleaned = cleaned.replace("\xa0", "").replace(" ", "")
        cleaned = cleaned.replace(",", ".")
        try:
            return float(cleaned)
        except ValueError:
            return 0.0

    def parse(self) -> ParsedProduct | None:
        """Parse HTML and return product data. Override in subclass."""
        raise NotImplementedError("Subclasses must implement parse()")
