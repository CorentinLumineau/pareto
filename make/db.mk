# Database targets (Atlas migrations)
# Responsible for: schema management, migrations, database operations

.PHONY: db-diff db-apply db-status db-lint db-hash db-validate db-init db-reset migrate-up migrate-down seed

# Atlas configuration
ATLAS_ENV := local
API_DIR := apps/api

# ============================================
# Atlas Database Migrations (Prisma-like DX)
# ============================================

# Generate a new migration from schema changes
# Usage: make db-diff name=add_users_table
db-diff:
ifndef name
	$(error name is required. Usage: make db-diff name=migration_name)
endif
	@echo "Generating migration '$(name)' from schema changes..."
	cd $(API_DIR) && atlas migrate diff $(name) \
		--env $(ATLAS_ENV) \
		--to file://schema.sql
	@echo "Migration generated! Review it in $(API_DIR)/migrations/"

# Apply all pending migrations
db-apply:
	@echo "Applying pending migrations..."
	cd $(API_DIR) && atlas migrate apply \
		--env $(ATLAS_ENV)
	@echo "Migrations applied successfully!"

# Show migration status
db-status:
	@echo "Migration status:"
	cd $(API_DIR) && atlas migrate status \
		--env $(ATLAS_ENV)

# Lint migrations for potential issues
db-lint:
	@echo "Linting migrations..."
	cd $(API_DIR) && atlas migrate lint \
		--env $(ATLAS_ENV) \
		--latest 1
	@echo "Lint complete!"

# Update the atlas.sum hash file
db-hash:
	@echo "Updating migration hash..."
	cd $(API_DIR) && atlas migrate hash \
		--env $(ATLAS_ENV)
	@echo "Hash updated!"

# Validate schema.sql syntax
db-validate:
	@echo "Validating schema syntax..."
	cd $(API_DIR) && atlas schema inspect \
		--env $(ATLAS_ENV) \
		--url "file://schema.sql" \
		--format '{{ sql . }}'
	@echo "Schema is valid!"

# Create initial migration (first time setup)
db-init:
	@echo "Creating initial migration..."
	cd $(API_DIR) && atlas migrate diff init \
		--env $(ATLAS_ENV) \
		--to file://schema.sql
	@echo "Initial migration created!"

# Reset database (DANGEROUS - development only)
db-reset:
	@echo "WARNING: This will destroy all data!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	cd $(API_DIR) && atlas schema clean \
		--env $(ATLAS_ENV) \
		--auto-approve
	cd $(API_DIR) && atlas migrate apply \
		--env $(ATLAS_ENV)
	@echo "Database reset complete!"

# ============================================
# Legacy Migration Commands
# ============================================

# Run database migrations (legacy Go-based)
migrate-up:
	@echo "Running migrations..."
	cd $(API_DIR) && go run ./cmd/migrate up

# Rollback migrations (legacy Go-based)
migrate-down:
	@echo "Rolling back migrations..."
	cd $(API_DIR) && go run ./cmd/migrate down

# Seed database with test data
seed:
	@echo "Seeding database..."
	cd $(API_DIR) && go run ./cmd/seed
