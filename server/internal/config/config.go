package config

import (
	"os"
)

// Config holds application configuration loaded from environment variables.
type Config struct {
	Port              string
	GCPProjectID      string
	FirestoreDatabase string
	PubSubTopic       string
}

// Load reads configuration from environment variables with sensible defaults.
func Load() *Config {
	return &Config{
		Port:              getEnv("PORT", "8080"),
		GCPProjectID:      getEnv("GCP_PROJECT_ID", ""),
		FirestoreDatabase: getEnv("FIRESTORE_DATABASE", "(default)"),
		PubSubTopic:       getEnv("PUBSUB_TOPIC", "photo-uploads"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
