package handlers

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/nicholasgasior/cgs-photos/server/internal/middleware"
	"github.com/nicholasgasior/cgs-photos/server/internal/services"
	"github.com/nicholasgasior/cgs-photos/server/pkg/response"
)

// PhotoHandler holds dependencies for photo endpoints.
type PhotoHandler struct {
	Firestore *services.FirestoreService
}

// NewPhotoHandler creates a new PhotoHandler.
func NewPhotoHandler(fs *services.FirestoreService) *PhotoHandler {
	return &PhotoHandler{Firestore: fs}
}

// ListPhotos handles GET /api/v1/photos.
func (h *PhotoHandler) ListPhotos(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	photos, err := h.Firestore.ListPhotos(r.Context(), userID, 100)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "failed to list photos")
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{
		"photos": photos,
		"count":  len(photos),
	})
}

// GetPhoto handles GET /api/v1/photos/{imageUID}.
func (h *PhotoHandler) GetPhoto(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	imageUID := chi.URLParam(r, "imageUID")
	if imageUID == "" {
		response.Error(w, http.StatusBadRequest, "imageUID is required")
		return
	}

	photo, err := h.Firestore.GetPhoto(r.Context(), userID, imageUID)
	if err != nil {
		response.Error(w, http.StatusNotFound, "photo not found")
		return
	}

	response.JSON(w, http.StatusOK, photo)
}
