package api_test

import (
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"
)

func getBaseURL() string {
	if url := os.Getenv("API_BASE_URL"); url != "" {
		return url
	}
	return "http://localhost:8080"
}

func TestHealthEndpoint(t *testing.T) {
	baseURL := getBaseURL()
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Get(fmt.Sprintf("%s/healthz", baseURL))
	if err != nil {
		t.Fatalf("failed to reach /healthz endpoint: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("expected status 200, got %d", resp.StatusCode)
	}
}
