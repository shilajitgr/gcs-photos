output "photo_uploads_topic_id" {
  description = "Photo uploads topic ID"
  value       = google_pubsub_topic.photo_uploads.id
}

output "photo_uploads_topic_name" {
  description = "Photo uploads topic name"
  value       = google_pubsub_topic.photo_uploads.name
}

output "dlq_topic_id" {
  description = "Dead letter topic ID"
  value       = google_pubsub_topic.photo_uploads_dlq.id
}

output "processing_subscription_name" {
  description = "Processing subscription name"
  value       = google_pubsub_subscription.processing.name
}

output "metadata_subscription_name" {
  description = "Metadata subscription name"
  value       = google_pubsub_subscription.metadata.name
}
