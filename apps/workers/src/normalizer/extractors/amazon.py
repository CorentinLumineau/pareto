"""Amazon.fr product extractor."""

import re
from bs4 import BeautifulSoup

from .base import BaseExtractor, ExtractedProduct


class AmazonExtractor(BaseExtractor):
    """Extractor for Amazon.fr product pages."""

    retailer_name = "Amazon"
    retailer_slug = "amazon"

    def extract(self) -> ExtractedProduct | None:
        """Extract product data from Amazon product page."""
        soup = BeautifulSoup(self.html, "lxml")

        # Product name
        name_elem = soup.select_one("#productTitle")
        if not name_elem:
            return None
        name = self.clean_text(name_elem.get_text())

        # Price
        price = 0.0
        price_elem = soup.select_one(".a-price .a-offscreen")
        if price_elem:
            price = self.clean_price(price_elem.get_text())

        # Check stock
        in_stock = True
        availability = soup.select_one("#availability")
        if availability:
            avail_text = availability.get_text().lower()
            in_stock = "en stock" in avail_text or "disponible" in avail_text

        # Image
        image_url = None
        img_elem = soup.select_one("#landingImage")
        if img_elem and img_elem.has_attr("src"):
            image_url = img_elem["src"]

        # GTIN/EAN
        gtin = None
        details = soup.select("#detailBullets_feature_div li")
        for detail in details:
            text = detail.get_text()
            if "EAN" in text or "GTIN" in text:
                match = re.search(r"\d{13}", text)
                if match:
                    gtin = match.group()
                    break

        # Brand
        brand = None
        brand_elem = soup.select_one("#bylineInfo")
        if brand_elem:
            brand_text = brand_elem.get_text()
            brand_match = re.search(r"Marque\s*:\s*(.+)", brand_text)
            if brand_match:
                brand = self.clean_text(brand_match.group(1))
            else:
                brand = self.clean_text(brand_text.replace("Visiter la boutique", ""))

        # Extract attributes from tech specs
        attributes: dict = {}
        tech_table = soup.select("#productDetails_techSpec_section_1 tr")
        for row in tech_table:
            header = row.select_one("th")
            value = row.select_one("td")
            if header and value:
                key = self.clean_text(header.get_text())
                val = self.clean_text(value.get_text())
                attributes[key] = val

        return ExtractedProduct(
            name=name,
            price=price,
            in_stock=in_stock,
            url=self.url,
            image_url=image_url,
            gtin=gtin,
            brand=brand,
            attributes=attributes,
        )

    def extract_list(self) -> list[ExtractedProduct]:
        """Extract products from Amazon search results page."""
        soup = BeautifulSoup(self.html, "lxml")
        products: list[ExtractedProduct] = []

        # Find search result items
        items = soup.select("[data-component-type='s-search-result']")

        for item in items:
            try:
                # Skip sponsored items
                if item.select_one(".s-label-popover-default"):
                    continue

                # Product name
                name_elem = item.select_one("h2 a span")
                if not name_elem:
                    continue
                name = self.clean_text(name_elem.get_text())

                # Product URL
                link = item.select_one("h2 a")
                if not link or not link.has_attr("href"):
                    continue
                url = "https://www.amazon.fr" + link["href"]

                # Price
                price = 0.0
                price_elem = item.select_one(".a-price .a-offscreen")
                if price_elem:
                    price = self.clean_price(price_elem.get_text())

                # Image
                image_url = None
                img_elem = item.select_one(".s-image")
                if img_elem and img_elem.has_attr("src"):
                    image_url = img_elem["src"]

                products.append(
                    ExtractedProduct(
                        name=name,
                        price=price,
                        url=url,
                        image_url=image_url,
                    )
                )
            except Exception:
                continue

        return products
