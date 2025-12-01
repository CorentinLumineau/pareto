"""Celery configuration for Pareto workers."""

import os

# Broker settings
broker_url = os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0")
result_backend = os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/1")

# Task settings
task_serializer = "json"
result_serializer = "json"
accept_content = ["json"]
timezone = "Europe/Paris"
enable_utc = True

# Task execution settings
task_acks_late = True
task_reject_on_worker_lost = True
worker_prefetch_multiplier = 1

# Result settings
result_expires = 3600  # 1 hour

# Task routes
task_routes = {
    "src.normalizer.tasks.*": {"queue": "normalizer"},
    "src.pareto.tasks.*": {"queue": "pareto"},
}

# Rate limits
task_annotations = {
    "src.normalizer.tasks.fetch_page": {"rate_limit": "10/m"},
}

# Logging
worker_hijack_root_logger = False
