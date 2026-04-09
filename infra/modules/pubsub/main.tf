# ---------------------------------------------------------------------------
# Pub/Sub — Topics, subscriptions, dead-letter
# ---------------------------------------------------------------------------

# ── Dead Letter Topic ───────────────────────────────────────────────────────

resource "google_pubsub_topic" "photo_uploads_dlq" {
  project = var.project_id
  name    = "photo-uploads-dlq"
  labels  = var.labels

  message_retention_duration = "604800s" # 7 days
}

resource "google_pubsub_subscription" "dlq_sub" {
  project = var.project_id
  name    = "photo-uploads-dlq-sub"
  topic   = google_pubsub_topic.photo_uploads_dlq.id

  # Keep DLQ messages for 7 days for inspection
  message_retention_duration = "604800s"
  retain_acked_messages      = true
  ack_deadline_seconds       = 60

  expiration_policy {
    ttl = "" # never expires
  }
}

# ── Main Upload Topic ──────────────────────────────────────────────────────

resource "google_pubsub_topic" "photo_uploads" {
  project = var.project_id
  name    = "photo-uploads"
  labels  = var.labels

  message_retention_duration = "86400s" # 1 day
}

# ── Processing Subscription (fan-out to Cloud Run Jobs) ─────────────────────

resource "google_pubsub_subscription" "processing" {
  project = var.project_id
  name    = "processing-sub"
  topic   = google_pubsub_topic.photo_uploads.id

  ack_deadline_seconds       = 600 # 10 min — processing is long-running
  message_retention_duration = "86400s"

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.photo_uploads_dlq.id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  expiration_policy {
    ttl = "" # never expires
  }
}

# ── Metadata Subscription (batched Firestore writes) ───────────────────────

resource "google_pubsub_subscription" "metadata" {
  project = var.project_id
  name    = "metadata-sub"
  topic   = google_pubsub_topic.photo_uploads.id

  ack_deadline_seconds       = 60
  message_retention_duration = "86400s"

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.photo_uploads_dlq.id
    max_delivery_attempts = 10
  }

  retry_policy {
    minimum_backoff = "5s"
    maximum_backoff = "300s"
  }

  expiration_policy {
    ttl = "" # never expires
  }
}
