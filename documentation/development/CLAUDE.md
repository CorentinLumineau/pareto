# Development Section - Navigation

> Setup guides, development workflows, and contribution guidelines

## Quick Reference

| File | Purpose |
|------|---------|
| [README.md](./README.md) | Quick start and overview |

## Quick Commands

```bash
# Start everything
docker compose up -d

# Start development
make dev

# Run tests
make test

# Build for production
make build
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
│   ├── api/         # Go API server
│   ├── workers/     # Python Celery workers
│   ├── web/         # Next.js frontend
│   └── mobile/      # Expo mobile app
├── packages/
│   ├── api-client/  # Shared API client
│   ├── types/       # Shared TypeScript types
│   └── utils/       # Shared utilities
├── docker-compose.yml
└── documentation/
```

## Related Sections

- [Implementation](../implementation/) - Technical architecture
- [Milestones](../milestones/) - Development roadmap
- [Stack Reference](../reference/stack/) - Technology documentation
