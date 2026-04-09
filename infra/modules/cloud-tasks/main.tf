# ---------------------------------------------------------------------------
# Cloud Tasks — Rate-limited work queues
# ---------------------------------------------------------------------------

resource "google_cloud_tasks_queue" "lifecycle_transitions" {
  project  = var.project_id
  location = var.region
  name     = "lifecycle-transitions"

  rate_limits {
    max_dispatches_per_second = 10
    max_concurrent_dispatches = 20
  }

  retry_config {
    max_attempts       = 5
    min_backoff        = "5s"
    max_backoff        = "300s"
    max_doublings      = 4
    max_retry_duration = "3600s"
  }
}

resource "google_cloud_tasks_queue" "batch_reprocess" {
  project  = var.project_id
  location = var.region
  name     = "batch-reprocess"

  rate_limits {
    max_dispatches_per_second = 5
    max_concurrent_dispatches = 10
  }

  retry_config {
    max_attempts       = 3
    min_backoff        = "10s"
    max_backoff        = "600s"
    max_doublings      = 3
    max_retry_duration = "7200s"
  }
}
