# ---------------------------------------------------------------------------
# Cloud Scheduler — Periodic jobs
# ---------------------------------------------------------------------------

# ── Lifecycle Sweep (daily at 2am UTC) ─────────────────────────────────────

resource "google_cloud_scheduler_job" "lifecycle_sweep" {
  project     = var.project_id
  region      = var.region
  name        = "cgs-lifecycle-sweep"
  description = "Daily sweep to transition photos through storage lifecycle tiers"
  schedule    = "0 2 * * *"
  time_zone   = "Etc/UTC"

  retry_config {
    retry_count          = 3
    min_backoff_duration = "30s"
    max_backoff_duration = "300s"
    max_doublings        = 2
  }

  http_target {
    http_method = "POST"
    uri         = "${var.api_service_url}/api/internal/lifecycle-sweep"

    oidc_token {
      service_account_email = var.scheduler_sa_email
      audience              = var.api_service_url
    }
  }
}

# ── Orphan Cleanup (weekly, Sundays at 3am UTC) ───────────────────────────

resource "google_cloud_scheduler_job" "orphan_cleanup" {
  project     = var.project_id
  region      = var.region
  name        = "cgs-orphan-cleanup"
  description = "Weekly cleanup of orphaned thumbnails and stale metadata"
  schedule    = "0 3 * * 0"
  time_zone   = "Etc/UTC"

  retry_config {
    retry_count          = 3
    min_backoff_duration = "30s"
    max_backoff_duration = "300s"
    max_doublings        = 2
  }

  http_target {
    http_method = "POST"
    uri         = "${var.api_service_url}/api/internal/orphan-cleanup"

    oidc_token {
      service_account_email = var.scheduler_sa_email
      audience              = var.api_service_url
    }
  }
}
