# Devcontainer Development Guide

> **Full containerized development environment with hot reload for Go, Python, and TypeScript**

## Overview

The Pareto Comparator uses VS Code Dev Containers to provide a consistent, fully containerized development environment. All runtimes (Node.js 24, Go 1.24, Python 3.14) run inside a single development container with hot reload support.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    VS Code Devcontainer                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    app (dev container)                    │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────┐ │   │
│  │  │ Node 24 │  │ Go 1.24 │  │Py 3.14  │  │   pnpm      │ │   │
│  │  │ +turbo  │  │  +air   │  │ +celery │  │  +turbo     │ │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────────┘ │   │
│  │                                                          │   │
│  │  Ports: 3000 (web), 8080 (api), 8081 (expo)             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                            │                                     │
│              ┌─────────────┴─────────────┐                      │
│              ▼                           ▼                      │
│  ┌───────────────────┐      ┌───────────────────┐              │
│  │    postgres       │      │      redis        │              │
│  │  TimescaleDB 18   │      │     8.4-alpine    │              │
│  │    :5432          │      │      :6379        │              │
│  └───────────────────┘      └───────────────────┘              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Docker Desktop (macOS/Windows) or Docker Engine + Compose (Linux)
- VS Code with "Dev Containers" extension (`ms-vscode-remote.remote-containers`)
- ~8GB RAM available for containers
- ~10GB disk space for images and caches

## Quick Start

### Option 1: VS Code (Recommended)

1. Open the project in VS Code
2. Press `F1` and select "Dev Containers: Reopen in Container"
3. Wait for the container to build (first time takes ~5-10 minutes)
4. Once ready, run `dev` to start all services

### Option 2: Command Line

```bash
# Build and start services
make devcontainer-up

# Open shell in container
make devcontainer-shell

# Start development
dev
```

## Available Commands

After opening the devcontainer, these aliases are available:

### Development

| Command | Description |
|---------|-------------|
| `dev` | Start all development servers (Turbo) |
| `api` | Start Go API with hot reload (air) |
| `web` | Start Next.js development server |
| `workers` | Start Celery workers |
| `build` | Build all applications |
| `test` | Run all tests |
| `lint` | Run all linters |

### Service-specific

| Command | Description |
|---------|-------------|
| `gotest` | Run Go tests |
| `golint` | Run Go linter |
| `pytest` | Run Python tests |
| `pylint` | Run Python linter |

### Database

| Command | Description |
|---------|-------------|
| `db:psql` | Connect to PostgreSQL |
| `db:redis` | Connect to Redis CLI |
| `db:migrate` | Run database migrations |
| `db:rollback` | Rollback migrations |
| `db:seed` | Seed test data |

### Navigation

| Command | Description |
|---------|-------------|
| `ws` | Go to workspace root |
| `api-dir` | Go to Go API directory |
| `web-dir` | Go to Next.js directory |
| `workers-dir` | Go to Python workers directory |
| `mobile-dir` | Go to Expo mobile directory |

### Claude Code

Claude Code is fully configured in the devcontainer and works on any machine.

**On existing machine (with Claude already set up):**
- Mounts your `~/.claude` directory (settings, plugins, credentials)
- Uses your existing configuration

**On new machine (fresh setup):**
- Claude Code is installed via npm in the container
- `expert-ccsetup` plugin is auto-cloned from [GitHub](https://github.com/CorentinLumineau/ccsetup)
- Just run `claude` to authenticate, then you're ready

| Command | Description |
|---------|-------------|
| `claude` | Start Claude Code CLI |
| `cc` | Claude Code with `-c` flag (continue) |
| `ccc` | Claude Code with `-c` and skip permissions |
| `claudec` | Claude Code with skip permissions |

**First time on new machine:**
```bash
# 1. Authenticate with Anthropic
claude

# 2. Plugin is auto-installed, verify with:
/x:help
```

## Hot Reload

All services support hot reload during development:

### Go API (Air)
- Watches `.go`, `.sql`, `.html`, `.tpl` files
- Automatic rebuild on changes
- ~1 second delay for stability
- Run: `api` or `air` in `apps/api/`

### Python Workers (Watchdog)
- Watches `.py` files in `src/`
- Automatic Celery worker restart
- Run: `workers` or `./scripts/dev.sh worker` in `apps/workers/`

### Next.js (Turbopack)
- Built-in HMR with Turbopack
- Instant updates on save
- Run: `web` or `pnpm dev` in `apps/web/`

## VS Code Tasks

Use `Ctrl+Shift+P` → "Tasks: Run Task" to access predefined tasks:

| Task | Description |
|------|-------------|
| `dev` | Start all services |
| `dev:api` | Start Go API only |
| `dev:web` | Start Next.js only |
| `dev:workers` | Start Celery only |
| `test` | Run all tests |
| `lint` | Run all linters |
| `db:migrate` | Run migrations |

## Debugging

### Go API

1. Start Air: `api`
2. In VS Code, select "Go: Attach to Air" debug configuration
3. Set breakpoints and debug

### Python Workers

1. Use "Python: Celery Worker" debug configuration
2. Set breakpoints in worker code
3. Or attach remotely with "Python: Attach Remote"

### Next.js

1. Use "Next.js: Full-stack" for combined client/server debugging
2. Or "Next.js: Chrome" for client-only debugging

### Full Stack

Use compound configurations:
- "Full Stack: API + Web" - Debug Go and Next.js together
- "Full Stack: All Services" - Debug everything

## Port Mapping

| Port | Service | URL |
|------|---------|-----|
| 3000 | Next.js Web | http://localhost:3000 |
| 8080 | Go API | http://localhost:8080 |
| 8081 | Expo DevTools | http://localhost:8081 |
| 5432 | PostgreSQL | postgresql://pareto:pareto_dev@localhost:5432/pareto_dev |
| 6379 | Redis | redis://localhost:6379 |
| 19000-19002 | Expo Go | Expo mobile connection |

## Environment Variables

The devcontainer sets these environment variables automatically:

```bash
# Database
DATABASE_URL=postgresql://pareto:pareto_dev@postgres:5432/pareto_dev?sslmode=disable

# Redis
REDIS_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/1
CELERY_RESULT_BACKEND=redis://redis:6379/2

# Development
NODE_ENV=development
GO_ENV=development
```

## Performance Tips

### Named Volumes

The devcontainer uses named volumes for caches to improve performance:
- `node_modules` - Node packages (faster than bind mount)
- `go_pkg` - Go modules
- `go_cache` - Go build cache
- `pip_cache` - Python packages
- `pnpm_store` - pnpm package store

### Resource Limits

Recommended Docker Desktop settings:
- Memory: 8GB minimum
- CPUs: 4 cores minimum
- Disk: 64GB+

### File Watching

If file watching is slow:
1. Ensure you're using named volumes for `node_modules`
2. Check Docker Desktop resource limits
3. On Linux, increase inotify limits:
   ```bash
   echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

## Troubleshooting

### Container Build Fails

```bash
# Check Docker resources
docker system info

# Clear Docker cache
docker system prune -a

# Rebuild from scratch
make devcontainer-rebuild
```

### Slow File Sync

```bash
# Verify named volumes are used
docker volume ls | grep pareto

# Check bind mount performance (should use cached)
docker compose -f .devcontainer/docker-compose.yml config
```

### Port Already in Use

```bash
# Find process using port
lsof -i :3000

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

### Go Modules Not Found

```bash
# Inside container
cd /workspace/apps/api
go mod download
```

### Python Packages Missing

```bash
# Inside container
source /workspace/.venv/bin/activate
pip install -e ".[dev]"
```

### PostgreSQL Connection Issues

```bash
# Check PostgreSQL health
docker compose -f .devcontainer/docker-compose.yml ps

# View PostgreSQL logs
docker compose -f .devcontainer/docker-compose.yml logs postgres

# Connect directly
psql $DATABASE_URL
```

### Redis Connection Issues

```bash
# Check Redis health
redis-cli -h redis ping

# View Redis logs
docker compose -f .devcontainer/docker-compose.yml logs redis
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make devcontainer-build` | Build devcontainer image |
| `make devcontainer-up` | Start all services |
| `make devcontainer-down` | Stop all services |
| `make devcontainer-logs` | View logs |
| `make devcontainer-shell` | Open shell |
| `make devcontainer-rebuild` | Rebuild from scratch |

## File Structure

```
.devcontainer/
├── devcontainer.json      # VS Code configuration
├── docker-compose.yml     # Development services
├── Dockerfile             # Multi-runtime dev image
├── post-create.sh         # Setup script
└── init-db.sql            # PostgreSQL initialization

.vscode/
├── settings.json          # Editor settings
├── launch.json            # Debug configurations
├── tasks.json             # Build/run tasks
└── extensions.json        # Recommended extensions

apps/
├── api/
│   └── .air.toml          # Go hot reload config
└── workers/
    └── scripts/
        └── dev.sh         # Python dev script
```

---

**Back to**: [Development README](./README.md)
