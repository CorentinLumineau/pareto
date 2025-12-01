# Devcontainer targets
# Responsible for: VS Code devcontainer management

.PHONY: devcontainer-build devcontainer-up devcontainer-down devcontainer-logs devcontainer-shell devcontainer-rebuild

# Devcontainer compose file
DEVCONTAINER_COMPOSE := .devcontainer/docker-compose.yml

# Build devcontainer image
devcontainer-build:
	@echo "Building devcontainer image..."
	docker compose -f $(DEVCONTAINER_COMPOSE) build
	@echo "Devcontainer image built!"

# Start devcontainer services
devcontainer-up:
	@echo "Starting devcontainer services..."
	docker compose -f $(DEVCONTAINER_COMPOSE) up -d
	@echo "Devcontainer services started!"
	@echo "  - PostgreSQL: localhost:5432"
	@echo "  - Redis: localhost:6379"
	@echo "  - App container ready for VS Code attach"

# Stop devcontainer services
devcontainer-down:
	@echo "Stopping devcontainer services..."
	docker compose -f $(DEVCONTAINER_COMPOSE) down

# View devcontainer logs
devcontainer-logs:
	docker compose -f $(DEVCONTAINER_COMPOSE) logs -f

# Open shell in devcontainer
devcontainer-shell:
	@echo "Opening shell in devcontainer..."
	docker compose -f $(DEVCONTAINER_COMPOSE) exec app zsh

# Rebuild devcontainer from scratch
devcontainer-rebuild:
	@echo "Rebuilding devcontainer from scratch..."
	docker compose -f $(DEVCONTAINER_COMPOSE) down -v
	docker compose -f $(DEVCONTAINER_COMPOSE) build --no-cache
	docker compose -f $(DEVCONTAINER_COMPOSE) up -d
	@echo "Devcontainer rebuilt and started!"
