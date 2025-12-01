#!/bin/bash
# Development script for Python Celery workers with auto-reload
# Usage: ./scripts/dev.sh [worker|beat|flower]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
COMPONENT=${1:-worker}
LOGLEVEL=${CELERY_LOGLEVEL:-info}
CONCURRENCY=${CELERY_CONCURRENCY:-2}

# Change to workers directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKERS_DIR="$(dirname "$SCRIPT_DIR")"
cd "$WORKERS_DIR"

# Activate virtual environment if exists
if [ -f "/workspace/.venv/bin/activate" ]; then
    source /workspace/.venv/bin/activate
elif [ -f "../../.venv/bin/activate" ]; then
    source ../../.venv/bin/activate
fi

# Ensure dependencies are installed
if ! python -c "import celery" 2>/dev/null; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install -e ".[dev]"
fi

# Function to start worker with auto-reload
start_worker() {
    echo -e "${BLUE}Starting Celery worker with auto-reload...${NC}"
    echo -e "${GREEN}  Loglevel: $LOGLEVEL${NC}"
    echo -e "${GREEN}  Concurrency: $CONCURRENCY${NC}"
    echo ""

    # Using watchfiles for file watching (more reliable than celery's built-in)
    # --reload enables auto-reload on Python file changes
    celery -A src.main worker \
        --loglevel="$LOGLEVEL" \
        --concurrency="$CONCURRENCY" \
        --pool=prefork \
        --events \
        --autoscale=4,2
}

# Function to start worker with watchdog (alternative approach)
start_worker_watchdog() {
    echo -e "${BLUE}Starting Celery worker with watchdog...${NC}"

    # Install watchdog if not present
    pip install watchdog[watchmedo] --quiet

    watchmedo auto-restart \
        --directory=./src \
        --pattern="*.py" \
        --recursive \
        -- celery -A src.main worker \
            --loglevel="$LOGLEVEL" \
            --concurrency="$CONCURRENCY" \
            --pool=prefork
}

# Function to start beat scheduler
start_beat() {
    echo -e "${BLUE}Starting Celery beat scheduler...${NC}"

    celery -A src.main beat \
        --loglevel="$LOGLEVEL" \
        --scheduler=celery.beat:PersistentScheduler
}

# Function to start flower monitoring
start_flower() {
    echo -e "${BLUE}Starting Flower monitoring...${NC}"

    # Install flower if not present
    pip install flower --quiet

    celery -A src.main flower \
        --port=5555 \
        --basic-auth="${FLOWER_USER:-admin}:${FLOWER_PASSWORD:-admin}"
}

# Function to start all components
start_all() {
    echo -e "${BLUE}Starting all Celery components...${NC}"
    echo -e "${YELLOW}Note: Run each in separate terminal for development${NC}"
    echo ""
    echo "  Terminal 1: ./scripts/dev.sh worker"
    echo "  Terminal 2: ./scripts/dev.sh beat"
    echo "  Terminal 3: ./scripts/dev.sh flower"
    echo ""

    # For development, start just the worker with watchdog
    start_worker_watchdog
}

# Main
case "$COMPONENT" in
    worker)
        start_worker_watchdog
        ;;
    worker-native)
        start_worker
        ;;
    beat)
        start_beat
        ;;
    flower)
        start_flower
        ;;
    all)
        start_all
        ;;
    *)
        echo -e "${RED}Unknown component: $COMPONENT${NC}"
        echo ""
        echo "Usage: $0 [worker|worker-native|beat|flower|all]"
        echo ""
        echo "Components:"
        echo "  worker        - Start worker with watchdog auto-reload (recommended)"
        echo "  worker-native - Start worker with celery's built-in reload"
        echo "  beat          - Start beat scheduler"
        echo "  flower        - Start Flower web UI"
        echo "  all           - Start all (defaults to worker with watchdog)"
        exit 1
        ;;
esac
