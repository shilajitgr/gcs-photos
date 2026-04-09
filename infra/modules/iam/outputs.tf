output "api_sa_email" {
  description = "API service account email"
  value       = google_service_account.api.email
}

output "processing_sa_email" {
  description = "Processing service account email"
  value       = google_service_account.processing.email
}

output "proxy_sa_email" {
  description = "Proxy service account email"
  value       = google_service_account.proxy.email
}

output "eventrouter_sa_email" {
  description = "Event router service account email"
  value       = google_service_account.eventrouter.email
}
