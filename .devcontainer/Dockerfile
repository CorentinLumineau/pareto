# Pareto Comparator Development Container
# Multi-runtime: Node.js 24 + Go 1.24 + Python 3.14

FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG NODE_VERSION=24
ARG GO_VERSION=1.24.4
ARG PYTHON_VERSION=3.14
ARG PNPM_VERSION=9.14.2

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    libpq-dev \
    libffi-dev \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    liblzma-dev \
    jq \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# Node.js 24 via NodeSource
# ============================================
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm globally
RUN npm install -g pnpm@${PNPM_VERSION}

# Configure pnpm
ENV PNPM_HOME=/home/vscode/.local/share/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"

# Install turbo and Claude Code globally
RUN npm install -g turbo @anthropic-ai/claude-code

# ============================================
# Go 1.24
# ============================================
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xzf -

ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH="${GOPATH}/bin:${GOROOT}/bin:${PATH}"

# Install Go tools
RUN go install github.com/air-verse/air@latest \
    && go install github.com/go-delve/delve/cmd/dlv@latest \
    && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest \
    && go install golang.org/x/tools/gopls@latest

# ============================================
# Python 3.14 via deadsnakes PPA
# ============================================
RUN add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-venv \
        python${PYTHON_VERSION}-dev \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.14 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1

# Install pip for Python 3.14
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python${PYTHON_VERSION}

# Install Python development tools
RUN pip install --no-cache-dir \
    uv \
    ruff \
    mypy \
    debugpy

# ============================================
# PostgreSQL Client
# ============================================
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client-18 \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# Atlas - Database Schema Management
# ============================================
RUN curl -sSf https://atlasgo.sh | sh -s -- -y \
    && mv /root/.atlas/bin/atlas /usr/local/bin/atlas \
    && chmod +x /usr/local/bin/atlas

# ============================================
# User Configuration
# ============================================
USER vscode

# Create directories for caches
RUN mkdir -p /home/vscode/.cache/go-build \
    && mkdir -p /home/vscode/.cache/pip \
    && mkdir -p /home/vscode/.local/share/pnpm/store

# Configure Git (will be overridden by devcontainer)
RUN git config --global init.defaultBranch main \
    && git config --global core.editor "code --wait"

# Set working directory
WORKDIR /workspace

# Default command
CMD ["sleep", "infinity"]
