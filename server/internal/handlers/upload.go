package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/nicholasgasior/cgs-photos/server/internal/middleware"
	"github.com/nicholasgasior/cgs-photos/server/internal/services"
	"github.com/nicholasgasior/cgs-photos/server/pkg/response"
)

// UploadHandler holds dependencies for upload endpoints.
type UploadHandler struct {
	Storage *services.StorageService
	PubSub  *services.PubSubService
}

// NewUploadHandler creates a new UploadHandler.
func NewUploadHandler(storage *services.StorageService, pubsub *services.PubSubService) *UploadHandler {
	return &UploadHandler{Storage: storage, PubSub: pubsub}
}

// uploadURLRequest is the request body for generating an upload URL.
type uploadURLRequest struct {
	FileName    string `json:"fileName"`
	ContentType string `json:"contentType"`
	Bucket      string `json:"bucket"`
}

// GenerateUploadURL handles POST /api/v1/photos/upload-url.
func (h *UploadHandler) GenerateUploadURL(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req uploadURLRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.FileName == "" || req.ContentType == "" || req.Bucket == "" {
		response.Error(w, http.StatusBadRequest, "fileName, contentType, and bucket are required")
		return
	}

	objectPath := "originals/" + userID + "/" + req.FileName

	signedURL, err := h.Storage.GenerateSignedUploadURL(r.Context(), req.Bucket, objectPath, req.ContentType)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "failed to generate upload URL")
		return
	}

	response.JSON(w, http.StatusOK, map[string]string{
		"uploadURL":  signedURL,
		"objectPath": objectPath,
	})
}
