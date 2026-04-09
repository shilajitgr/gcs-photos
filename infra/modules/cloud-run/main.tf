# ---------------------------------------------------------------------------
# Cloud Run — Services and Jobs
# ---------------------------------------------------------------------------

# ── API Service ─────────────────────────────────────────────────────────────

resource "google_cloud_run_v2_service" "api" {
  name     = "cgs-api"
  location = var.region
  project  = var.project_id

  labels = var.labels

  template {
    service_account = var.api_sa_email

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }

    containers {
      image = var.api_image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }

      startup_probe {
        http_get {
          path = "/healthz"
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/healthz"
        }
        period_seconds = 30
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# Allow unauthenticated access (auth handled at application layer via Firebase tokens)
resource "google_cloud_run_v2_service_iam_member" "api_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ── Image Proxy Service ─────────────────────────────────────────────────────

resource "google_cloud_run_v2_service" "proxy" {
  name     = "cgs-image-proxy"
  location = var.region
  project  = var.project_id

  labels = var.labels

  template {
    service_account = var.proxy_sa_email

    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    containers {
      image = var.proxy_image

      resources {
        limits = {
          cpu    = "2"
          memory = "1Gi"
        }
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }

      startup_probe {
        http_get {
          path = "/healthz"
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

resource "google_cloud_run_v2_service_iam_member" "proxy_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.proxy.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ── Processing Job ──────────────────────────────────────────────────────────

resource "google_cloud_run_v2_job" "processing" {
  name     = "cgs-processing"
  location = var.region
  project  = var.project_id

  labels = var.labels

  template {
    parallelism = 10
    task_count  = 10

    template {
      service_account = var.processing_sa_email
      timeout         = "86400s" # 24 hours
      max_retries     = 3

      containers {
        image = var.processing_image

        resources {
          limits = {
            cpu    = "4"
            memory = "4Gi"
          }
        }

        env {
          name  = "ENVIRONMENT"
          value = var.environment
        }

        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
      }
    }
  }
}
