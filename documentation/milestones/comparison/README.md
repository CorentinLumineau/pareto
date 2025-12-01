# Comparison Initiative

> **Pareto optimization engine for multi-objective product comparison**

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                          COMPARISON INITIATIVE                                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Status:     ⏳ PENDING                                                       ║
║  Effort:     1.5 weeks (7 days)                                              ║
║  Depends:    Catalog                                                         ║
║  Unlocks:    Frontend                                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Objective

Build the core differentiator: multi-objective Pareto optimization that helps users find the best trade-offs between price, performance, and features - not just the cheapest option.

## What is Pareto Optimization?

```
┌─────────────────────────────────────────────────────────────────┐
│                    PARETO FRONTIER                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Performance │                                                  │
│      ↑       │        ★ A (Best performance, highest price)     │
│      │       │      ★ B                                         │
│      │       │    ★ C        ← Pareto Frontier                  │
│      │       │  ★ D            (optimal trade-offs)             │
│      │       │                                                  │
│      │       │    • E  • F     ← Dominated products             │
│      │       │        • G        (worse in all aspects)         │
│      │       │                                                  │
│      └───────┴───────────────────────────────────→ Price        │
│                                                                 │
│  Products A, B, C, D are Pareto-optimal (on the frontier)       │
│  Products E, F, G are dominated (there's always a better one)   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     COMPARISON MODULE                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Frontend ─────► Go API ─────► Python Worker                   │
│   (request)      (orchestrate)   (calculate)                    │
│                                                                 │
│                       │              │                          │
│                       ▼              ▼                          │
│                   Catalog        paretoset                      │
│                   (products)     (algorithm)                    │
│                                                                 │
│                                      │                          │
│                                      ▼                          │
│                              Pareto Results                     │
│                              + Z-scores                         │
│                              + Rankings                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| API Layer | Go + Gin | Request handling |
| Calculation | Python | Pareto algorithm |
| Library | paretoset | Efficient Pareto calculation |
| Scoring | scipy | Z-score normalization |
| Cache | Redis | Result caching |

## Phases

| # | Phase | Effort | Description |
|---|-------|--------|-------------|
| 01 | [Pareto Engine](./01-pareto-engine.md) | 3d | Python paretoset implementation |
| 02 | [API Integration](./02-api-integration.md) | 2d | Go API endpoints |
| 03 | [Scoring & Ranking](./03-scoring.md) | 2d | Z-scores, rankings |

## Comparison Criteria

For smartphones MVP, we optimize on these objectives:

| Criterion | Type | Weight | Source |
|-----------|------|--------|--------|
| Price | Minimize | High | Offers table |
| Storage | Maximize | Medium | Attributes |
| RAM | Maximize | Medium | Attributes |
| Battery | Maximize | Low | Attributes |
| Screen Size | Maximize | Low | Attributes |

## Example Flow

```python
# Input: User wants to compare all iPhones
products = [
    {"id": "1", "name": "iPhone 15", "price": 899, "storage": 128, "ram": 6},
    {"id": "2", "name": "iPhone 15 Plus", "price": 999, "storage": 128, "ram": 6},
    {"id": "3", "name": "iPhone 15 Pro", "price": 1199, "storage": 256, "ram": 8},
    {"id": "4", "name": "iPhone 15 Pro Max", "price": 1399, "storage": 256, "ram": 8},
    {"id": "5", "name": "iPhone 14", "price": 699, "storage": 128, "ram": 6},
]

# Output: Pareto frontier + scores
{
    "frontier": ["1", "3", "5"],  # Optimal trade-offs
    "dominated": ["2", "4"],       # Strictly worse options exist
    "scores": {
        "1": {"overall": 0.72, "value": 0.85, "performance": 0.60},
        "3": {"overall": 0.78, "value": 0.65, "performance": 0.90},
        "5": {"overall": 0.68, "value": 0.95, "performance": 0.50},
    }
}
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/compare` | Compare products |
| GET | `/api/v1/compare/criteria` | Available criteria |
| POST | `/api/v1/compare/frontier` | Get Pareto frontier |

## Success Metrics

| Metric | Target |
|--------|--------|
| Comparison latency | <500ms |
| Cache hit rate | >70% |
| Pareto calculation | <100ms for 100 products |

## Deliverables

- [ ] Python Pareto engine
- [ ] Go API integration
- [ ] Z-score normalization
- [ ] Product ranking
- [ ] Result caching
- [ ] Frontend-ready responses

---

**Depends on**: [Catalog](../catalog/)
**Unlocks**: [Frontend](../frontend/)
**Back to**: [MASTERPLAN](../MASTERPLAN.md)
