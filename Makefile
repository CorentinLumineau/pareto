.PHONY: help install dev build lint test typecheck clean docker-up docker-down docker-logs docker-build migrate-up migrate-down seed devcontainer-build devcontainer-up devcontainer-down devcontainer-logs devcontainer-shell devcontainer-rebuild

# Default target
help:
	@echo "Pareto Comparator - Available commands:"
	@echo ""
	@echo "  Development:"
	@echo "    make install      Install all dependencies"
	@echo "    make dev          Start development servers"
	@echo "    make build        Build all applications"
	@echo "    make lint         Run linters"
	@echo "    make test         Run tests"
	@echo "    make typecheck    Run type checking"
	@echo "    make clean        Clean build artifacts"
	@echo ""
	@echo "  Devcontainer (recommended):"
	@echo "    make devcontainer-build   Build the devcontainer image"
	@echo "    make devcontainer-up      Start devcontainer services"
	@echo "    make devcontainer-down    Stop devcontainer services"
	@echo "    make devcontainer-logs    View devcontainer logs"
	@echo "    make devcontainer-shell   Open shell in devcontainer"
	@echo "    make devcontainer-rebuild Rebuild devcontainer from scratch"
	@echo ""
	@echo "  Docker (standalone):"
	@echo "    make docker-up    Start Docker containers"
	@echo "    make docker-down  Stop Docker containers"
	@echo "    make docker-logs  View Docker logs"
	@echo "    make docker-build Build Docker images"
	@echo ""
	@echo "  Database:"
	@echo "    make migrate-up   Run database migrations"
	@echo "    make migrate-down Rollback migrations"
	@echo "    make seed         Seed database with test data"

# Installation
install:
	@echo "Installing dependencies..."
	pnpm install
	cd apps/api && go mod download
	cd apps/workers && pip install -e ".[dev]"
	@echo "Dependencies installed!"

# Development
dev:
	@echo "Starting development servers..."
	pnpm dev

build:
	@echo "Building all applications..."
	pnpm build

lint:
	@echo "Running linters..."
	pnpm lint
	cd apps/api && golangci-lint run || true
	cd apps/workers && ruff check src/ || true

test:
	@echo "Running tests..."
	pnpm test
	cd apps/api && go test ./...
	cd apps/workers && pytest

typecheck:
	@echo "Running type checking..."
	pnpm typecheck
	cd apps/workers && mypy src/

clean:
	@echo "Cleaning build artifacts..."
	pnpm clean
	rm -rf node_modules .turbo
	rm -rf apps/api/bin
	rm -rf apps/web/.next
	rm -rf apps/mobile/.expo
	rm -rf apps/workers/__pycache__ apps/workers/.pytest_cache
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".turbo" -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete!"

# Docker
docker-up:
	@echo "Starting Docker containers..."
	docker compose -f docker/docker-compose.yml up -d
	@echo "Containers started!"
	@echo "  - PostgreSQL: localhost:5432"
	@echo "  - Redis: localhost:6379"

docker-down:
	@echo "Stopping Docker containers..."
	docker compose -f docker/docker-compose.yml down

docker-logs:
	docker compose -f docker/docker-compose.yml logs -f

docker-build:
	@echo "Building Docker images..."
	docker compose -f docker/docker-compose.yml build

docker-prod-up:
	@echo "Starting production containers..."
	docker compose -f docker/docker-compose.prod.yml up -d

docker-prod-down:
	docker compose -f docker/docker-compose.prod.yml down

# Database
migrate-up:
	@echo "Running migrations..."
	cd apps/api && go run ./cmd/migrate up

migrate-down:
	@echo "Rolling back migrations..."
	cd apps/api && go run ./cmd/migrate down

seed:
	@echo "Seeding database..."
	cd apps/api && go run ./cmd/seed

# Quick start for development
start: docker-up
	@echo "Waiting for databases to be ready..."
	sleep 5
	@echo "Starting development servers..."
	pnpm dev

# Devcontainer commands
devcontainer-build:
	@echo "Building devcontainer image..."
	docker compose -f .devcontainer/docker-compose.yml build
	@echo "Devcontainer image built!"

devcontainer-up:
	@echo "Starting devcontainer services..."
	docker compose -f .devcontainer/docker-compose.yml up -d
	@echo "Devcontainer services started!"
	@echo "  - PostgreSQL: localhost:5432"
	@echo "  - Redis: localhost:6379"
	@echo "  - App container ready for VS Code attach"

devcontainer-down:
	@echo "Stopping devcontainer services..."
	docker compose -f .devcontainer/docker-compose.yml down

devcontainer-logs:
	docker compose -f .devcontainer/docker-compose.yml logs -f

devcontainer-shell:
	@echo "Opening shell in devcontainer..."
	docker compose -f .devcontainer/docker-compose.yml exec app zsh

devcontainer-rebuild:
	@echo "Rebuilding devcontainer from scratch..."
	docker compose -f .devcontainer/docker-compose.yml down -v
	docker compose -f .devcontainer/docker-compose.yml build --no-cache
	docker compose -f .devcontainer/docker-compose.yml up -d
	@echo "Devcontainer rebuilt and started!"
