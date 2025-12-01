"""Celery application configuration."""

from celery import Celery

app = Celery("pareto_workers")

# Load config from celeryconfig.py
app.config_from_object("celeryconfig")

# Auto-discover tasks from these modules
app.autodiscover_tasks(["src.normalizer", "src.pareto"])

if __name__ == "__main__":
    app.start()
