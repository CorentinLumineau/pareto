"""Pareto frontier calculation using paretoset library."""

from typing import Any

import numpy as np
from paretoset import paretoset
from pydantic import BaseModel


class ComparisonCriterion(BaseModel):
    """Criterion for Pareto comparison."""

    attribute: str
    weight: float = 1.0
    direction: str = "maximize"  # "maximize" or "minimize"


class ParetoResult(BaseModel):
    """Result of Pareto calculation."""

    pareto_indices: list[int]
    dominated_indices: list[int]
    normalized_scores: dict[int, dict[str, float]]


class ParetoCalculator:
    """Calculate Pareto frontier for multi-objective optimization."""

    def __init__(self, criteria: list[ComparisonCriterion]) -> None:
        """Initialize calculator with criteria."""
        self.criteria = criteria

    def calculate(self, products: list[dict[str, Any]]) -> ParetoResult:
        """Calculate Pareto frontier for given products.

        Args:
            products: List of products with attributes matching criteria

        Returns:
            ParetoResult with pareto and dominated indices
        """
        if not products:
            return ParetoResult(
                pareto_indices=[],
                dominated_indices=[],
                normalized_scores={},
            )

        # Build attribute matrix
        n_products = len(products)
        n_criteria = len(self.criteria)
        matrix = np.zeros((n_products, n_criteria))

        for i, product in enumerate(products):
            for j, criterion in enumerate(self.criteria):
                value = product.get(criterion.attribute, 0)
                if isinstance(value, (int, float)):
                    matrix[i, j] = float(value)
                else:
                    matrix[i, j] = 0.0

        # Determine sense for each criterion (maximize = True)
        sense = [c.direction == "maximize" for c in self.criteria]

        # Calculate Pareto frontier
        pareto_mask = paretoset(matrix, sense=sense)

        pareto_indices = [i for i, is_pareto in enumerate(pareto_mask) if is_pareto]
        dominated_indices = [i for i, is_pareto in enumerate(pareto_mask) if not is_pareto]

        # Calculate normalized scores
        normalized_scores = self._normalize_scores(matrix)

        return ParetoResult(
            pareto_indices=pareto_indices,
            dominated_indices=dominated_indices,
            normalized_scores=normalized_scores,
        )

    def _normalize_scores(self, matrix: np.ndarray) -> dict[int, dict[str, float]]:
        """Normalize scores to 0-1 range using min-max normalization."""
        normalized: dict[int, dict[str, float]] = {}
        n_products, n_criteria = matrix.shape

        # Calculate min/max for each criterion
        mins = matrix.min(axis=0)
        maxs = matrix.max(axis=0)
        ranges = maxs - mins
        ranges[ranges == 0] = 1  # Avoid division by zero

        for i in range(n_products):
            scores: dict[str, float] = {}
            for j, criterion in enumerate(self.criteria):
                # Normalize to 0-1
                normalized_value = (matrix[i, j] - mins[j]) / ranges[j]

                # Apply weight
                weighted = normalized_value * criterion.weight

                # Invert if minimizing (so higher is always better)
                if criterion.direction == "minimize":
                    weighted = criterion.weight - weighted

                scores[criterion.attribute] = float(weighted)

            normalized[i] = scores

        return normalized
