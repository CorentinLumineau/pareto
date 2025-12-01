# Development Section - Navigation

> Setup guides, development workflows, and contribution guidelines

## Quick Reference

| File | Purpose |
|------|---------|
| [README.md](./README.md) | Quick start and overview |
| [database.md](./database.md) | Atlas database migrations (Prisma-like DX) |
| [devcontainer.md](./devcontainer.md) | VS Code devcontainer setup |

## Quick Commands

```bash
# Start everything (devcontainer recommended)
make devcontainer-up

# Start development servers
make dev

# Run tests
make test

# Run ALL quality checks
make verify

# Database management (Atlas)
make db-diff name=add_feature  # Generate migration
make db-apply                  # Apply migrations
make db-status                 # Check status
```

## Stack Versions (December 2025)

| Category | Technology | Version |
|----------|------------|---------|
| **Backend** | Go | 1.24.10 |
| **Backend** | Python | 3.14.0 |
| **Frontend** | Node.js | 24.x LTS |
| **Frontend** | Next.js | 16.0.3 |
| **Frontend** | React | 19.2.0 |
| **Frontend** | Tailwind CSS | 4.1.17 |
| **Mobile** | Expo SDK | 53 |
| **Mobile** | React Native | 0.79.0 |
| **Database** | PostgreSQL | 18.1 |
| **Database** | TimescaleDB | 2.23.0 |
| **Cache** | Redis | 8.4.0 |
| **Infra** | Docker | 29.1.1 |

## Project Structure

```
pareto/
├── apps/
│   ├── api/              # Go API server
│   │   ├── atlas.hcl     # Atlas migration config
│   │   ├── schema.sql    # Declarative schema (source of truth)
│   │   └── migrations/   # Auto-generated migrations
│   ├── workers/          # Python Celery workers
│   ├── web/              # Next.js frontend
│   └── mobile/           # Expo mobile app
├── packages/
│   ├── api-client/       # Shared API client
│   ├── types/            # Shared TypeScript types
│   └── utils/            # Shared utilities
├── make/                 # Modular Makefile (SOLID)
│   ├── dev.mk            # Development commands
│   ├── quality.mk        # Lint, test, verify
│   ├── docker.mk         # Docker management
│   ├── devcontainer.mk   # VS Code devcontainer
│   └── db.mk             # Atlas database commands
├── scripts/
│   └── verify/           # Quality verification scripts
├── Makefile              # Main entry point
└── documentation/
```

## Related Sections

- [Implementation](../implementation/) - Technical architecture
- [Milestones](../milestones/) - Development roadmap
- [Stack Reference](../reference/stack/) - Technology documentation
