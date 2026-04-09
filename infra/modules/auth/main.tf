# ---------------------------------------------------------------------------
# Auth — Workload Identity Federation for Firebase token exchange
# ---------------------------------------------------------------------------

# ── Workload Identity Pool ─────────────────────────────────────────────────

resource "google_iam_workload_identity_pool" "firebase" {
  provider                  = google-beta
  project                   = var.project_id
  workload_identity_pool_id = "cgs-firebase-pool"
  display_name              = "CGS Photos Firebase Pool"
  description               = "Workload Identity Pool for Firebase Auth token exchange"
}

# ── Workload Identity Provider ─────────────────────────────────────────────

resource "google_iam_workload_identity_pool_provider" "firebase" {
  provider                           = google-beta
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.firebase.workload_identity_pool_id
  workload_identity_pool_provider_id = "cgs-firebase-provider"
  display_name                       = "CGS Photos Firebase Provider"
  description                        = "OIDC provider for Firebase Auth tokens"

  oidc {
    issuer_uri = "https://securetoken.google.com/${var.project_id}"
  }

  attribute_mapping = {
    "google.subject"  = "assertion.sub"
    "attribute.uid"   = "assertion.sub"
    "attribute.email" = "assertion.email"
  }

  # Only accept tokens issued by our project
  attribute_condition = "assertion.aud == '${var.project_id}'"
}

# ── Service Account for GCS Bucket Access ──────────────────────────────────

resource "google_service_account" "user_storage_access" {
  project      = var.project_id
  account_id   = "cgs-user-storage-sa"
  display_name = "CGS Photos User Storage Access"
  description  = "Service account used via WIF for scoped GCS bucket access"
}

resource "google_project_iam_member" "user_storage_access" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.user_storage_access.email}"
}

# Allow the WIF pool to impersonate this service account
resource "google_service_account_iam_member" "wif_impersonation" {
  service_account_id = google_service_account.user_storage_access.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.firebase.name}/*"
}
