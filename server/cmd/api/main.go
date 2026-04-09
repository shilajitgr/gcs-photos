package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"cloud.google.com/go/firestore"
	"cloud.google.com/go/pubsub"
	"cloud.google.com/go/storage"
	firebase "firebase.google.com/go/v4"
	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/rs/zerolog"

	"github.com/nicholasgasior/cgs-photos/server/internal/config"
	"github.com/nicholasgasior/cgs-photos/server/internal/handlers"
	"github.com/nicholasgasior/cgs-photos/server/internal/middleware"
	"github.com/nicholasgasior/cgs-photos/server/internal/services"
)

func main() {
	// Logger
	logger := zerolog.New(os.Stdout).With().Timestamp().Logger()

	// Config
	cfg := config.Load()

	ctx := context.Background()

	// Firebase Auth
	firebaseApp, err := firebase.NewApp(ctx, nil)
	if err != nil {
		logger.Warn().Err(err).Msg("failed to initialize firebase app — auth will be unavailable")
	}
	var authClient middleware.AuthVerifier
	if firebaseApp != nil {
		authClient, err = firebaseApp.Auth(ctx)
		if err != nil {
			logger.Warn().Err(err).Msg("failed to initialize firebase auth client")
		}
	}

	// Firestore
	fsClient, err := firestore.NewClient(ctx, cfg.GCPProjectID)
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to initialize firestore client")
	}
	defer fsClient.Close()

	// GCS
	gcsClient, err := storage.NewClient(ctx)
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to initialize gcs client")
	}
	defer gcsClient.Close()

	// Pub/Sub
	psClient, err := pubsub.NewClient(ctx, cfg.GCPProjectID)
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to initialize pubsub client")
	}
	defer psClient.Close()

	// Services
	firestoreSvc := services.NewFirestoreService(fsClient)
	storageSvc := services.NewStorageService(gcsClient)
	pubsubSvc := services.NewPubSubService(psClient, cfg.PubSubTopic)
	defer pubsubSvc.Close()

	// Handlers
	photoHandler := handlers.NewPhotoHandler(firestoreSvc)
	uploadHandler := handlers.NewUploadHandler(storageSvc, pubsubSvc)
	syncHandler := handlers.NewSyncHandler(firestoreSvc)

	// Router
	r := chi.NewRouter()

	// Global middleware
	r.Use(chimiddleware.RequestID)
	r.Use(chimiddleware.RealIP)
	r.Use(middleware.Logging(logger))
	r.Use(middleware.Tracing("cgs-photos-api"))
	r.Use(chimiddleware.Recoverer)

	// Public routes
	r.Get("/healthz", handlers.HealthCheck)

	// Protected routes
	r.Route("/api/v1", func(r chi.Router) {
		r.Use(middleware.Auth(authClient))

		r.Get("/photos", photoHandler.ListPhotos)
		r.Get("/photos/{imageUID}", photoHandler.GetPhoto)
		r.Post("/photos/upload-url", uploadHandler.GenerateUploadURL)
		r.Get("/photos/sync", syncHandler.SyncPhotos)
	})

	// Server
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	go func() {
		logger.Info().Str("port", cfg.Port).Msg("starting server")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal().Err(err).Msg("server failed")
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info().Msg("shutting down server")

	shutdownCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Fatal().Err(err).Msg("server forced to shutdown")
	}

	logger.Info().Msg("server stopped")
}
