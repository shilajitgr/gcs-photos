package handlers

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/storage"
	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"

	"github.com/nicholasgasior/cgs-photos/proxy/internal/config"
	"github.com/nicholasgasior/cgs-photos/proxy/internal/resize"
)

type ProxyHandler struct {
	gcs    *storage.Client
	cfg    *config.Config
	logger zerolog.Logger
}

func NewProxyHandler(gcs *storage.Client, cfg *config.Config, logger zerolog.Logger) *ProxyHandler {
	return &ProxyHandler{gcs: gcs, cfg: cfg, logger: logger}
}

// ServeThumbnail serves a pre-generated thumbnail from GCS.
// URL pattern: /thumb/{bucket}/{hash}_{size}.avif
// Content-hash-based URLs make CDN cache invalidation unnecessary.
func (h *ProxyHandler) ServeThumbnail(w http.ResponseWriter, r *http.Request) {
	bucket := chi.URLParam(r, "bucket")
	fileName := chi.URLParam(r, "fileName")

	if bucket == "" || fileName == "" {
		http.Error(w, "missing bucket or fileName", http.StatusBadRequest)
		return
	}

	objectPath := "thumbnails/" + fileName

	ctx, cancel := context.WithTimeout(r.Context(), 30*time.Second)
	defer cancel()

	reader, err := h.gcs.Bucket(bucket).Object(objectPath).NewReader(ctx)
	if err != nil {
		if err == storage.ErrObjectNotExist {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		h.logger.Error().Err(err).Str("bucket", bucket).Str("object", objectPath).Msg("gcs read error")
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer reader.Close()

	contentType := reader.Attrs.ContentType
	if contentType == "" {
		contentType = detectContentType(fileName)
	}

	etag := fmt.Sprintf(`"%08x"`, reader.Attrs.CRC32C)
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", h.cfg.CacheControlThumb)
	w.Header().Set("ETag", etag)

	// Support conditional requests
	if match := r.Header.Get("If-None-Match"); match != "" {
		if match == etag {
			w.WriteHeader(http.StatusNotModified)
			return
		}
	}

	if reader.Attrs.Size > 0 {
		w.Header().Set("Content-Length", strconv.FormatInt(reader.Attrs.Size, 10))
	}

	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, reader)
}

// ResizeOnDemand reads an original from GCS, resizes it, and returns the result.
// URL pattern: /resize/{bucket}/{objectPath}?w=600&fmt=avif
// This is the cache-miss fallback — CDN caches the response.
func (h *ProxyHandler) ResizeOnDemand(w http.ResponseWriter, r *http.Request) {
	bucket := chi.URLParam(r, "bucket")
	objectPath := chi.URLParam(r, "objectPath")

	if bucket == "" || objectPath == "" {
		http.Error(w, "missing bucket or objectPath", http.StatusBadRequest)
		return
	}

	// Parse resize parameters
	widthStr := r.URL.Query().Get("w")
	format := r.URL.Query().Get("fmt")

	width := 600 // default
	if widthStr != "" {
		parsed, err := strconv.Atoi(widthStr)
		if err != nil || parsed < 1 {
			http.Error(w, "invalid width", http.StatusBadRequest)
			return
		}
		if parsed > h.cfg.MaxResizeWidth {
			parsed = h.cfg.MaxResizeWidth
		}
		width = parsed
	}

	if format == "" {
		format = "avif"
	}
	if format != "avif" && format != "webp" && format != "jpeg" {
		http.Error(w, "unsupported format: use avif, webp, or jpeg", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 60*time.Second)
	defer cancel()

	// Read original from GCS
	reader, err := h.gcs.Bucket(bucket).Object(objectPath).NewReader(ctx)
	if err != nil {
		if err == storage.ErrObjectNotExist {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		h.logger.Error().Err(err).Str("bucket", bucket).Str("object", objectPath).Msg("gcs read error")
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer reader.Close()

	original, err := io.ReadAll(reader)
	if err != nil {
		h.logger.Error().Err(err).Msg("failed to read object")
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	resized, contentType, err := resize.Process(original, width, format)
	if err != nil {
		h.logger.Error().Err(err).Int("width", width).Str("format", format).Msg("resize failed")
		http.Error(w, "resize error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Content-Length", strconv.Itoa(len(resized)))
	w.Header().Set("Cache-Control", h.cfg.CacheControlResize)

	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(resized)
}

func detectContentType(fileName string) string {
	lower := strings.ToLower(fileName)
	switch {
	case strings.HasSuffix(lower, ".avif"):
		return "image/avif"
	case strings.HasSuffix(lower, ".webp"):
		return "image/webp"
	case strings.HasSuffix(lower, ".jpg"), strings.HasSuffix(lower, ".jpeg"):
		return "image/jpeg"
	case strings.HasSuffix(lower, ".png"):
		return "image/png"
	default:
		return "application/octet-stream"
	}
}
