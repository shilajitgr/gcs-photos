package services

import (
	"context"
	"fmt"
	"time"

	"cloud.google.com/go/storage"
)

// StorageService handles GCS signed URL generation for user buckets.
type StorageService struct {
	client *storage.Client
}

// NewStorageService creates a new StorageService.
func NewStorageService(client *storage.Client) *StorageService {
	return &StorageService{client: client}
}

// GenerateSignedUploadURL creates a V4 signed URL for uploading to the user's bucket.
func (s *StorageService) GenerateSignedUploadURL(ctx context.Context, bucket, objectPath, contentType string) (string, error) {
	url, err := s.client.Bucket(bucket).SignedURL(objectPath, &storage.SignedURLOptions{
		Method:      "PUT",
		Expires:     time.Now().Add(15 * time.Minute),
		ContentType: contentType,
		Scheme:      storage.SigningSchemeV4,
	})
	if err != nil {
		return "", fmt.Errorf("gcs signed url: %w", err)
	}
	return url, nil
}
