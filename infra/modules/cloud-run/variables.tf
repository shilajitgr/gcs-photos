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

variable "labels" {
  description = "Common labels"
  type        = map(string)
  default     = {}
}

variable "api_image" {
  description = "Container image for the API service"
  type        = string
}

variable "processing_image" {
  description = "Container image for the processing job"
  type        = string
}

variable "proxy_image" {
  description = "Container image for the image proxy service"
  type        = string
}

variable "api_sa_email" {
  description = "Service account email for the API service"
  type        = string
}

variable "processing_sa_email" {
  description = "Service account email for the processing job"
  type        = string
}

variable "proxy_sa_email" {
  description = "Service account email for the proxy service"
  type        = string
}
