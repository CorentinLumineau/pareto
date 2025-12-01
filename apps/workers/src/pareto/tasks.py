"""Celery tasks for Pareto calculation."""

from typing import Any

from src.tasks.celery_app import app
from .calculator import ComparisonCriterion, ParetoCalculator


@app.task(name="src.pareto.tasks.calculate_pareto")
def calculate_pareto(
    products: list[dict[str, Any]],
    criteria: list[dict[str, Any]],
) -> dict[str, Any]:
    """Calculate Pareto frontier for products.

    Args:
        products: List of product dictionaries with attributes
        criteria: List of criteria dicts with attribute, weight, direction

    Returns:
        Dictionary with pareto_indices, dominated_indices, normalized_scores
    """
    # Convert criteria dicts to models
    criterion_models = [
        ComparisonCriterion(
            attribute=c["attribute"],
            weight=c.get("weight", 1.0),
            direction=c.get("direction", "maximize"),
        )
        for c in criteria
    ]

    # Calculate
    calculator = ParetoCalculator(criterion_models)
    result = calculator.calculate(products)

    return {
        "pareto_indices": result.pareto_indices,
        "dominated_indices": result.dominated_indices,
        "normalized_scores": result.normalized_scores,
    }
