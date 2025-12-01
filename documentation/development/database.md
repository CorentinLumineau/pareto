# Database Management

> **Declarative schema management with Atlas (Prisma-like DX)**

## Overview

Pareto Comparator uses [Atlas](https://atlasgo.io/) for database schema management. Atlas provides:

- **Declarative schema** - Define desired state in `schema.sql`
- **Auto-diffing** - Atlas generates migrations automatically
- **Migration linting** - Catch dangerous changes before applying
- **Version control** - All migrations tracked in git

## Quick Start

```bash
# 1. Edit the schema (add table, column, index)
vim apps/api/schema.sql

# 2. Generate migration from changes
make db-diff name=add_user_preferences

# 3. Review generated SQL
cat apps/api/migrations/*_add_user_preferences.sql

# 4. Lint for issues
make db-lint

# 5. Apply to database
make db-apply

# 6. Commit both files
git add apps/api/schema.sql apps/api/migrations/
git commit -m "feat: add user preferences table"
```

## File Structure

```
apps/api/
├── atlas.hcl              # Atlas configuration
├── schema.sql             # Declarative schema (source of truth)
└── migrations/            # Auto-generated migrations
    ├── 20241201000001_init.sql
    ├── 20241201000002_add_feature.sql
    └── atlas.sum          # Integrity checksum
```

## Commands

| Command | Description |
|---------|-------------|
| `make db-diff name=<name>` | Generate migration from schema changes |
| `make db-apply` | Apply pending migrations |
| `make db-status` | Show migration status |
| `make db-lint` | Lint migrations for issues |
| `make db-hash` | Update atlas.sum hash file |
| `make db-validate` | Validate schema.sql syntax |
| `make db-init` | Create initial migration (first time) |
| `make db-reset` | Reset database (DANGEROUS!) |

## Schema Overview

### Core Tables

```sql
-- Products (from brand websites)
products
├── id (UUID)
├── category_id (FK → categories)
├── name, slug, brand, model
├── ean (EAN-13 barcode)
├── attributes (JSONB - 40+ specs)
└── timestamps

-- Variants (color/storage combinations)
variants
├── id (UUID)
├── product_id (FK → products)
├── sku, ean
├── color, storage_gb, ram_gb
├── msrp (official price)
└── timestamps

-- Offers (marketplace prices)
offers
├── id (UUID)
├── product_id (FK → products)
├── variant_id (FK → variants, optional)
├── retailer_id (FK → retailers)
├── price, shipping, url
├── in_stock, scraped_at
└── timestamps

-- Price History (TimescaleDB)
price_history
├── time (partition key)
├── product_id, variant_id, retailer_id
├── price, in_stock
└── (hypertable for time-series)
```

### Reference Tables

```sql
-- Categories
categories (id, name, slug, parent_id, attribute_schema)

-- Retailers
retailers (id, name, website_url, affiliate_network, rate_limit_ms)

-- Scrape Jobs
scrape_jobs (id, job_type, status, attempts, scheduled_at)

-- Affiliate Clicks
affiliate_clicks (id, offer_id, clicked_at, ip_hash)
```

## Adding a New Table

### 1. Edit schema.sql

```sql
-- apps/api/schema.sql

-- Add new table at the end
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    category_id UUID REFERENCES categories(id),
    min_price DECIMAL(10, 2),
    max_price DECIMAL(10, 2),
    brands TEXT[],
    attributes JSONB DEFAULT '{}',
    notify_price_drop BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_preferences_user ON user_preferences(user_id);
```

### 2. Generate Migration

```bash
make db-diff name=add_user_preferences
```

Atlas generates:
```sql
-- migrations/20241201120000_add_user_preferences.sql
-- Create table "user_preferences"
CREATE TABLE "public"."user_preferences" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "user_id" text NOT NULL,
    ...
);
-- Create index "idx_user_preferences_user"
CREATE INDEX "idx_user_preferences_user" ON "public"."user_preferences" ("user_id");
```

### 3. Apply Migration

```bash
make db-apply
```

## Adding a Column

### 1. Edit schema.sql

```sql
-- In the products table, add:
CREATE TABLE products (
    ...
    meta_keywords TEXT[],  -- Add this line
    ...
);
```

### 2. Generate & Apply

```bash
make db-diff name=add_product_keywords
make db-apply
```

## Modifying a Column

### Non-Destructive Changes (Safe)

```sql
-- Increasing varchar length
-- Adding nullable column
-- Adding default value
```

### Destructive Changes (Requires Care)

```sql
-- Dropping column (data loss)
-- Changing column type
-- Adding NOT NULL to existing column
```

Atlas will **warn or block** destructive changes by default.

To allow a specific destructive change, review the generated migration carefully.

## Migration Linting

Atlas checks for:

- **Destructive changes** - DROP COLUMN, DROP TABLE
- **Data-dependent changes** - Adding NOT NULL without default
- **Performance issues** - Missing indexes on foreign keys
- **Naming conventions** - Consistent naming

```bash
# Lint the latest migration
make db-lint

# Example output:
# Analyzing migration "20241201_drop_column":
#   L2: Dropping column "old_field" may result in data loss
#
#   Fix: Add explicit statement to handle existing data
```

## Environment Configuration

### Local Development

```bash
# .env or docker-compose environment
DATABASE_URL=postgresql://pareto:pareto_dev@localhost:5432/pareto_dev?sslmode=disable
```

### CI/CD

```bash
# Use ci environment
cd apps/api && atlas migrate apply --env ci
```

### Production

```bash
# Use prod environment (no dev URL, stricter checks)
cd apps/api && atlas migrate apply --env prod
```

## TimescaleDB Integration

The `price_history` table is designed for TimescaleDB:

```sql
-- After creating the table, run:
SELECT create_hypertable('price_history', 'time');
```

This is **not** in the schema.sql because:
1. It requires TimescaleDB extension to be installed
2. It's a one-time operation
3. It modifies table internals

Run manually after initial migration:
```bash
psql $DATABASE_URL -c "SELECT create_hypertable('price_history', 'time');"
```

## Troubleshooting

### Migration Fails

```bash
# Check current status
make db-status

# View migration SQL
cat apps/api/migrations/<migration_name>.sql

# Apply with verbose output
cd apps/api && atlas migrate apply --env local --log debug
```

### Schema Drift

If the database differs from migrations:

```bash
# Check what's different
cd apps/api && atlas schema diff \
  --from $DATABASE_URL \
  --to file://schema.sql

# Reset (DEVELOPMENT ONLY)
make db-reset
```

### Hash Mismatch

If `atlas.sum` is outdated:

```bash
make db-hash
```

### Docker Issues

Atlas uses Docker for the `dev` URL (diffing):

```bash
# Ensure Docker is running
docker info

# Pull postgres image if needed
docker pull postgres:18
```

## Best Practices

1. **One change per migration** - Keep migrations focused
2. **Review generated SQL** - Always check before applying
3. **Test migrations** - Apply to dev before prod
4. **Never edit applied migrations** - Create new ones instead
5. **Commit schema.sql AND migrations** - Both are needed
6. **Use meaningful names** - `add_user_email` not `update_1`

## Go Integration

### Programmatic Migration Apply

```go
import "github.com/clumineau/pareto/apps/api/internal/database"

// Apply on startup (if AUTO_MIGRATE=true)
database.ApplyOnStartup(ctx, os.Getenv("DATABASE_URL"))

// Or explicitly
migrator := database.NewMigrator(&database.MigrationConfig{
    DatabaseURL: os.Getenv("DATABASE_URL"),
    AtlasEnv:    "local",
})
migrator.Apply(ctx)
```

### Using Domain Types

```go
import "github.com/clumineau/pareto/apps/api/internal/catalog/domain"

product := domain.Product{
    ID:         uuid.NewString(),
    CategoryID: "...",
    Name:       "iPhone 16 Pro",
    Brand:      "Apple",
    Model:      "iPhone 16 Pro",
    EAN:        ptr("0194253715214"),
    Attributes: map[string]interface{}{
        "screen_size":    6.3,
        "battery_mah":    4685,
        "5g":             true,
    },
    Source:    domain.SourceBrand,
}
```

---

**Back to**: [Development README](./README.md)
