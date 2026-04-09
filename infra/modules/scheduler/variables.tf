variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "lifecycle_queue_name" {
  description = "Cloud Tasks queue name for lifecycle transitions"
  type        = string
}

variable "api_service_url" {
  description = "Cloud Run API service URL"
  type        = string
}

variable "scheduler_sa_email" {
  description = "Service account email for the scheduler to use"
  type        = string
}
