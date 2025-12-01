# Docker targets
# Responsible for: standalone Docker container management

.PHONY: docker-up docker-down docker-logs docker-build docker-prod-up docker-prod-down

# Docker compose file paths
DOCKER_COMPOSE_DEV := docker/docker-compose.yml
DOCKER_COMPOSE_PROD := docker/docker-compose.prod.yml

# Start Docker containers (development)
docker-up:
	@echo "Starting Docker containers..."
	docker compose -f $(DOCKER_COMPOSE_DEV) up -d
	@echo "Containers started!"
	@echo "  - PostgreSQL: localhost:5432"
	@echo "  - Redis: localhost:6379"

# Stop Docker containers
docker-down:
	@echo "Stopping Docker containers..."
	docker compose -f $(DOCKER_COMPOSE_DEV) down

# View Docker logs
docker-logs:
	docker compose -f $(DOCKER_COMPOSE_DEV) logs -f

# Build Docker images
docker-build:
	@echo "Building Docker images..."
	docker compose -f $(DOCKER_COMPOSE_DEV) build

# Start production containers
docker-prod-up:
	@echo "Starting production containers..."
	docker compose -f $(DOCKER_COMPOSE_PROD) up -d

# Stop production containers
docker-prod-down:
	docker compose -f $(DOCKER_COMPOSE_PROD) down
