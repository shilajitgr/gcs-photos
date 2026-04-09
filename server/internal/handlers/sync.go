package handlers

import (
	"net/http"
	"strconv"

	"github.com/nicholasgasior/cgs-photos/server/internal/middleware"
	"github.com/nicholasgasior/cgs-photos/server/internal/services"
	"github.com/nicholasgasior/cgs-photos/server/pkg/response"
)

// SyncHandler holds dependencies for sync endpoints.
type SyncHandler struct {
	Firestore *services.FirestoreService
}

// NewSyncHandler creates a new SyncHandler.
func NewSyncHandler(fs *services.FirestoreService) *SyncHandler {
	return &SyncHandler{Firestore: fs}
}

// SyncPhotos handles GET /api/v1/photos/sync?mode=full&cursor=&limit=1000.
func (h *SyncHandler) SyncPhotos(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	mode := r.URL.Query().Get("mode")
	if mode == "" {
		mode = "full"
	}

	cursor := r.URL.Query().Get("cursor")

	limit := 1000
	if l := r.URL.Query().Get("limit"); l != "" {
		parsed, err := strconv.Atoi(l)
		if err != nil || parsed < 1 || parsed > 5000 {
			response.Error(w, http.StatusBadRequest, "limit must be between 1 and 5000")
			return
		}
		limit = parsed
	}

	photos, nextCursor, err := h.Firestore.ListPhotosPaginated(r.Context(), userID, limit, cursor)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "failed to sync photos")
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{
		"photos":     photos,
		"nextCursor": nextCursor,
		"hasMore":    nextCursor != "",
		"count":      len(photos),
		"mode":       mode,
	})
}
