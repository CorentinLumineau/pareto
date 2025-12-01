package database

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
)

// MigrationConfig holds configuration for Atlas migrations
type MigrationConfig struct {
	// DatabaseURL is the connection string for the target database
	DatabaseURL string

	// MigrationDir is the path to the migrations directory (default: "migrations")
	MigrationDir string

	// AtlasEnv is the Atlas environment to use (default: "local")
	AtlasEnv string

	// DryRun if true, only shows what would be applied without making changes
	DryRun bool

	// Logger for migration operations
	Logger *slog.Logger
}

// DefaultMigrationConfig returns a MigrationConfig with sensible defaults
func DefaultMigrationConfig() *MigrationConfig {
	return &MigrationConfig{
		DatabaseURL:  os.Getenv("DATABASE_URL"),
		MigrationDir: "migrations",
		AtlasEnv:     "local",
		DryRun:       false,
		Logger:       slog.Default(),
	}
}

// Migrator handles database migrations using Atlas
type Migrator struct {
	config *MigrationConfig
}

// NewMigrator creates a new Migrator with the given config
func NewMigrator(config *MigrationConfig) *Migrator {
	if config == nil {
		config = DefaultMigrationConfig()
	}
	if config.Logger == nil {
		config.Logger = slog.Default()
	}
	return &Migrator{config: config}
}

// Apply applies all pending migrations
func (m *Migrator) Apply(ctx context.Context) error {
	m.config.Logger.Info("applying database migrations",
		"env", m.config.AtlasEnv,
		"dir", m.config.MigrationDir,
	)

	args := []string{
		"migrate", "apply",
		"--env", m.config.AtlasEnv,
	}

	if m.config.DryRun {
		args = append(args, "--dry-run")
	}

	if err := m.runAtlas(ctx, args...); err != nil {
		return fmt.Errorf("failed to apply migrations: %w", err)
	}

	m.config.Logger.Info("migrations applied successfully")
	return nil
}

// Status returns the current migration status
func (m *Migrator) Status(ctx context.Context) error {
	m.config.Logger.Info("checking migration status",
		"env", m.config.AtlasEnv,
	)

	return m.runAtlas(ctx,
		"migrate", "status",
		"--env", m.config.AtlasEnv,
	)
}

// Lint checks migrations for potential issues
func (m *Migrator) Lint(ctx context.Context, latest int) error {
	m.config.Logger.Info("linting migrations",
		"env", m.config.AtlasEnv,
		"latest", latest,
	)

	return m.runAtlas(ctx,
		"migrate", "lint",
		"--env", m.config.AtlasEnv,
		"--latest", fmt.Sprintf("%d", latest),
	)
}

// Validate checks if the schema file is valid
func (m *Migrator) Validate(ctx context.Context) error {
	m.config.Logger.Info("validating schema")

	return m.runAtlas(ctx,
		"schema", "inspect",
		"--env", m.config.AtlasEnv,
		"--url", "file://schema.sql",
	)
}

// runAtlas executes an Atlas command
func (m *Migrator) runAtlas(ctx context.Context, args ...string) error {
	// Find the working directory (should contain atlas.hcl)
	workDir, err := m.findAtlasDir()
	if err != nil {
		return fmt.Errorf("failed to find atlas directory: %w", err)
	}

	cmd := exec.CommandContext(ctx, "atlas", args...)
	cmd.Dir = workDir
	cmd.Env = append(os.Environ(), fmt.Sprintf("DATABASE_URL=%s", m.config.DatabaseURL))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	m.config.Logger.Debug("running atlas command",
		"args", args,
		"dir", workDir,
	)

	return cmd.Run()
}

// findAtlasDir finds the directory containing atlas.hcl
func (m *Migrator) findAtlasDir() (string, error) {
	// Start from current directory and look for atlas.hcl
	candidates := []string{
		".",
		"apps/api",
		"../",
		"../../apps/api",
	}

	for _, candidate := range candidates {
		atlasPath := filepath.Join(candidate, "atlas.hcl")
		if _, err := os.Stat(atlasPath); err == nil {
			absPath, err := filepath.Abs(candidate)
			if err != nil {
				return "", err
			}
			return absPath, nil
		}
	}

	return "", fmt.Errorf("atlas.hcl not found in any expected location")
}

// MustApply applies migrations and panics on error
// Useful for application startup
func MustApply(ctx context.Context, databaseURL string) {
	config := DefaultMigrationConfig()
	config.DatabaseURL = databaseURL

	migrator := NewMigrator(config)
	if err := migrator.Apply(ctx); err != nil {
		panic(fmt.Sprintf("failed to apply database migrations: %v", err))
	}
}

// ApplyOnStartup applies migrations if AUTO_MIGRATE environment variable is set
// Safe to call during application startup
func ApplyOnStartup(ctx context.Context, databaseURL string) error {
	if os.Getenv("AUTO_MIGRATE") != "true" {
		slog.Debug("AUTO_MIGRATE not set, skipping automatic migrations")
		return nil
	}

	config := DefaultMigrationConfig()
	config.DatabaseURL = databaseURL

	migrator := NewMigrator(config)
	return migrator.Apply(ctx)
}
