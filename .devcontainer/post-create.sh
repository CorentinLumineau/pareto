#!/bin/bash
# Post-create script for Pareto Comparator devcontainer
# This script runs after the container is created

set -e

echo "=========================================="
echo "  Pareto Comparator - Post-Create Setup  "
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# Environment Variables for SSL/Certificates
# ============================================
echo -e "\n${BLUE}[0/7] Setting up environment variables...${NC}"
cat >> /home/vscode/.zshenv << 'ENVEOF'
# SSL/TLS certificates
export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENVEOF
echo -e "${GREEN}✓ Environment variables configured${NC}"

# ============================================
# Git Configuration
# ============================================
echo -e "\n${BLUE}[1/7] Configuring Git...${NC}"
git config --global --add safe.directory /workspace
echo -e "${GREEN}✓ Git configured${NC}"

# ============================================
# Node.js / pnpm Dependencies
# ============================================
echo -e "\n${BLUE}[2/7] Installing Node.js dependencies...${NC}"
cd /workspace
pnpm install
echo -e "${GREEN}✓ Node.js dependencies installed${NC}"

# ============================================
# Go Dependencies
# ============================================
echo -e "\n${BLUE}[3/7] Downloading Go modules...${NC}"
if [ -d "/workspace/apps/api" ]; then
    cd /workspace/apps/api
    go mod download
    echo -e "${GREEN}✓ Go modules downloaded${NC}"
else
    echo -e "${YELLOW}⚠ apps/api not found, skipping Go setup${NC}"
fi

# ============================================
# Python Virtual Environment
# ============================================
echo -e "\n${BLUE}[4/7] Setting up Python virtual environment...${NC}"
cd /workspace
if [ ! -d ".venv" ]; then
    python -m venv .venv
fi
source .venv/bin/activate

if [ -d "/workspace/apps/workers" ]; then
    cd /workspace/apps/workers
    pip install -e ".[dev]"
    echo -e "${GREEN}✓ Python environment configured${NC}"
else
    echo -e "${YELLOW}⚠ apps/workers not found, skipping Python setup${NC}"
fi

# ============================================
# Shell Aliases
# ============================================
echo -e "\n${BLUE}[5/7] Configuring shell aliases...${NC}"

ALIASES_FILE="/home/vscode/.zshrc"
if [ -f "$ALIASES_FILE" ]; then
    cat >> "$ALIASES_FILE" << 'EOF'

# ============================================
# Pareto Comparator Aliases
# ============================================

# Development commands
alias dev="cd /workspace && pnpm dev"
alias build="cd /workspace && pnpm build"
alias test="cd /workspace && pnpm test"
alias lint="cd /workspace && pnpm lint"
alias typecheck="cd /workspace && pnpm typecheck"

# Service-specific commands
alias api="cd /workspace/apps/api && air"
alias web="cd /workspace/apps/web && pnpm dev"
alias workers="cd /workspace/apps/workers && source /workspace/.venv/bin/activate && celery -A src.main worker --loglevel=info"

# Database commands
alias db:migrate="cd /workspace/apps/api && go run ./cmd/migrate up"
alias db:rollback="cd /workspace/apps/api && go run ./cmd/migrate down"
alias db:seed="cd /workspace/apps/api && go run ./cmd/seed"
alias db:psql="psql \$DATABASE_URL"
alias db:redis="redis-cli -u \$REDIS_URL"

# Go commands
alias gotest="cd /workspace/apps/api && go test -v ./..."
alias golint="cd /workspace/apps/api && golangci-lint run"

# Python commands
alias pytest="cd /workspace/apps/workers && source /workspace/.venv/bin/activate && pytest"
alias pylint="cd /workspace/apps/workers && source /workspace/.venv/bin/activate && ruff check src/"

# Quick navigation
alias ws="cd /workspace"
alias api-dir="cd /workspace/apps/api"
alias web-dir="cd /workspace/apps/web"
alias workers-dir="cd /workspace/apps/workers"
alias mobile-dir="cd /workspace/apps/mobile"

# Utility
alias ports="netstat -tlnp 2>/dev/null || ss -tlnp"
alias logs:api="tail -f /workspace/apps/api/tmp/main.log"

# Claude Code - use local installation if available, otherwise use npm global
if [ -x "/home/vscode/.claude/local/claude" ]; then
    CLAUDE_BIN="/home/vscode/.claude/local/claude"
else
    CLAUDE_BIN="claude"
fi
alias claude="\$CLAUDE_BIN"
alias cc="\$CLAUDE_BIN -c"
alias ccc="\$CLAUDE_BIN -c --dangerously-skip-permissions"
alias claudec="\$CLAUDE_BIN --dangerously-skip-permissions"
EOF
    echo -e "${GREEN}✓ Shell aliases configured${NC}"
else
    echo -e "${YELLOW}⚠ .zshrc not found, skipping aliases${NC}"
fi

# ============================================
# Wait for Services
# ============================================
echo -e "\n${BLUE}[6/7] Verifying services...${NC}"

# Wait for PostgreSQL
echo -n "  Waiting for PostgreSQL..."
for i in {1..30}; do
    if pg_isready -h postgres -U pareto -d pareto_dev > /dev/null 2>&1; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    sleep 1
done

# Wait for Redis
echo -n "  Waiting for Redis..."
for i in {1..30}; do
    if redis-cli -h redis ping > /dev/null 2>&1; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    sleep 1
done

# ============================================
# Claude Code Verification & Setup
# ============================================
echo -e "\n${BLUE}[7/7] Verifying Claude Code setup...${NC}"

# Check if Claude Code is available (local or npm)
if [ -x "/home/vscode/.claude/local/claude" ]; then
    echo -e "  ${GREEN}✓${NC} Claude Code binary found (local installation)"
    CLAUDE_CMD="/home/vscode/.claude/local/claude"
elif command -v claude &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Claude Code available (npm global)"
    CLAUDE_CMD="claude"
else
    echo -e "  ${YELLOW}⚠${NC} Claude Code not found - installing via npm..."
    npm install -g @anthropic-ai/claude-code
    CLAUDE_CMD="claude"
fi

# Check settings
if [ -f "/home/vscode/.claude/settings.json" ]; then
    echo -e "  ${GREEN}✓${NC} Claude settings found (from host)"
    # Show enabled plugins
    PLUGINS=$(jq -r '.enabledPlugins | keys[]' /home/vscode/.claude/settings.json 2>/dev/null || echo "")
    if [ -n "$PLUGINS" ]; then
        echo -e "  ${GREEN}✓${NC} Plugins enabled: $PLUGINS"
    fi
else
    echo -e "  ${YELLOW}!${NC} No existing Claude settings - will be created on first run"
fi

# Check credentials
if [ -f "/home/vscode/.claude/.credentials.json" ]; then
    echo -e "  ${GREEN}✓${NC} Claude credentials found"
else
    echo -e "  ${YELLOW}!${NC} No credentials - run 'claude' to authenticate"
fi

# Install expert-ccsetup plugin if not present
PLUGIN_DIR="/home/vscode/.claude/plugins/marketplaces/expert/ccsetup-plugin"
if [ ! -d "$PLUGIN_DIR" ]; then
    echo -e "  ${BLUE}→${NC} Installing expert-ccsetup plugin from GitHub..."
    mkdir -p "/home/vscode/.claude/plugins/marketplaces/expert"
    if git clone https://github.com/CorentinLumineau/ccsetup.git "$PLUGIN_DIR" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Plugin expert-ccsetup cloned from GitHub"

        # Create/update installed_plugins.json
        PLUGINS_JSON="/home/vscode/.claude/plugins/installed_plugins.json"
        if [ ! -f "$PLUGINS_JSON" ]; then
            cat > "$PLUGINS_JSON" << 'PLUGINJSON'
{
  "version": 1,
  "plugins": {
    "expert-ccsetup@expert": {
      "version": "3.0.0",
      "installedAt": "$(date -Iseconds)",
      "lastUpdated": "$(date -Iseconds)",
      "installPath": "/home/vscode/.claude/plugins/marketplaces/expert/ccsetup-plugin",
      "isLocal": true
    }
  }
}
PLUGINJSON
        fi

        # Enable plugin in settings if settings exist
        SETTINGS_FILE="/home/vscode/.claude/settings.json"
        if [ -f "$SETTINGS_FILE" ]; then
            # Add plugin to enabledPlugins if not already there
            jq '.enabledPlugins["expert-ccsetup@expert"] = true' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
        else
            # Create minimal settings with plugin enabled
            cat > "$SETTINGS_FILE" << 'SETTINGSJSON'
{
  "enabledPlugins": {
    "expert-ccsetup@expert": true
  }
}
SETTINGSJSON
        fi
        echo -e "  ${GREEN}✓${NC} Plugin enabled in settings"
    else
        echo -e "  ${YELLOW}!${NC} Could not clone plugin - check network/authentication"
    fi
else
    echo -e "  ${GREEN}✓${NC} Plugin expert-ccsetup already installed"
    # Update plugin from git
    cd "$PLUGIN_DIR" && git pull --quiet 2>/dev/null && cd - > /dev/null
    echo -e "  ${GREEN}✓${NC} Plugin updated from GitHub"
fi

# ============================================
# Final Summary
# ============================================
echo -e "\n${GREEN}=========================================="
echo "  Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Available commands:"
echo "  dev          - Start all development servers"
echo "  api          - Start Go API with hot reload (air)"
echo "  web          - Start Next.js development server"
echo "  workers      - Start Celery workers"
echo ""
echo "Database:"
echo "  db:psql      - Connect to PostgreSQL"
echo "  db:redis     - Connect to Redis"
echo "  db:migrate   - Run migrations"
echo ""
echo "Testing:"
echo "  test         - Run all tests"
echo "  gotest       - Run Go tests"
echo "  pytest       - Run Python tests"
echo ""
echo "Claude Code:"
echo "  claude       - Start Claude Code CLI"
echo "  cc           - Claude Code with -c flag (continue)"
echo "  ccc          - Claude Code continue + skip permissions"
echo "  claudec      - Claude Code with skip permissions"
echo ""
echo -e "${YELLOW}Tip: Run 'source ~/.zshrc' to load aliases in current terminal${NC}"
echo ""
echo -e "${BLUE}First time setup on new machine:${NC}"
echo "  1. Run 'claude' to authenticate with Anthropic"
echo "  2. The expert-ccsetup plugin is auto-installed from GitHub"
echo "  3. Use /x:help to see available commands"
echo ""
