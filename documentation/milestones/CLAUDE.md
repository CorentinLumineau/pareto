# Milestones Section - Navigation

> **Initiative tracking, roadmap, and project phases**

## Quick Reference

| File | Purpose | Status |
|------|---------|--------|
| [MASTERPLAN.md](./MASTERPLAN.md) | Master Plan & Roadmap orchestrator | Active |
| [foundation/](./foundation/) | Infrastructure, monorepo, legal | ✅ Complete |
| [scraper/](./scraper/) | Brand-first scraping | ⏳ In Progress |
| [normalizer/](./normalizer/) | Brand page parsing | ⏳ Pending (20%) |
| [catalog/](./catalog/) | Product database, API | ⏳ Pending (5%) |
| [comparison/](./comparison/) | Pareto optimization engine | ⏳ Pending (60%) |
| [affiliate/](./affiliate/) | Revenue tracking | ⏳ Pending |
| [frontend/](./frontend/) | Next.js 16 web app | ⏳ Pending (10%) |
| [mobile/](./mobile/) | Expo SDK 53 apps | ⏳ Pending (10%) |
| [launch/](./launch/) | Go-live preparation | ⏳ Pending |
| [quality-enforcement/](./quality-enforcement/) | `make verify`, coverage, type safety | ✅ Complete |

## Current Status

```
═══════════════════════════════════════════════════
  Current:  Scraper (Brand-First Approach)
  Progress: ~25% overall
  Target:   MVP in 10-12 weeks
═══════════════════════════════════════════════════
```

## Data Strategy

**Brand-First Scraping**: Complete specs from brand websites (Apple, Samsung, etc.), prices from marketplaces (Amazon, Fnac, etc.). See [scraping-strategy.md](../implementation/scraping-strategy.md).

## Initiative Structure

Each initiative follows a flat structure:

```
milestones/
├── MASTERPLAN.md              # Orchestrates all initiatives
├── foundation/                # 1 day
│   ├── README.md              # Initiative overview
│   ├── 01-infrastructure.md   # Phase 1
│   ├── 02-monorepo.md         # Phase 2
│   └── 03-legal.md            # Phase 3
├── scraper/                   # 3-4 weeks
│   ├── README.md
│   ├── 01-skeleton.md
│   ├── 02-antibot.md
│   ├── 03-queue.md
│   ├── 04-retailers-1.md
│   └── 05-retailers-2.md
├── normalizer/                # 2 weeks
├── catalog/                   # 2 weeks
├── comparison/                # 1.5 weeks
├── affiliate/                 # 1 week
├── frontend/                  # 4 weeks (web)
├── mobile/                    # 4 weeks (parallel with web)
├── launch/                    # 2 weeks
└── quality-enforcement/       # 1.5 weeks (cross-cutting)
```

## Initiative Overview

| # | Initiative | Milestones | Effort | Progress |
|---|------------|------------|--------|----------|
| 1 | [Foundation](./foundation/) | 3 | 1 day | ✅ 100% |
| 2 | [Scraper](./scraper/) | 4 | 2-3w | ⏳ 10% |
| 3 | [Normalizer](./normalizer/) | 4 | 1.5w | ⏳ 20% |
| 4 | [Catalog](./catalog/) | 4 | 2w | ⏳ 5% |
| 5 | [Comparison](./comparison/) | 3 | 1w | ⏳ 60% |
| 6 | [Affiliate](./affiliate/) | 3 | 1w | ⏳ 0% |
| 7 | [Frontend Web](./frontend/) | 5 | 3w | ⏳ 10% |
| 8 | [Mobile](./mobile/) | 5 | 3w | ⏳ 10% |
| 9 | [Launch](./launch/) | 4 | 2w | ⏳ 0% |
| 10 | [Quality Enforcement](./quality-enforcement/) | 6 | 1.5w | ✅ 100% |

## Quick Navigation

### By Status
- **Completed**: Foundation ✅, Quality Enforcement ✅
- **Active**: Scraper (brand-first)
- **Pending**: Normalizer, Catalog, Comparison, Affiliate, Frontend, Mobile, Launch

### By Timeline (Updated)
```
Week  1   2   3   4   5   6   7   8   9  10  11  12
      │───│───│───│───│───│───│───│───│───│───│───│
FOUND [✓] DONE
SCRAP     [██████]
NORM            [████]
CATAL                 [█████]
COMP                        [███]
AFFIL                            [██]
WEB                               [████████]
MOBILE                            [████████]  (parallel)
LAUNC                                      [████]
```

## Related Sections

- [Implementation](../implementation/) - Technical specs
- [Development](../development/) - Setup guide
- [Domain](../domain/) - Business rules
- [Reference](../reference/) - Stack docs

## Usage

```bash
# View master plan
cat milestones/MASTERPLAN.md

# View specific initiative
cat milestones/scraper/README.md

# Check all phase files
ls milestones/*/
```
