# Pareto Optimization - Algorithm Details

## Overview

Pareto optimization is the mathematical foundation of the Comparator's value proposition. Instead of sorting products by a single dimension (price), we identify the **Pareto Frontier** - the set of products representing optimal trade-offs.

## Mathematical Definition

### Pareto Dominance

Product A **dominates** Product B if:
- A is **better or equal** on ALL objectives
- A is **strictly better** on AT LEAST ONE objective

```
Example:
Product A: Price=1000EUR, Performance=80
Product B: Price=1200EUR, Performance=75

A dominates B (cheaper AND better performance)
```

### Pareto Frontier

The **Pareto Frontier** (or Pareto Set) contains all non-dominated products.

```
Products:
- MacBook Pro: 1800EUR, 95pts -> Frontier (best performance)
- ThinkPad X1: 1500EUR, 88pts -> Frontier
- Dell XPS: 1200EUR, 82pts -> Frontier
- HP Pavilion: 800EUR, 70pts -> Frontier (cheapest)
- Laptop X: 1400EUR, 75pts -> DOMINATED by ThinkPad
```

## Algorithm Implementation

### Using `paretoset` Library (Python)

```python
from paretoset import paretoset
import numpy as np

# Products: [price, performance]
data = np.array([
    [1800, 95],  # MacBook
    [1500, 88],  # ThinkPad
    [1200, 82],  # Dell
    [800, 70],   # HP
    [1400, 75],  # Laptop X
])

# sense: "min" for price, "max" for performance
mask = paretoset(data, sense=["min", "max"])
# mask = [True, True, True, True, False]
```

### Complexity

- **2 objectives**: O(n log n) using sorting
- **k objectives**: O(n^2) or O(n log^(k-1) n) with advanced algorithms
- Our use case: 3-5 objectives, <1000 products = fast enough

## Z-Score Normalization

To fairly compare different units (EUR, GB, hours), we normalize using z-scores:

```
z = (value - mean) / std_deviation
```

### Why Z-Score over Min-Max?

- **Min-Max** is sensitive to outliers (one 10,000EUR laptop skews the whole scale)
- **Z-Score** preserves distribution and handles outliers better

### Implementation

```python
def normalize_objectives(products, objectives):
    """
    Normalize product attributes using z-scores
    Flip sign for minimization objectives
    """
    for obj in objectives:
        values = [p[obj.name] for p in products]
        mean = np.mean(values)
        std = np.std(values) or 1

        for p in products:
            z = (p[obj.name] - mean) / std
            if obj.sense == "min":
                z = -z  # Flip: lower is better -> higher z-score
            p[f"{obj.name}_normalized"] = z

    return products
```

## Weighted Utility Score

Users can assign weights to objectives (e.g., "Price is 3x more important than battery").

```
utility = sum(weight_i * z_score_i) / sum(weights)
```

### Example

```
User weights: price=3, performance=1, battery=1

Product A:
- price_z = -0.5 (below average price = good)
- performance_z = 1.2
- battery_z = 0.3

utility = (3*0.5 + 1*1.2 + 1*0.3) / 5 = 0.6
```

## Visualization

### Scatter Plot with Frontier

```
Performance
    ^
95  |           * MacBook
    |       * ThinkPad
88  |
    |     * Dell
82  |
    |   X <- Laptop X (dominated, grayed)
75  |
    | * HP
70  |______________________> Price
    800  1000  1200  1500  1800
```

- **Blue dots**: Pareto-optimal products
- **Gray dots**: Dominated products
- **Line**: Pareto frontier curve

### Frontend Component

The `ParetoChart.tsx` component uses Recharts to:
1. Plot all products as scatter points
2. Highlight Pareto-optimal products in blue
3. Draw frontier line connecting optimal points
4. Show tooltip with product details on hover

## API Integration

### Request

```json
POST /api/compare
{
  "product_ids": ["uuid1", "uuid2", ...],
  "objectives": [
    {"name": "price", "sense": "min", "weight": 2.0},
    {"name": "performance", "sense": "max", "weight": 1.0},
    {"name": "battery_hours", "sense": "max", "weight": 1.0}
  ]
}
```

### Response

```json
{
  "pareto_ids": ["uuid1", "uuid3", "uuid5"],
  "dominated_ids": ["uuid2", "uuid4"],
  "scores": {
    "uuid1": 85.5,
    "uuid2": 62.3,
    "uuid3": 91.0,
    ...
  },
  "frontier_data": [
    {
      "id": "uuid1",
      "name": "MacBook Pro",
      "is_pareto": true,
      "score": 85.5,
      "objectives": {
        "price": {"value": 1800, "sense": "min"},
        "performance": {"value": 95, "sense": "max"}
      }
    },
    ...
  ]
}
```

## Caching Strategy

Pareto calculations are computationally intensive. We cache results:

- **Key**: `pareto:{sorted_product_ids_hash}:{objectives_hash}`
- **TTL**: 1 hour (prices change frequently)
- **Invalidation**: On price update for any included product

## Edge Cases

### 1. Single Product
- Return as Pareto-optimal (no competition)

### 2. Missing Attributes
- Exclude product from comparison for that objective
- Or: Impute with category average (configurable)

### 3. All Products Dominated
- Should never happen mathematically
- If occurs: data error, return all as Pareto

### 4. Ties
- Products with identical values on all objectives
- Both are Pareto-optimal

---

**See Also**:
- [Comparison Engine Spec](../reference/specs/comparaison-catalog.md)
- [Implementation](../implementation/README.md)
