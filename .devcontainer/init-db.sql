-- Initialize PostgreSQL for Pareto Comparator development
-- This script runs automatically when the postgres container starts for the first time

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgcrypto for hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enable pg_trgm for text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create test database for CI
CREATE DATABASE pareto_test;

-- Grant privileges on test database
GRANT ALL PRIVILEGES ON DATABASE pareto_test TO pareto;

-- Connect to test database and enable extensions
\c pareto_test
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Log completion
DO $$
BEGIN
  RAISE NOTICE 'Database initialization complete!';
END $$;
