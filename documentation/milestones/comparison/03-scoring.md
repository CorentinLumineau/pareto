# Phase 03: Scoring & Ranking

> **Z-score normalization and product rankings**

```
╔════════════════════════════════════════════════════════════════╗
║  Phase:      03 - Scoring & Ranking                            ║
║  Initiative: Comparison                                        ║
║  Status:     ⏳ PENDING                                        ║
║  Effort:     2 days                                            ║
╚════════════════════════════════════════════════════════════════╝
```

## Objective

Implement Z-score normalization for fair comparison across different scales and create meaningful product rankings.

## Tasks

- [ ] Implement Z-score normalization
- [ ] Create composite scoring system
- [ ] Add value-for-money calculation
- [ ] Build ranking algorithms
- [ ] Add score explanations

## Z-Score Normalization

```python
# apps/workers/src/pareto/scoring.py
import numpy as np
from scipy import stats
from dataclasses import dataclass
from typing import List, Dict, Optional
from enum import Enum

class ScoreType(Enum):
    OVERALL = "overall"
    VALUE = "value"
    PERFORMANCE = "performance"
    BALANCED = "balanced"

@dataclass
class ScoringResult:
    """Complete scoring result for a product."""
    product_id: str
    overall: float
    value: float          # Price vs features
    performance: float    # Raw specs
    balanced: float       # Weighted combination
    percentile: float     # Position among all products
    explanation: str

class ProductScorer:
    """Z-score based product scoring."""

    def __init__(self, criteria_weights: Dict[str, float] = None):
        self.weights = criteria_weights or {
            "price": 1.0,
            "storage": 0.8,
            "ram": 0.6,
            "battery": 0.4,
            "screen_size": 0.3,
        }

    def score_products(
        self,
        products: List[Dict],
        frontier_ids: List[str]
    ) -> Dict[str, ScoringResult]:
        """
        Score all products using Z-score normalization.

        Z-score = (value - mean) / std_dev
        This normalizes all criteria to the same scale.
        """
        if len(products) < 2:
            return {}

        # Extract values into arrays
        criteria_values = self._extract_values(products)

        # Calculate Z-scores for each criterion
        z_scores = {}
        for criterion, values in criteria_values.items():
            arr = np.array(values)
            if np.std(arr) > 0:
                z_scores[criterion] = stats.zscore(arr)
            else:
                z_scores[criterion] = np.zeros_like(arr)

        # Calculate composite scores
        results = {}
        for i, product in enumerate(products):
            pid = product["id"]

            # Overall score (weighted Z-scores)
            overall = self._calculate_overall(z_scores, i)

            # Value score (price efficiency)
            value = self._calculate_value(z_scores, i)

            # Performance score (raw specs)
            performance = self._calculate_performance(z_scores, i)

            # Balanced score
            balanced = (overall + value + performance) / 3

            # Percentile
            percentile = self._calculate_percentile(overall, [
                self._calculate_overall(z_scores, j)
                for j in range(len(products))
            ])

            # Explanation
            is_frontier = pid in frontier_ids
            explanation = self._generate_explanation(
                product, z_scores, i, is_frontier
            )

            results[pid] = ScoringResult(
                product_id=pid,
                overall=float(self._normalize_score(overall)),
                value=float(self._normalize_score(value)),
                performance=float(self._normalize_score(performance)),
                balanced=float(self._normalize_score(balanced)),
                percentile=float(percentile),
                explanation=explanation
            )

        return results

    def _extract_values(self, products: List[Dict]) -> Dict[str, List[float]]:
        """Extract criterion values from products."""
        criteria_values = {c: [] for c in self.weights.keys()}

        for product in products:
            values = product.get("values", {})
            for criterion in self.weights.keys():
                criteria_values[criterion].append(
                    values.get(criterion, 0)
                )

        return criteria_values

    def _calculate_overall(self, z_scores: Dict, idx: int) -> float:
        """Calculate weighted overall score."""
        total = 0
        total_weight = 0

        for criterion, weight in self.weights.items():
            if criterion in z_scores:
                z = z_scores[criterion][idx]
                # Invert price (lower is better)
                if criterion == "price":
                    z = -z
                total += z * weight
                total_weight += weight

        return total / total_weight if total_weight > 0 else 0

    def _calculate_value(self, z_scores: Dict, idx: int) -> float:
        """Calculate value-for-money score."""
        # Compare specs to price
        spec_criteria = ["storage", "ram", "battery", "screen_size"]
        spec_score = sum(
            z_scores.get(c, [0])[idx] * self.weights.get(c, 0)
            for c in spec_criteria
        )

        price_z = z_scores.get("price", [0])[idx]

        # High specs + low price = high value
        return spec_score - price_z

    def _calculate_performance(self, z_scores: Dict, idx: int) -> float:
        """Calculate raw performance score (ignoring price)."""
        spec_criteria = ["storage", "ram", "battery", "screen_size"]
        return sum(
            z_scores.get(c, [0])[idx]
            for c in spec_criteria
        ) / len(spec_criteria)

    def _normalize_score(self, score: float) -> float:
        """Normalize Z-score to 0-100 scale."""
        # Z-scores typically range from -3 to +3
        # Map to 0-100
        normalized = (score + 3) / 6 * 100
        return max(0, min(100, normalized))

    def _calculate_percentile(self, score: float, all_scores: List[float]) -> float:
        """Calculate percentile rank."""
        below = sum(1 for s in all_scores if s < score)
        return below / len(all_scores) * 100

    def _generate_explanation(
        self,
        product: Dict,
        z_scores: Dict,
        idx: int,
        is_frontier: bool
    ) -> str:
        """Generate human-readable explanation."""
        explanations = []

        if is_frontier:
            explanations.append("Choix optimal (frontière Pareto)")

        # Find strengths
        strengths = []
        weaknesses = []

        for criterion, z_arr in z_scores.items():
            z = z_arr[idx]
            if criterion == "price":
                z = -z  # Invert for price

            if z > 1:
                label = self._criterion_label(criterion)
                strengths.append(f"excellent {label}")
            elif z < -1:
                label = self._criterion_label(criterion)
                weaknesses.append(f"{label} en dessous de la moyenne")

        if strengths:
            explanations.append("Points forts: " + ", ".join(strengths[:2]))
        if weaknesses:
            explanations.append("Points faibles: " + ", ".join(weaknesses[:2]))

        return ". ".join(explanations) if explanations else "Produit dans la moyenne"

    def _criterion_label(self, criterion: str) -> str:
        """Get French label for criterion."""
        labels = {
            "price": "prix",
            "storage": "stockage",
            "ram": "RAM",
            "battery": "batterie",
            "screen_size": "taille d'écran"
        }
        return labels.get(criterion, criterion)
```

## Ranking System

```python
# apps/workers/src/pareto/ranking.py
from dataclasses import dataclass
from typing import List, Dict
from enum import Enum

class RankingStrategy(Enum):
    OVERALL = "overall"          # Best overall score
    VALUE = "value"              # Best value for money
    PREMIUM = "premium"          # Best performance regardless of price
    BUDGET = "budget"            # Best among cheapest
    BALANCED = "balanced"        # Most balanced trade-offs

@dataclass
class RankedProduct:
    """Product with ranking information."""
    product_id: str
    rank: int
    score: float
    badge: str | None  # "Meilleur choix", "Meilleur rapport qualité-prix", etc.

class ProductRanker:
    """Rank products using different strategies."""

    BADGES = {
        RankingStrategy.OVERALL: "Meilleur choix",
        RankingStrategy.VALUE: "Meilleur rapport qualité-prix",
        RankingStrategy.PREMIUM: "Premium",
        RankingStrategy.BUDGET: "Choix économique",
        RankingStrategy.BALANCED: "Le plus équilibré",
    }

    def rank(
        self,
        products: List[Dict],
        scores: Dict[str, "ScoringResult"],
        strategy: RankingStrategy = RankingStrategy.OVERALL
    ) -> List[RankedProduct]:
        """Rank products according to strategy."""
        if not products:
            return []

        # Get score attribute based on strategy
        score_attr = {
            RankingStrategy.OVERALL: "overall",
            RankingStrategy.VALUE: "value",
            RankingStrategy.PREMIUM: "performance",
            RankingStrategy.BUDGET: "value",
            RankingStrategy.BALANCED: "balanced",
        }[strategy]

        # Filter for budget strategy
        filtered = products
        if strategy == RankingStrategy.BUDGET:
            prices = [p.get("values", {}).get("price", float("inf")) for p in products]
            median_price = sorted(prices)[len(prices) // 2]
            filtered = [p for p in products if p.get("values", {}).get("price", float("inf")) <= median_price]

        # Sort by score
        sorted_products = sorted(
            filtered,
            key=lambda p: getattr(scores.get(p["id"]), score_attr, 0),
            reverse=True
        )

        # Build ranked list
        results = []
        for i, product in enumerate(sorted_products):
            pid = product["id"]
            score_result = scores.get(pid)

            badge = None
            if i == 0:
                badge = self.BADGES[strategy]

            results.append(RankedProduct(
                product_id=pid,
                rank=i + 1,
                score=getattr(score_result, score_attr, 0) if score_result else 0,
                badge=badge
            ))

        return results

    def get_top_picks(
        self,
        products: List[Dict],
        scores: Dict[str, "ScoringResult"],
        frontier_ids: List[str]
    ) -> Dict[str, RankedProduct]:
        """Get top pick for each category."""
        picks = {}

        for strategy in RankingStrategy:
            ranked = self.rank(products, scores, strategy)
            # Only consider frontier products for top picks
            for rp in ranked:
                if rp.product_id in frontier_ids:
                    picks[strategy.value] = rp
                    break

        return picks
```

## Integration with API

```python
# apps/workers/src/pareto/api.py (extended)
from .scoring import ProductScorer, ScoringResult
from .ranking import ProductRanker, RankingStrategy

@app.post("/compare/detailed", response_model=DetailedCompareResponse)
def compare_detailed(request: CompareRequest):
    """Compare with detailed scoring and rankings."""
    # Calculate Pareto
    calculator = ParetoCalculator(...)
    pareto_result = calculator.calculate(...)

    # Calculate scores
    scorer = ProductScorer()
    scores = scorer.score_products(
        [{"id": p.id, "values": p.values} for p in request.products],
        pareto_result.frontier
    )

    # Get rankings
    ranker = ProductRanker()
    rankings = {
        strategy.value: ranker.rank(
            [{"id": p.id, "values": p.values} for p in request.products],
            scores,
            strategy
        )
        for strategy in RankingStrategy
    }

    # Get top picks
    top_picks = ranker.get_top_picks(
        [{"id": p.id, "values": p.values} for p in request.products],
        scores,
        pareto_result.frontier
    )

    return DetailedCompareResponse(
        frontier=pareto_result.frontier,
        dominated=pareto_result.dominated,
        scores={k: v.__dict__ for k, v in scores.items()},
        rankings=rankings,
        top_picks=top_picks
    )
```

## Deliverables

- [ ] Z-score normalization
- [ ] Composite scoring (overall, value, performance)
- [ ] Multiple ranking strategies
- [ ] Score explanations in French
- [ ] Top picks per category
- [ ] Unit tests

---

**Previous Phase**: [02-api-integration.md](./02-api-integration.md)
**Back to**: [Comparison README](./README.md)
