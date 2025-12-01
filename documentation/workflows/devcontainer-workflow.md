# Devcontainer Setup - Implementation Workflow

> **Full containerized development environment with hot reload for Go, Python, and TypeScript**

```
Created: 2025-12-01
Status:  Ready for Implementation
Effort:  ~6 hours
```

## Overview

Setup a complete VS Code devcontainer environment where all services run in containers with hot reload support. This enables consistent development across machines and simplifies onboarding.

### Architecture

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

### Prerequisites

- Docker Desktop (or Docker Engine + Compose)
- VS Code with "Dev Containers" extension
- ~8GB RAM available for containers

---

## Task Hierarchy

```
Epic: Devcontainer Setup
├─ Milestone 1: Devcontainer Base (~2h)
│  ├─ Task 1.1: Create devcontainer.json
│  ├─ Task 1.2: Create docker-compose.yml
│  ├─ Task 1.3: Create multi-runtime Dockerfile
│  └─ Task 1.4: Create post-create script
├─ Milestone 2: Hot Reload Configuration (~1.5h)
│  ├─ Task 2.1: Configure Go air hot reload
│  ├─ Task 2.2: Configure Python Celery reload
│  └─ Task 2.3: Verify Turbopack for Next.js
├─ Milestone 3: VS Code Configuration (~1h)
│  ├─ Task 3.1: Create settings.json
│  ├─ Task 3.2: Create launch.json (debugging)
│  ├─ Task 3.3: Create tasks.json
│  └─ Task 3.4: Configure extensions
├─ Milestone 4: Scripts & Documentation (~1h)
│  ├─ Task 4.1: Update Makefile
│  ├─ Task 4.2: Create devcontainer documentation
│  └─ Task 4.3: Update development README
└─ Milestone 5: Verification (~30min)
   ├─ Task 5.1: Test container build
   ├─ Task 5.2: Test all services
   └─ Task 5.3: Test hot reload
```

---

## Milestone 1: Devcontainer Base

### Task 1.1: Create devcontainer.json

**Command:**
```bash
/x:implement "Create .devcontainer/devcontainer.json for VS Code with Docker Compose integration, targeting 'app' service, forwarding ports 3000/8080/8081/5432/6379, mounting workspace to /workspace, configuring VS Code extensions for Go, Python, TypeScript, Tailwind, Docker, ESLint, Prettier, and setting default shell to zsh"
```

**Deliverables:**
- `.devcontainer/devcontainer.json`

**Acceptance Criteria:**
- VS Code recognizes devcontainer configuration
- "Reopen in Container" option available

---

### Task 1.2: Create docker-compose.yml

**Command:**
```bash
/x:implement "Create .devcontainer/docker-compose.yml with services: app (build from .devcontainer/Dockerfile, volumes for workspace and caches, ports 3000/8080/8081/19000-19002), postgres (timescale/timescaledb:2.23.0-pg18, port 5432, healthcheck), redis (redis:8.4-alpine, port 6379, healthcheck). Use named volumes for node_modules, go-pkg, pip-cache for performance"
```

**Deliverables:**
- `.devcontainer/docker-compose.yml`

**Acceptance Criteria:**
- `docker compose up` starts all services
- Named volumes created for caches

---

### Task 1.3: Create Multi-Runtime Dockerfile

**Command:**
```bash
/x:implement "Create .devcontainer/Dockerfile based on mcr.microsoft.com/devcontainers/base:ubuntu-24.04, install Node.js 24 via nvm, Go 1.24 from official tarball, Python 3.14 from deadsnakes PPA, pnpm 9.14 globally, cosmtrek/air for Go hot reload, create non-root 'vscode' user, set GOPATH and PATH, install zsh with oh-my-zsh"
```

**Deliverables:**
- `.devcontainer/Dockerfile`

**Acceptance Criteria:**
- Container builds successfully
- `node --version`, `go version`, `python3 --version` all work
- `air` command available

---

### Task 1.4: Create Post-Create Script

**Command:**
```bash
/x:implement "Create .devcontainer/post-create.sh script that runs after container creation: install pnpm dependencies, download Go modules, create Python venv and install dependencies, setup git safe directory, configure shell aliases for common commands (dev, build, test)"
```

**Deliverables:**
- `.devcontainer/post-create.sh`

**Acceptance Criteria:**
- Script executes without errors
- All dependencies installed after container creation

---

## Milestone 2: Hot Reload Configuration

### Task 2.1: Configure Go Air Hot Reload

**Command:**
```bash
/x:implement "Create apps/api/.air.toml configuration for cosmtrek/air hot reload: watch .go files in cmd/ and internal/, exclude tmp/ and vendor/, build to tmp/main, run with environment variables, configure 1s delay and colorful output"
```

**Deliverables:**
- `apps/api/.air.toml`

**Acceptance Criteria:**
- `air` in apps/api directory starts server with hot reload
- Changes to .go files trigger rebuild

---

### Task 2.2: Configure Python Celery Reload

**Command:**
```bash
/x:implement "Update apps/workers/celeryconfig.py to enable auto-reload in development, create apps/workers/scripts/dev.sh that starts Celery with --reload flag and watchdog for file changes"
```

**Deliverables:**
- Updated `apps/workers/celeryconfig.py`
- `apps/workers/scripts/dev.sh`

**Acceptance Criteria:**
- Celery worker restarts on Python file changes
- Development mode clearly indicated in logs

---

### Task 2.3: Verify Turbopack Configuration

**Command:**
```bash
/x:implement "Verify apps/web/next.config.ts has Turbopack enabled for development, ensure package.json dev script uses --turbopack flag, test hot module replacement works"
```

**Deliverables:**
- Verified `apps/web/next.config.ts`
- Verified `apps/web/package.json`

**Acceptance Criteria:**
- Next.js dev server uses Turbopack
- Fast refresh works on component changes

---

## Milestone 3: VS Code Configuration

### Task 3.1: Create settings.json

**Command:**
```bash
/x:implement "Create .vscode/settings.json with configurations for: Go (gopls, format on save, test flags), Python (pylance, black formatter, pytest), TypeScript (strict mode, organize imports), Tailwind CSS (class sorting), ESLint (flat config), editor settings (format on save, trim whitespace), file associations"
```

**Deliverables:**
- `.vscode/settings.json`

**Acceptance Criteria:**
- Language servers work for Go, Python, TypeScript
- Format on save works for all languages

---

### Task 3.2: Create launch.json

**Command:**
```bash
/x:implement "Create .vscode/launch.json with debug configurations for: Go API (dlv attach to air process), Python Workers (debugpy attach), Next.js (Chrome DevTools), compound configuration to debug all services together"
```

**Deliverables:**
- `.vscode/launch.json`

**Acceptance Criteria:**
- F5 launches debugger for selected configuration
- Breakpoints work in Go, Python, and TypeScript

---

### Task 3.3: Create tasks.json

**Command:**
```bash
/x:implement "Create .vscode/tasks.json with tasks for: start all services (pnpm dev), start individual services (api, web, workers), run tests, run lints, docker compose up/down, database migrations"
```

**Deliverables:**
- `.vscode/tasks.json`

**Acceptance Criteria:**
- Tasks appear in VS Code command palette
- Keyboard shortcuts work for common tasks

---

### Task 3.4: Configure Extensions

**Command:**
```bash
/x:implement "Create .vscode/extensions.json with recommended extensions: golang.go, ms-python.python, ms-python.vscode-pylance, dbaeumer.vscode-eslint, esbenp.prettier-vscode, bradlc.vscode-tailwindcss, ms-azuretools.vscode-docker, prisma.prisma, streetsidesoftware.code-spell-checker"
```

**Deliverables:**
- `.vscode/extensions.json`

**Acceptance Criteria:**
- VS Code prompts to install recommended extensions
- All extensions work in devcontainer

---

## Milestone 4: Scripts & Documentation

### Task 4.1: Update Makefile

**Command:**
```bash
/x:implement "Update Makefile to add devcontainer targets: devcontainer-build (build the dev image), devcontainer-up (start with docker compose), devcontainer-down, devcontainer-logs, devcontainer-shell (exec into running container)"
```

**Deliverables:**
- Updated `Makefile`

**Acceptance Criteria:**
- `make devcontainer-up` starts development environment
- All devcontainer commands documented in `make help`

---

### Task 4.2: Create Devcontainer Documentation

**Command:**
```bash
/x:implement "Create documentation/development/devcontainer.md with: overview of devcontainer setup, prerequisites, quick start guide, architecture diagram, troubleshooting section, performance tips (named volumes, resource limits), FAQ"
```

**Deliverables:**
- `documentation/development/devcontainer.md`

**Acceptance Criteria:**
- New developers can setup environment following guide
- Common issues addressed in troubleshooting

---

### Task 4.3: Update Development README

**Command:**
```bash
/x:implement "Update documentation/development/README.md to add devcontainer as primary development method, link to devcontainer.md, update quick start section with 'Reopen in Container' instructions"
```

**Deliverables:**
- Updated `documentation/development/README.md`

**Acceptance Criteria:**
- README clearly describes devcontainer workflow
- Both local and container development options documented

---

## Milestone 5: Verification

### Task 5.1: Test Container Build

**Commands:**
```bash
# Build devcontainer image
cd .devcontainer && docker compose build

# Verify image size is reasonable (<5GB)
docker images | grep devcontainer
```

**Acceptance Criteria:**
- Image builds without errors
- Build time < 10 minutes
- Image size < 5GB

---

### Task 5.2: Test All Services

**Commands:**
```bash
# Start all services
docker compose -f .devcontainer/docker-compose.yml up -d

# Check services are healthy
docker compose -f .devcontainer/docker-compose.yml ps

# Test endpoints
curl http://localhost:8080/health  # Go API
curl http://localhost:3000/api/health  # Next.js
```

**Acceptance Criteria:**
- All containers start and stay healthy
- API and web respond to health checks
- Database and Redis accessible

---

### Task 5.3: Test Hot Reload

**Tests:**
1. **Go**: Edit `apps/api/cmd/api/main.go`, verify server restarts
2. **Python**: Edit `apps/workers/src/pareto/calculator.py`, verify Celery reloads
3. **Next.js**: Edit `apps/web/src/app/page.tsx`, verify browser updates

**Acceptance Criteria:**
- All three languages hot reload within 5 seconds
- No manual restart required
- Terminal shows reload messages

---

## Implementation Order

```bash
# Day 1 (~4 hours)
/x:implement "Task 1.1: Create devcontainer.json..."
/x:implement "Task 1.2: Create docker-compose.yml..."
/x:implement "Task 1.3: Create multi-runtime Dockerfile..."
/x:implement "Task 1.4: Create post-create script..."
/x:implement "Task 2.1: Configure Go air..."
/x:implement "Task 2.2: Configure Python reload..."

# Day 1 continued (~2 hours)
/x:implement "Task 3.1: Create settings.json..."
/x:implement "Task 3.2: Create launch.json..."
/x:implement "Task 3.3: Create tasks.json..."
/x:implement "Task 3.4: Configure extensions..."
/x:implement "Task 4.1: Update Makefile..."
/x:implement "Task 4.2: Create devcontainer docs..."
/x:implement "Task 4.3: Update development README..."

# Verification
# Open VS Code → "Reopen in Container" → Test all services
```

---

## Final Structure

```
pareto/
├── .devcontainer/
│   ├── devcontainer.json       # VS Code configuration
│   ├── docker-compose.yml      # Development services
│   ├── Dockerfile              # Multi-runtime dev image
│   ├── post-create.sh          # Setup script
│   └── .env.example            # Environment template
├── .vscode/
│   ├── settings.json           # Editor settings
│   ├── launch.json             # Debug configurations
│   ├── tasks.json              # Build/run tasks
│   └── extensions.json         # Recommended extensions
├── apps/
│   ├── api/
│   │   └── .air.toml           # Go hot reload config
│   └── workers/
│       └── scripts/
│           └── dev.sh          # Python dev script
└── documentation/
    └── development/
        ├── README.md           # Updated with devcontainer
        └── devcontainer.md     # Detailed devcontainer guide
```

---

## Success Criteria Checklist

After completing all tasks:

- [ ] VS Code "Reopen in Container" works
- [ ] All three runtimes available (Node, Go, Python)
- [ ] `pnpm dev` starts all services with hot reload
- [ ] Go changes trigger automatic rebuild
- [ ] Python changes trigger Celery reload
- [ ] Next.js fast refresh works
- [ ] Database accessible from container
- [ ] Redis accessible from container
- [ ] VS Code debugging works for all languages
- [ ] Documentation updated

---

## Troubleshooting Guide

| Issue | Solution |
|-------|----------|
| Container build fails | Check Docker resources (8GB+ RAM) |
| Slow file sync | Ensure named volumes for node_modules |
| Port already in use | Stop local services or change ports |
| Go modules not found | Run `go mod download` in container |
| Python packages missing | Activate venv: `source .venv/bin/activate` |

---

**Next Steps After Completion:**
1. Test the devcontainer setup
2. Continue with Scraper Initiative
3. All development happens inside containers

---

**Back to**: [Foundation Workflow](./foundation-workflow.md)
**Related**: [Development README](../development/README.md)
