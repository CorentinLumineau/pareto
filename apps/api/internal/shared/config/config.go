package config

import (
	"os"
)

// Config holds the application configuration
type Config struct {
	Env         string
	Port        string
	DatabaseURL string
	RedisURL    string
}

// Load loads the configuration from environment variables
func Load() *Config {
	return &Config{
		Env:         getEnv("APP_ENV", "development"),
		Port:        getEnv("PORT", "8080"),
		DatabaseURL: getEnv("DATABASE_URL", "postgresql://pareto:pareto@localhost:5432/pareto?sslmode=disable"),
		RedisURL:    getEnv("REDIS_URL", "redis://localhost:6379/0"),
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
