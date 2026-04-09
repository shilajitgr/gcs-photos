package services

import (
	"context"
	"encoding/json"
	"fmt"

	"cloud.google.com/go/pubsub"
)

// PubSubService publishes events to Pub/Sub topics.
type PubSubService struct {
	client *pubsub.Client
	topic  *pubsub.Topic
}

// NewPubSubService creates a new PubSubService for the given topic.
func NewPubSubService(client *pubsub.Client, topicID string) *PubSubService {
	return &PubSubService{
		client: client,
		topic:  client.Topic(topicID),
	}
}

// UploadEvent represents a photo upload event published to Pub/Sub.
type UploadEvent struct {
	ImageUID    string `json:"imageUID"`
	UserID      string `json:"userID"`
	Bucket      string `json:"bucket"`
	ObjectPath  string `json:"objectPath"`
	ContentType string `json:"contentType"`
}

// PublishUploadEvent publishes a photo upload event.
func (s *PubSubService) PublishUploadEvent(ctx context.Context, event UploadEvent) error {
	data, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("pubsub marshal event: %w", err)
	}

	result := s.topic.Publish(ctx, &pubsub.Message{
		Data: data,
		Attributes: map[string]string{
			"eventType": "photo.uploaded",
			"userID":    event.UserID,
		},
	})

	if _, err := result.Get(ctx); err != nil {
		return fmt.Errorf("pubsub publish: %w", err)
	}

	return nil
}

// Close stops the topic and releases resources.
func (s *PubSubService) Close() {
	s.topic.Stop()
}
