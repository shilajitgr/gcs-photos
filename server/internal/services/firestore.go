package services

import (
	"context"
	"fmt"

	"cloud.google.com/go/firestore"
	"github.com/nicholasgasior/cgs-photos/server/internal/models"
	"google.golang.org/api/iterator"
)

// FirestoreService wraps the Firestore client for photo metadata operations.
type FirestoreService struct {
	client     *firestore.Client
	collection string
}

// NewFirestoreService creates a new FirestoreService.
func NewFirestoreService(client *firestore.Client) *FirestoreService {
	return &FirestoreService{
		client:     client,
		collection: "photos",
	}
}

// GetPhoto retrieves a single photo document by imageUID for a given user.
func (s *FirestoreService) GetPhoto(ctx context.Context, userID, imageUID string) (*models.Photo, error) {
	doc, err := s.client.Collection(s.collection).Doc(imageUID).Get(ctx)
	if err != nil {
		return nil, fmt.Errorf("firestore get photo: %w", err)
	}

	var photo models.Photo
	if err := doc.DataTo(&photo); err != nil {
		return nil, fmt.Errorf("firestore decode photo: %w", err)
	}

	if photo.UserID != userID {
		return nil, fmt.Errorf("photo not found")
	}

	return &photo, nil
}

// ListPhotos returns photos for a user with a limit.
func (s *FirestoreService) ListPhotos(ctx context.Context, userID string, limit int) ([]models.Photo, error) {
	iter := s.client.Collection(s.collection).
		Where("userID", "==", userID).
		Limit(limit).
		Documents(ctx)
	defer iter.Stop()

	return collectPhotos(iter)
}

// ListPhotosPaginated returns a page of photos for sync, ordered by syncVersion.
// Returns photos and the last document snapshot for cursor-based pagination.
func (s *FirestoreService) ListPhotosPaginated(ctx context.Context, userID string, limit int, cursor string) ([]models.Photo, string, error) {
	q := s.client.Collection(s.collection).
		Where("userID", "==", userID).
		OrderBy("syncVersion", firestore.Asc).
		Limit(limit)

	if cursor != "" {
		// Use the cursor as a startAfter value for syncVersion.
		doc, err := s.client.Collection(s.collection).Doc(cursor).Get(ctx)
		if err != nil {
			return nil, "", fmt.Errorf("firestore get cursor doc: %w", err)
		}
		q = q.StartAfter(doc)
	}

	iter := q.Documents(ctx)
	defer iter.Stop()

	photos, err := collectPhotos(iter)
	if err != nil {
		return nil, "", err
	}

	var nextCursor string
	if len(photos) == limit {
		nextCursor = photos[len(photos)-1].FirestoreDocID
	}

	return photos, nextCursor, nil
}

func collectPhotos(iter *firestore.DocumentIterator) ([]models.Photo, error) {
	var photos []models.Photo
	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("firestore iterate: %w", err)
		}

		var p models.Photo
		if err := doc.DataTo(&p); err != nil {
			return nil, fmt.Errorf("firestore decode: %w", err)
		}
		p.FirestoreDocID = doc.Ref.ID
		photos = append(photos, p)
	}
	return photos, nil
}
