# Development - Setup & Workflows

> **Getting started guide, local development setup, and contribution workflows**

## Quick Start

### Option 1: Devcontainer (Recommended)

The fastest way to start developing - everything runs in containers with hot reload:

1. Open project in VS Code
2. Press `F1` → "Dev Containers: Reopen in Container"
3. Wait for build (~5 minutes first time)
4. Run `dev` to start all services

See [Devcontainer Guide](./devcontainer.md) for details.

### Option 2: Local Setup

```bash
# 1. Clone repository
git clone https://github.com/clumineau/pareto-comparator.git
cd pareto-comparator

# 2. Install dependencies
make install

# 3. Start infrastructure (PostgreSQL, Redis)
make docker-up

# 4. Start all services with Turbo
make dev
```

## Prerequisites

### For Devcontainer (Recommended)

| Tool | Purpose | Installation |
|------|---------|--------------|
| **Docker Desktop** | Container runtime | [docker.com](https://docker.com) |
| **VS Code** | Editor | [code.visualstudio.com](https://code.visualstudio.com) |
| **Dev Containers Extension** | VS Code extension | Install from VS Code |

### For Local Development

| Tool | Version | Installation |
|------|---------|--------------|
| **Go** | 1.24+ | [golang.org/dl](https://golang.org/dl/) |
| **Python** | 3.14+ | [python.org](https://python.org) or `pyenv` |
| **Node.js** | 24.x LTS | [nodejs.org](https://nodejs.org) or `nvm` |
| **pnpm** | 9.14+ | `npm install -g pnpm` |
| **Docker** | 29+ | [docker.com](https://docker.com) |
| **Docker Compose** | 2.x | Included with Docker Desktop |

### Optional Tools

| Tool | Purpose |
|------|---------|
| **Make** | Task runner (Makefile) |
| **direnv** | Environment variable management |
| **lazydocker** | Docker TUI |
| **pgcli** | PostgreSQL CLI with autocomplete |

## Project Structure

```
pareto-comparator/
├── backend/                 # Go monolith
│   ├── cmd/server/          # Entry point
│   ├── internal/            # Private packages
│   │   ├── catalog/         # Products, prices, categories
│   │   ├── scraper/         # Job orchestration
│   │   ├── compare/         # Pareto API
│   │   └── affiliate/       # Link tracking
│   ├── migrations/          # SQL migrations
│   └── go.mod
├── workers/                 # Python workers
│   ├── src/
│   │   ├── normalizer/      # HTML parsing
│   │   ├── pareto/          # Pareto calculation
│   │   └── fetcher/         # Anti-bot scraping
│   ├── celery_app.py
│   └── requirements.txt
├── frontend/                # Next.js 15
│   ├── app/                 # App Router pages
│   ├── components/          # React components
│   └── package.json
├── documentation/           # This folder
├── docker-compose.yml       # Local development
└── Makefile                 # Task runner
```

## Local Setup

### 1. Backend (Go)

```bash
cd backend

# Install dependencies
go mod download

# Copy environment file
cp .env.example .env

# Run migrations
go run cmd/migrate/main.go up

# Start server (hot reload with air)
air
# or without air:
go run cmd/server/main.go
```

**Environment Variables** (`.env`):
```bash
DATABASE_URL=postgres://pareto:pareto@localhost:5432/pareto?sslmode=disable
REDIS_URL=redis://localhost:6379/0
ENVIRONMENT=development
```

### 2. Workers (Python)

```bash
cd workers

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or: .\venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Start Celery worker
celery -A celery_app worker --loglevel=info

# Start Celery beat (scheduler)
celery -A celery_app beat --loglevel=info
```

### 3. Frontend (Next.js)

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev

# Open http://localhost:3000
```

### 4. Infrastructure (Docker)

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop all
docker compose down

# Reset data
docker compose down -v
```

**docker-compose.yml** services:
- `postgres` - PostgreSQL 17 + TimescaleDB
- `redis` - Redis 7.4
- `adminer` - Database admin UI (localhost:8080)

## Development Workflow

### Daily Workflow

```bash
# 1. Pull latest changes
git pull origin main

# 2. Start infrastructure
docker compose up -d

# 3. Start services (in separate terminals)
make backend-dev   # Go with hot reload
make workers-dev   # Celery worker
make frontend-dev  # Next.js dev server

# 4. Work on feature/fix
git checkout -b feature/my-feature

# 5. Test changes
make test

# 6. Commit and push
git add .
git commit -m "feat: add my feature"
git push origin feature/my-feature
```

### Makefile Commands

```makefile
# Development
make dev           # Start all services
make backend-dev   # Start Go with hot reload
make workers-dev   # Start Celery worker
make frontend-dev  # Start Next.js

# Testing
make test          # Run all tests
make test-backend  # Go tests only
make test-workers  # Python tests only
make test-frontend # Jest tests only

# Database
make migrate-up    # Run migrations
make migrate-down  # Rollback last migration
make seed          # Seed test data

# Build
make build         # Build all containers
make build-backend # Build Go binary

# Linting
make lint          # Lint all code
make lint-fix      # Auto-fix lint issues
```

## Testing

### Backend (Go)

```bash
# Run all tests
go test ./...

# Run with coverage
go test -cover ./...

# Run specific package
go test ./internal/catalog/...

# Run with verbose output
go test -v ./...
```

### Workers (Python)

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src

# Run specific file
pytest tests/test_normalizer.py

# Run specific test
pytest tests/test_pareto.py::test_simple_pareto
```

### Frontend (Next.js)

```bash
# Run Jest tests
npm test

# Run in watch mode
npm test -- --watch

# Run with coverage
npm test -- --coverage
```

## Code Style

### Go
- Use `gofmt` for formatting
- Follow [Effective Go](https://golang.org/doc/effective_go)
- Run `golangci-lint` before commits

### Python
- Use `black` for formatting
- Use `ruff` for linting
- Follow PEP 8

### TypeScript/JavaScript
- Use Prettier for formatting
- Use ESLint for linting
- Run `npm run lint` before commits

## Git Workflow

### Branch Naming

```
feature/add-pareto-visualization
fix/price-parsing-error
refactor/catalog-service
docs/add-api-documentation
```

### Commit Messages

Follow [Conventional Commits](https://conventionalcommits.org/):

```
feat: add Pareto frontier calculation
fix: correct price parsing for French format
refactor: extract retailer adapters
docs: add API endpoint documentation
test: add unit tests for normalizer
chore: update dependencies
```

### Pull Request Process

1. Create feature branch from `main`
2. Make changes with atomic commits
3. Ensure tests pass locally
4. Push and create PR
5. Wait for CI checks
6. Request review (if team > 1)
7. Merge via squash merge

## Troubleshooting

### Common Issues

**PostgreSQL connection refused**
```bash
# Check if container is running
docker compose ps

# Check logs
docker compose logs postgres

# Restart container
docker compose restart postgres
```

**Redis connection error**
```bash
# Test Redis connection
redis-cli ping
# Should return: PONG
```

**Go module errors**
```bash
# Clear module cache
go clean -modcache
go mod download
```

**Python import errors**
```bash
# Ensure venv is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

**Next.js hydration errors**
```bash
# Clear Next.js cache
rm -rf .next
npm run dev
```

---

## Files in this Section

- [Devcontainer Guide](./devcontainer.md) - Full containerized development (recommended)
- [Local Setup](./local-setup.md) - Detailed setup instructions
- [Environment Variables](./environment.md) - All env vars explained
- [Docker Guide](./docker.md) - Container management
- [Testing Guide](./testing.md) - Testing strategies
- [Debugging Guide](./debugging.md) - Common debugging techniques

**See Also**: [Implementation](../implementation/) for architecture details
