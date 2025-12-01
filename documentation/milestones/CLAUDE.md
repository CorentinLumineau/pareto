# Milestones Section - Navigation

> **Initiative tracking, roadmap, and project phases**

## Quick Reference

| File | Purpose |
|------|---------|
| [MASTERPLAN.md](./MASTERPLAN.md) | Master Plan & Roadmap orchestrator |
| [foundation/](./foundation/) | Infrastructure, monorepo, legal |
| [scraper/](./scraper/) | Web scraping with anti-bot |
| [normalizer/](./normalizer/) | HTML parsing, data extraction |
| [catalog/](./catalog/) | Product database, API |
| [comparison/](./comparison/) | Pareto optimization engine |
| [affiliate/](./affiliate/) | Revenue tracking |
| [frontend/](./frontend/) | Next.js web app |
| [mobile/](./mobile/) | Expo iOS/Android apps |
| [launch/](./launch/) | Go-live preparation |

## Current Status

```
═══════════════════════════════════════════════════
  Current:  Foundation (Repository Setup)
  Progress: ~2% overall
  Target:   MVP in 14-16 weeks
═══════════════════════════════════════════════════
```

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
└── launch/                    # 2 weeks
```

## Initiative Overview

| # | Initiative | Phases | Effort | Dependencies |
|---|------------|--------|--------|--------------|
| 1 | [Foundation](./foundation/) | 3 | 1 day | None |
| 2 | [Scraper](./scraper/) | 5 | 3-4w | Foundation |
| 3 | [Normalizer](./normalizer/) | 4 | 2w | Scraper |
| 4 | [Catalog](./catalog/) | 4 | 2w | Normalizer |
| 5 | [Comparison](./comparison/) | 3 | 1.5w | Catalog |
| 6 | [Affiliate](./affiliate/) | 3 | 1w | Catalog |
| 7 | [Frontend Web](./frontend/) | 5 | 4w | Catalog, Comparison, Affiliate |
| 8 | [Mobile](./mobile/) | 5 | 4w | Catalog, Comparison, Affiliate |
| 9 | [Launch](./launch/) | 4 | 2w | All |

## Quick Navigation

### By Status
- **Active**: Foundation
- **Pending**: All others
- **Completed**: None yet

### By Timeline
```
Week  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16
      │───│───│───│───│───│───│───│───│───│───│───│───│───│───│───│
FOUND [█]
SCRAP     [███████]
NORM              [█████]
CATAL                   [█████]
COMP                          [███]
AFFIL                              [██]
WEB                                    [███████████]
MOBILE                                 [███████████]  (parallel)
LAUNC                                              [█████]
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
