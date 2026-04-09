package handlers

import (
	"net/http"

	"github.com/nicholasgasior/cgs-photos/server/pkg/response"
)

// HealthCheck returns a simple health status for liveness/readiness probes.
func HealthCheck(w http.ResponseWriter, r *http.Request) {
	response.JSON(w, http.StatusOK, map[string]string{"status": "ok"})
}
