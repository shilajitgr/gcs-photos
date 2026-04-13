package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"cloud.google.com/go/storage"
	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/rs/zerolog"

	"github.com/nicholasgasior/cgs-photos/proxy/internal/config"
	"github.com/nicholasgasior/cgs-photos/proxy/internal/handlers"
)

func main() {
	logger := zerolog.New(os.Stdout).With().Timestamp().Logger()

	cfg := config.Load()

	ctx := context.Background()

	gcsClient, err := storage.NewClient(ctx)
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to initialize gcs client")
	}
	defer gcsClient.Close()

	proxyHandler := handlers.NewProxyHandler(gcsClient, cfg, logger)

	r := chi.NewRouter()

	r.Use(chimiddleware.RequestID)
	r.Use(chimiddleware.RealIP)
	r.Use(chimiddleware.Recoverer)

	r.Get("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	// Thumbnail serving: /thumb/{bucket}/{hash}_{size}.{format}
	r.Get("/thumb/{bucket}/{fileName}", proxyHandler.ServeThumbnail)

	// On-demand resize: /resize/{bucket}/{objectPath}?w=600&fmt=avif
	r.Get("/resize/{bucket}/{objectPath:.*}", proxyHandler.ResizeOnDemand)

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      r,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 60 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	go func() {
		logger.Info().Str("port", cfg.Port).Msg("starting image proxy")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal().Err(err).Msg("server failed")
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info().Msg("shutting down proxy")

	shutdownCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Fatal().Err(err).Msg("server forced to shutdown")
	}

	logger.Info().Msg("proxy stopped")
}
