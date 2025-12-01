// Atlas configuration for Pareto Comparator
// Declarative database schema management with auto-diffing

variable "database_url" {
  type    = string
  default = getenv("DATABASE_URL")
}

// Local development environment
env "local" {
  // Source of truth: declarative schema
  src = "file://schema.sql"

  // Target database
  url = var.database_url

  // Dev database for diffing (uses Docker)
  dev = "docker://postgres/18/dev?search_path=public"

  // Migration directory
  migration {
    dir    = "file://migrations"
    format = atlas
  }

  // Diff configuration
  diff {
    // Concurrent index creation for zero-downtime
    concurrent_index {
      create = true
      drop   = true
    }
  }

  // Lint rules for safety
  lint {
    // Detect destructive changes
    destructive {
      error = true
    }
    // Detect data-dependent changes
    data_depend {
      error = true
    }
  }
}

// CI environment (stricter)
env "ci" {
  src = "file://schema.sql"
  url = var.database_url
  dev = "docker://postgres/18/dev?search_path=public"

  migration {
    dir    = "file://migrations"
    format = atlas
  }

  // Stricter lint for CI
  lint {
    destructive {
      error = true
    }
    data_depend {
      error = true
    }
    // Require review for certain changes
    review = WARNING
  }
}

// Production environment
env "prod" {
  src = "file://schema.sql"
  url = var.database_url

  migration {
    dir    = "file://migrations"
    format = atlas
  }

  // No dev URL in prod - migrations must be pre-generated
  // Baseline for existing databases
  migration {
    baseline = "20241201000000"
  }
}
