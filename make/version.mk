# Versioning commands for Pareto Comparator
# Uses Changesets for version management

.PHONY: changeset version release version-check version-status

# Create a new changeset (run after making changes)
changeset:
	pnpm changeset

# Apply changesets and bump versions (usually done by CI)
version:
	pnpm changeset version

# Publish packages and create release (usually done by CI)
release:
	pnpm changeset publish

# Check if there are any changesets pending
version-check:
	@echo "Checking for pending changesets..."
	@if ls .changeset/*.md 1> /dev/null 2>&1; then \
		echo "Pending changesets found:"; \
		ls -la .changeset/*.md | grep -v README.md || true; \
	else \
		echo "No pending changesets."; \
	fi

# Show current version across all packages
version-status:
	@echo "Current versions:"
	@echo "  Root:            $$(node -p "require('./package.json').version")"
	@echo "  @pareto/types:   $$(node -p "require('./packages/types/package.json').version")"
	@echo "  @pareto/utils:   $$(node -p "require('./packages/utils/package.json').version")"
	@echo "  @pareto/api-client: $$(node -p "require('./packages/api-client/package.json').version")"
	@echo "  @pareto/web:     $$(node -p "require('./apps/web/package.json').version")"
	@echo "  @pareto/mobile:  $$(node -p "require('./apps/mobile/package.json').version")"
	@echo "  @pareto/api:     $$(node -p "require('./apps/api/package.json').version")"
	@echo "  @pareto/workers: $$(node -p "require('./apps/workers/package.json').version")"
