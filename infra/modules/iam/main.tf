# ---------------------------------------------------------------------------
# IAM — Service accounts and bindings
# ---------------------------------------------------------------------------

# ── Service Accounts ────────────────────────────────────────────────────────

resource "google_service_account" "api" {
  project      = var.project_id
  account_id   = "cgs-api-sa"
  display_name = "CGS Photos API Service Account"
  description  = "Service account for the Cloud Run API service"
}

resource "google_service_account" "processing" {
  project      = var.project_id
  account_id   = "cgs-processing-sa"
  display_name = "CGS Photos Processing Service Account"
  description  = "Service account for the Cloud Run processing job"
}

resource "google_service_account" "proxy" {
  project      = var.project_id
  account_id   = "cgs-proxy-sa"
  display_name = "CGS Photos Image Proxy Service Account"
  description  = "Service account for the Cloud Run image proxy service"
}

resource "google_service_account" "eventrouter" {
  project      = var.project_id
  account_id   = "cgs-eventrouter-sa"
  display_name = "CGS Photos Event Router Service Account"
  description  = "Service account for Cloud Functions event routing"
}

# ── IAM Bindings ────────────────────────────────────────────────────────────

# API SA: Firestore read/write, Pub/Sub publish, GCS read/write, Cloud Run invoker
resource "google_project_iam_member" "api_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.api.email}"
}

resource "google_project_iam_member" "api_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.api.email}"
}

resource "google_project_iam_member" "api_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.api.email}"
}

resource "google_project_iam_member" "api_cloudtasks_enqueuer" {
  project = var.project_id
  role    = "roles/cloudtasks.enqueuer"
  member  = "serviceAccount:${google_service_account.api.email}"
}

# Processing SA: Firestore read/write, GCS read/write, Pub/Sub subscriber
resource "google_project_iam_member" "processing_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.processing.email}"
}

resource "google_project_iam_member" "processing_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.processing.email}"
}

resource "google_project_iam_member" "processing_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.processing.email}"
}

resource "google_project_iam_member" "processing_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.processing.email}"
}

# Proxy SA: GCS read-only
resource "google_project_iam_member" "proxy_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.proxy.email}"
}

# Event Router SA: Pub/Sub publish, Cloud Run invoker
resource "google_project_iam_member" "eventrouter_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.eventrouter.email}"
}

resource "google_project_iam_member" "eventrouter_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.eventrouter.email}"
}
