variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "gcs-p-492809"
}

variable "region" {
  description = "Primary GCP region"
  type        = string
  default     = "asia-south1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod"
  }
}

variable "domain_name" {
  description = "Domain name for the application (e.g. photos.example.com). Leave empty to skip SSL/CDN provisioning."
  type        = string
  default     = ""
}

variable "api_image" {
  description = "Container image for the API service (e.g. us-central1-docker.pkg.dev/project/repo/api:latest)"
  type        = string
}

variable "processing_image" {
  description = "Container image for the processing job (e.g. us-central1-docker.pkg.dev/project/repo/processing:latest)"
  type        = string
}

variable "proxy_image" {
  description = "Container image for the image proxy service (e.g. us-central1-docker.pkg.dev/project/repo/proxy:latest)"
  type        = string
}

variable "firestore_location" {
  description = "Firestore database location (cannot change after creation)"
  type        = string
  default     = "us-central1"
}

variable "notification_email" {
  description = "Email address for monitoring alert notifications"
  type        = string
  default     = ""
}
