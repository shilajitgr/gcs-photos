# GCS remote state backend.
# Configure the bucket via:
#   terraform init -backend-config="bucket=<YOUR_STATE_BUCKET>"
terraform {
  backend "gcs" {
    prefix = "terraform/state"
  }
}
