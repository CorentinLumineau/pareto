# Phase 01: Pareto Engine

> **Python paretoset implementation**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      01 - Pareto Engine                                ║
║  Initiative: Comparison                                        ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     3 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Implement the core Pareto optimization algorithm using the `paretoset` library.

## Tasks

- [ ] Setup Pareto calculation module
- [ ] Implement multi-objective optimization
- [ ] Handle missing data gracefully
- [ ] Create Celery task for async calculation
- [ ] Add unit tests

## Pareto Calculator

```python
# apps/workers/src/pareto/calculator.py
import numpy as np
from paretoset import paretoset
from dataclasses import dataclass
from typing import List, Dict, Optional
from enum import Enum

class ObjectiveType(Enum):
    MINIMIZE = "min"
    MAXIMIZE = "max"

@dataclass
class Criterion:
    """A comparison criterion."""
    name: str
    objective: ObjectiveType
    weight: float = 1.0
    default_value: Optional[float] = None

@dataclass
class Product:
    """Product for comparison."""
    id: str
    name: str
    values: Dict[str, float]

@dataclass
class ParetoResult:
    """Result of Pareto optimization."""
    frontier: List[str]           # Product IDs on frontier
    dominated: List[str]          # Dominated product IDs
    mask: np.ndarray              # Boolean mask of frontier
    scores: Dict[str, Dict[str, float]]  # Per-product scores

class ParetoCalculator:
    """Multi-objective Pareto optimization."""

    # Default criteria for smartphones
    DEFAULT_CRITERIA = [
        Criterion("price", ObjectiveType.MINIMIZE, weight=1.0, default_value=9999),
        Criterion("storage", ObjectiveType.MAXIMIZE, weight=0.8, default_value=0),
        Criterion("ram", ObjectiveType.MAXIMIZE, weight=0.6, default_value=0),
        Criterion("battery", ObjectiveType.MAXIMIZE, weight=0.4, default_value=0),
        Criterion("screen_size", ObjectiveType.MAXIMIZE, weight=0.3, default_value=0),
    ]

    def __init__(self, criteria: List[Criterion] = None):
        self.criteria = criteria or self.DEFAULT_CRITERIA

    def calculate(self, products: List[Product]) -> ParetoResult:
        """
        Calculate Pareto frontier for products.

        Returns products that are not dominated by any other product.
        A product dominates another if it's better or equal in all criteria
        and strictly better in at least one.
        """
        if not products:
            return ParetoResult([], [], np.array([]), {})

        # Build data matrix
        data = self._build_matrix(products)

        # Build sense array (True = maximize, False = minimize)
        sense = np.array([
            c.objective == ObjectiveType.MAXIMIZE
            for c in self.criteria
        ])

        # Calculate Pareto frontier
        mask = paretoset(data, sense=sense)

        # Separate frontier and dominated
        frontier = [p.id for p, m in zip(products, mask) if m]
        dominated = [p.id for p, m in zip(products, mask) if not m]

        # Calculate scores
        scores = self._calculate_scores(products, data, mask)

        return ParetoResult(
            frontier=frontier,
            dominated=dominated,
            mask=mask,
            scores=scores
        )

    def _build_matrix(self, products: List[Product]) -> np.ndarray:
        """Build data matrix for paretoset."""
        n_products = len(products)
        n_criteria = len(self.criteria)
        data = np.zeros((n_products, n_criteria))

        for i, product in enumerate(products):
            for j, criterion in enumerate(self.criteria):
                value = product.values.get(criterion.name)
                if value is None:
                    value = criterion.default_value or 0
                data[i, j] = value

        return data

    def _calculate_scores(
        self,
        products: List[Product],
        data: np.ndarray,
        mask: np.ndarray
    ) -> Dict[str, Dict[str, float]]:
        """Calculate weighted scores for each product."""
        scores = {}

        # Normalize each column to 0-1
        normalized = np.zeros_like(data)
        for j, criterion in enumerate(self.criteria):
            col = data[:, j]
            col_min, col_max = col.min(), col.max()

            if col_max - col_min > 0:
                normalized[:, j] = (col - col_min) / (col_max - col_min)
            else:
                normalized[:, j] = 0.5

            # Flip for minimization objectives
            if criterion.objective == ObjectiveType.MINIMIZE:
                normalized[:, j] = 1 - normalized[:, j]

        # Calculate weighted scores
        weights = np.array([c.weight for c in self.criteria])
        weights = weights / weights.sum()

        weighted_scores = (normalized * weights).sum(axis=1)

        for i, product in enumerate(products):
            scores[product.id] = {
                "overall": float(weighted_scores[i]),
                "is_frontier": bool(mask[i]),
                "criteria": {
                    c.name: float(normalized[i, j])
                    for j, c in enumerate(self.criteria)
                }
            }

        return scores
```

## Celery Task

```python
# apps/workers/src/pareto/tasks.py
from celery import shared_task
from typing import List, Dict
from .calculator import ParetoCalculator, Product, Criterion, ObjectiveType

@shared_task
def calculate_pareto(
    products: List[Dict],
    criteria: List[Dict] = None
) -> Dict:
    """
    Calculate Pareto frontier for products.

    Args:
        products: List of product dicts with 'id', 'name', 'values'
        criteria: Optional custom criteria

    Returns:
        Dict with frontier, dominated, and scores
    """
    # Convert to Product objects
    product_objects = [
        Product(
            id=p["id"],
            name=p["name"],
            values=p.get("values", {})
        )
        for p in products
    ]

    # Convert criteria if provided
    criterion_objects = None
    if criteria:
        criterion_objects = [
            Criterion(
                name=c["name"],
                objective=ObjectiveType(c.get("objective", "max")),
                weight=c.get("weight", 1.0),
                default_value=c.get("default_value")
            )
            for c in criteria
        ]

    # Calculate
    calculator = ParetoCalculator(criterion_objects)
    result = calculator.calculate(product_objects)

    return {
        "frontier": result.frontier,
        "dominated": result.dominated,
        "scores": result.scores,
        "total": len(products),
        "frontier_count": len(result.frontier),
    }
```

## HTTP API for Go Communication

```python
# apps/workers/src/pareto/api.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional
from .calculator import ParetoCalculator, Product, Criterion, ObjectiveType

app = FastAPI(title="Pareto API")

class ProductInput(BaseModel):
    id: str
    name: str
    values: Dict[str, float]

class CriterionInput(BaseModel):
    name: str
    objective: str = "max"
    weight: float = 1.0
    default_value: Optional[float] = None

class CompareRequest(BaseModel):
    products: List[ProductInput]
    criteria: Optional[List[CriterionInput]] = None

class CompareResponse(BaseModel):
    frontier: List[str]
    dominated: List[str]
    scores: Dict[str, Dict[str, float]]
    total: int
    frontier_count: int

@app.post("/compare", response_model=CompareResponse)
def compare_products(request: CompareRequest):
    """Calculate Pareto frontier for products."""
    if len(request.products) < 2:
        raise HTTPException(400, "Need at least 2 products to compare")

    products = [
        Product(id=p.id, name=p.name, values=p.values)
        for p in request.products
    ]

    criteria = None
    if request.criteria:
        criteria = [
            Criterion(
                name=c.name,
                objective=ObjectiveType(c.objective),
                weight=c.weight,
                default_value=c.default_value
            )
            for c in request.criteria
        ]

    calculator = ParetoCalculator(criteria)
    result = calculator.calculate(products)

    return CompareResponse(
        frontier=result.frontier,
        dominated=result.dominated,
        scores=result.scores,
        total=len(products),
        frontier_count=len(result.frontier)
    )

@app.get("/health")
def health():
    return {"status": "ok"}
```

## Unit Tests

```python
# apps/workers/tests/pareto/test_calculator.py
import pytest
from src.pareto.calculator import ParetoCalculator, Product, Criterion, ObjectiveType

@pytest.fixture
def calculator():
    criteria = [
        Criterion("price", ObjectiveType.MINIMIZE),
        Criterion("performance", ObjectiveType.MAXIMIZE),
    ]
    return ParetoCalculator(criteria)

@pytest.fixture
def sample_products():
    return [
        Product("A", "High perf, high price", {"price": 1000, "performance": 100}),
        Product("B", "Med perf, med price", {"price": 700, "performance": 70}),
        Product("C", "Low perf, low price", {"price": 400, "performance": 40}),
        Product("D", "Dominated by B", {"price": 800, "performance": 60}),
    ]

def test_pareto_frontier(calculator, sample_products):
    result = calculator.calculate(sample_products)

    # A, B, C should be on frontier
    assert set(result.frontier) == {"A", "B", "C"}
    # D is dominated
    assert result.dominated == ["D"]

def test_scores_calculated(calculator, sample_products):
    result = calculator.calculate(sample_products)

    # All products should have scores
    assert len(result.scores) == 4

    # Frontier products marked correctly
    assert result.scores["A"]["is_frontier"] is True
    assert result.scores["D"]["is_frontier"] is False

def test_empty_products(calculator):
    result = calculator.calculate([])
    assert result.frontier == []
    assert result.dominated == []

def test_single_product(calculator):
    products = [Product("A", "Only one", {"price": 500, "performance": 50})]
    result = calculator.calculate(products)
    assert result.frontier == ["A"]
    assert result.dominated == []
```

## Dependencies

```toml
# Add to apps/workers/pyproject.toml
[project.dependencies]
paretoset = ">=1.2.0"
numpy = ">=1.24.0"
fastapi = ">=0.104.0"
uvicorn = ">=0.24.0"
```

## Deliverables

- [ ] ParetoCalculator class
- [ ] Multi-criteria support
- [ ] Celery task integration
- [ ] FastAPI HTTP endpoint
- [ ] Unit tests >90% coverage

---

**Next Phase**: [02-api-integration.md](./02-api-integration.md)
**Back to**: [Comparison README](./README.md)
