variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the managed SSL certificate"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "labels" {
  description = "Common labels"
  type        = map(string)
  default     = {}
}

variable "api_service_name" {
  description = "Name of the Cloud Run API service"
  type        = string
}

variable "proxy_service_name" {
  description = "Name of the Cloud Run image proxy service"
  type        = string
}
