# Python workers Dockerfile
FROM python:3.14-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libxml2-dev \
    libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for caching
COPY pyproject.toml ./

# Install Python dependencies
RUN pip install --no-cache-dir -e .

# Copy source code
COPY . .

# Create non-root user
RUN useradd -m -r celeryuser && chown -R celeryuser:celeryuser /app
USER celeryuser

# Run Celery worker
CMD ["celery", "-A", "src.tasks.celery_app", "worker", "--loglevel=info", "--concurrency=2"]
