# ---------------------------------------------------------------------------
# CGS Photos — Root Terraform Module
# ---------------------------------------------------------------------------

locals {
  labels = {
    project     = "cgs-photos"
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ── Provider configuration ──────────────────────────────────────────────────

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ── Enable required GCP APIs ────────────────────────────────────────────────

resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "firestore.googleapis.com",
    "pubsub.googleapis.com",
    "cloudtasks.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "certificatemanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com",
    "identitytoolkit.googleapis.com",
    "firebase.googleapis.com",
    "cloudbuild.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# ── Module calls ────────────────────────────────────────────────────────────

module "iam" {
  source = "./modules/iam"

  project_id  = var.project_id
  environment = var.environment
}

module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_id = var.project_id
  region     = var.region
  labels     = local.labels

  depends_on = [google_project_service.apis]
}

module "firestore" {
  source = "./modules/firestore"

  project_id          = var.project_id
  region              = var.region
  firestore_location  = var.firestore_location
  labels              = local.labels

  depends_on = [google_project_service.apis]
}

module "pubsub" {
  source = "./modules/pubsub"

  project_id = var.project_id
  region     = var.region
  labels     = local.labels

  depends_on = [google_project_service.apis]
}

module "cloud_tasks" {
  source = "./modules/cloud-tasks"

  project_id = var.project_id
  region     = var.region

  depends_on = [google_project_service.apis]
}

module "cloud_run" {
  source = "./modules/cloud-run"

  project_id          = var.project_id
  region              = var.region
  environment         = var.environment
  labels              = local.labels
  api_image           = var.api_image
  processing_image    = var.processing_image
  proxy_image         = var.proxy_image
  api_sa_email        = module.iam.api_sa_email
  processing_sa_email = module.iam.processing_sa_email
  proxy_sa_email      = module.iam.proxy_sa_email

  depends_on = [google_project_service.apis]
}

module "networking" {
  source = "./modules/networking"

  project_id  = var.project_id
  region      = var.region
  domain_name = var.domain_name
  environment = var.environment
  labels      = local.labels

  api_service_name   = module.cloud_run.api_service_name
  proxy_service_name = module.cloud_run.proxy_service_name

  depends_on = [google_project_service.apis]
}

module "auth" {
  source = "./modules/auth"

  project_id  = var.project_id
  environment = var.environment

  depends_on = [google_project_service.apis]
}

module "scheduler" {
  source = "./modules/scheduler"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  lifecycle_queue_name = module.cloud_tasks.lifecycle_queue_name
  api_service_url      = module.cloud_run.api_service_url
  scheduler_sa_email   = module.iam.api_sa_email

  depends_on = [google_project_service.apis]
}

module "observability" {
  source = "./modules/observability"

  project_id         = var.project_id
  environment        = var.environment
  notification_email = var.notification_email
  api_service_name   = module.cloud_run.api_service_name
  domain_name        = var.domain_name

  depends_on = [google_project_service.apis]
}
