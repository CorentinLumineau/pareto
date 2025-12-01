# Quality assurance targets
# Responsible for: linting, testing, type checking, verification

.PHONY: lint test typecheck verify

# Run all linters
lint:
	@echo "Running linters..."
	pnpm lint
	cd apps/api && golangci-lint run || true
	cd apps/workers && ruff check src/ || true

# Run all tests
test:
	@echo "Running tests..."
	pnpm test
	cd apps/api && go test ./...
	cd apps/workers && pytest

# Run type checking
typecheck:
	@echo "Running type checking..."
	pnpm typecheck
	cd apps/workers && mypy src/

# Quality verification (all checks in parallel)
verify:
	@./scripts/verify/main.sh
