# Pareto Comparator - Main Makefile
# Modular structure following SOLID principles (Single Responsibility)
#
# Structure:
#   make/dev.mk         - Development: install, dev, build, clean
#   make/quality.mk     - Quality: lint, test, typecheck, verify
#   make/docker.mk      - Docker: container management
#   make/devcontainer.mk - Devcontainer: VS Code integration
#   make/db.mk          - Database: Atlas migrations, schema management
#   make/version.mk     - Versioning: changesets, releases

# Include all modular makefiles
include make/dev.mk
include make/quality.mk
include make/docker.mk
include make/devcontainer.mk
include make/db.mk
include make/version.mk

# Default target
.DEFAULT_GOAL := help

.PHONY: help

help:
	@echo "Pareto Comparator - Available commands:"
	@echo ""
	@echo "  Development (make/dev.mk):"
	@echo "    make install      Install all dependencies and hooks"
	@echo "    make hooks        Install/reinstall pre-commit hooks"
	@echo "    make dev          Start development servers"
	@echo "    make build        Build all applications"
	@echo "    make clean        Clean build artifacts"
	@echo "    make start        Start Docker + dev servers"
	@echo ""
	@echo "  Quality (make/quality.mk):"
	@echo "    make lint         Run linters"
	@echo "    make test         Run tests"
	@echo "    make typecheck    Run type checking"
	@echo "    make verify       Run ALL quality checks (lint, type, test, coverage)"
	@echo ""
	@echo "  Devcontainer (make/devcontainer.mk) - recommended:"
	@echo "    make devcontainer-build   Build the devcontainer image"
	@echo "    make devcontainer-up      Start devcontainer services"
	@echo "    make devcontainer-down    Stop devcontainer services"
	@echo "    make devcontainer-logs    View devcontainer logs"
	@echo "    make devcontainer-shell   Open shell in devcontainer"
	@echo "    make devcontainer-rebuild Rebuild devcontainer from scratch"
	@echo ""
	@echo "  Docker (make/docker.mk) - standalone:"
	@echo "    make docker-up    Start Docker containers"
	@echo "    make docker-down  Stop Docker containers"
	@echo "    make docker-logs  View Docker logs"
	@echo "    make docker-build Build Docker images"
	@echo ""
	@echo "  Database (make/db.mk) - Atlas migrations:"
	@echo "    make db-diff name=<name>  Generate migration from schema changes"
	@echo "    make db-apply             Apply pending migrations"
	@echo "    make db-status            Show migration status"
	@echo "    make db-lint              Lint migrations for issues"
	@echo "    make db-hash              Update atlas.sum hash file"
	@echo "    make db-validate          Validate schema.sql syntax"
	@echo "    make db-init              Create initial migration"
	@echo "    make db-reset             Reset database (DANGEROUS!)"
	@echo ""
	@echo "  Database (make/db.mk) - Legacy:"
	@echo "    make migrate-up   Run database migrations (legacy)"
	@echo "    make migrate-down Rollback migrations (legacy)"
	@echo "    make seed         Seed database with test data"
	@echo ""
	@echo "  Versioning (make/version.mk):"
	@echo "    make changeset       Create a changeset for your changes"
	@echo "    make version         Apply changesets and bump versions"
	@echo "    make version-status  Show current versions across packages"
	@echo "    make version-check   Check for pending changesets"
