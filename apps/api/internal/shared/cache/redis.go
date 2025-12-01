package cache

import (
	"context"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog/log"
)

// Client wraps the Redis client
type Client struct {
	rdb *redis.Client
}

// New creates a new Redis client
func New(redisURL string) *Client {
	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to parse Redis URL")
	}

	rdb := redis.NewClient(opt)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Warn().Err(err).Msg("Redis connection failed, cache disabled")
		return &Client{rdb: nil}
	}

	log.Info().Msg("Redis connected successfully")

	return &Client{rdb: rdb}
}

// Close closes the Redis connection
func (c *Client) Close() {
	if c.rdb != nil {
		c.rdb.Close()
		log.Info().Msg("Redis connection closed")
	}
}

// Get retrieves a value from cache
func (c *Client) Get(ctx context.Context, key string) (string, error) {
	if c.rdb == nil {
		return "", redis.Nil
	}
	return c.rdb.Get(ctx, key).Result()
}

// Set stores a value in cache with TTL
func (c *Client) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	if c.rdb == nil {
		return nil
	}
	return c.rdb.Set(ctx, key, value, ttl).Err()
}

// Delete removes a value from cache
func (c *Client) Delete(ctx context.Context, keys ...string) error {
	if c.rdb == nil {
		return nil
	}
	return c.rdb.Del(ctx, keys...).Err()
}

// Health checks if Redis is healthy
func (c *Client) Health(ctx context.Context) error {
	if c.rdb == nil {
		return nil // Cache is optional
	}
	return c.rdb.Ping(ctx).Err()
}

// Client returns the underlying Redis client
func (c *Client) Client() *redis.Client {
	return c.rdb
}
