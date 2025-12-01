# Development targets
# Responsible for: installation, dev servers, building, cleaning

.PHONY: install hooks dev build clean start

# Installation
install:
	@echo "Installing dependencies..."
	pnpm install
	cd apps/api && go mod download
	cd apps/workers && pip install -e ".[dev]"
	@echo "Installing pre-commit hooks..."
	pnpm lefthook install || true
	@echo "Dependencies and hooks installed!"

# Install/reinstall pre-commit hooks
hooks:
	@echo "Installing pre-commit hooks..."
	pnpm lefthook install
	@echo "Hooks installed!"

# Development
dev:
	@echo "Starting development servers..."
	pnpm dev

# Build all applications
build:
	@echo "Building all applications..."
	pnpm build

# Clean build artifacts
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

# Quick start for development (requires docker-up from docker.mk)
start: docker-up
	@echo "Waiting for databases to be ready..."
	sleep 5
	@echo "Starting development servers..."
	pnpm dev
