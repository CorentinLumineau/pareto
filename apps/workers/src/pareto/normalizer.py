"""Score normalization utilities."""

from typing import Any

import numpy as np


def z_score_normalize(values: list[float]) -> list[float]:
    """Normalize values using z-score (mean=0, std=1).

    Args:
        values: List of values to normalize

    Returns:
        List of z-score normalized values
    """
    if not values:
        return []

    arr = np.array(values)
    mean = np.mean(arr)
    std = np.std(arr)

    if std == 0:
        return [0.0] * len(values)

    return ((arr - mean) / std).tolist()


def min_max_normalize(values: list[float], invert: bool = False) -> list[float]:
    """Normalize values to 0-1 range using min-max normalization.

    Args:
        values: List of values to normalize
        invert: If True, invert so lower values become higher (for minimization)

    Returns:
        List of normalized values in 0-1 range
    """
    if not values:
        return []

    arr = np.array(values)
    min_val = np.min(arr)
    max_val = np.max(arr)

    if max_val == min_val:
        return [0.5] * len(values)

    normalized = (arr - min_val) / (max_val - min_val)

    if invert:
        normalized = 1 - normalized

    return normalized.tolist()


def weighted_sum(scores: dict[str, float], weights: dict[str, float]) -> float:
    """Calculate weighted sum of scores.

    Args:
        scores: Dictionary of attribute -> normalized score
        weights: Dictionary of attribute -> weight

    Returns:
        Weighted sum score
    """
    total = 0.0
    weight_sum = 0.0

    for attr, score in scores.items():
        weight = weights.get(attr, 1.0)
        total += score * weight
        weight_sum += weight

    if weight_sum == 0:
        return 0.0

    return total / weight_sum


def normalize_product_attributes(
    products: list[dict[str, Any]],
    attributes: list[str],
    directions: dict[str, str] | None = None,
) -> list[dict[str, float]]:
    """Normalize multiple attributes across products.

    Args:
        products: List of product dictionaries with attributes
        attributes: List of attribute names to normalize
        directions: Dict of attribute -> 'minimize' or 'maximize'

    Returns:
        List of dictionaries with normalized scores for each attribute
    """
    if not products or not attributes:
        return []

    directions = directions or {}
    normalized_products: list[dict[str, float]] = []

    # Extract values for each attribute
    attribute_values: dict[str, list[float]] = {}
    for attr in attributes:
        values = []
        for product in products:
            val = product.get(attr)
            if isinstance(val, (int, float)):
                values.append(float(val))
            else:
                values.append(0.0)
        attribute_values[attr] = values

    # Normalize each attribute
    normalized_values: dict[str, list[float]] = {}
    for attr, values in attribute_values.items():
        invert = directions.get(attr, "maximize") == "minimize"
        normalized_values[attr] = min_max_normalize(values, invert=invert)

    # Combine into product-level results
    for i in range(len(products)):
        product_scores: dict[str, float] = {}
        for attr in attributes:
            product_scores[attr] = normalized_values[attr][i]
        normalized_products.append(product_scores)

    return normalized_products
