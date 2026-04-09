variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "notification_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = ""
}

variable "api_service_name" {
  description = "Name of the Cloud Run API service"
  type        = string
}

variable "domain_name" {
  description = "Domain name for uptime checks"
  type        = string
}
