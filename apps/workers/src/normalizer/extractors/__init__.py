"""Retailer-specific extractors."""

from .base import BaseExtractor
from .amazon import AmazonExtractor

__all__ = ["BaseExtractor", "AmazonExtractor"]
