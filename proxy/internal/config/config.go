package config

import "os"

type Config struct {
	Port             string
	DefaultBucket    string
	MaxResizeWidth   int
	CacheControlThumb string
	CacheControlResize string
}

func Load() *Config {
	return &Config{
		Port:               getEnv("PORT", "8080"),
		DefaultBucket:      getEnv("DEFAULT_BUCKET", ""),
		MaxResizeWidth:     1200,
		CacheControlThumb:  getEnv("CACHE_CONTROL_THUMB", "public, max-age=31536000, immutable"),
		CacheControlResize: getEnv("CACHE_CONTROL_RESIZE", "public, max-age=86400"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
