# ---------------------------------------------------------------------------
# Firestore — Database and indexes
# ---------------------------------------------------------------------------

resource "google_firestore_database" "main" {
  provider    = google-beta
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  concurrency_mode            = "OPTIMISTIC"
  app_engine_integration_mode = "DISABLED"
}

# ── Composite Indexes ───────────────────────────────────────────────────────

# Query: photos by user, ordered by date_taken
resource "google_firestore_index" "photos_user_date" {
  project    = var.project_id
  database   = google_firestore_database.main.name
  collection = "photos"

  fields {
    field_path = "user_id"
    order      = "ASCENDING"
  }

  fields {
    field_path = "date_taken"
    order      = "DESCENDING"
  }
}

# Query: photos by user and backup_status, ordered by date_taken
resource "google_firestore_index" "photos_user_backup_date" {
  project    = var.project_id
  database   = google_firestore_database.main.name
  collection = "photos"

  fields {
    field_path = "user_id"
    order      = "ASCENDING"
  }

  fields {
    field_path = "backup_status"
    order      = "ASCENDING"
  }

  fields {
    field_path = "date_taken"
    order      = "DESCENDING"
  }
}

# Query: photos by user, ordered by updated_at (for sync)
resource "google_firestore_index" "photos_user_updated" {
  project    = var.project_id
  database   = google_firestore_database.main.name
  collection = "photos"

  fields {
    field_path = "user_id"
    order      = "ASCENDING"
  }

  fields {
    field_path = "updated_at"
    order      = "ASCENDING"
  }
}

# Query: photos by content_hash (dedup lookup)
resource "google_firestore_index" "photos_user_content_hash" {
  project    = var.project_id
  database   = google_firestore_database.main.name
  collection = "photos"

  fields {
    field_path = "user_id"
    order      = "ASCENDING"
  }

  fields {
    field_path = "content_hash"
    order      = "ASCENDING"
  }
}
