output "api_service_url" {
  description = "URL of the API Cloud Run service"
  value       = google_cloud_run_v2_service.api.uri
}

output "api_service_name" {
  description = "Name of the API Cloud Run service"
  value       = google_cloud_run_v2_service.api.name
}

output "proxy_service_url" {
  description = "URL of the image proxy Cloud Run service"
  value       = google_cloud_run_v2_service.proxy.uri
}

output "proxy_service_name" {
  description = "Name of the image proxy Cloud Run service"
  value       = google_cloud_run_v2_service.proxy.name
}

output "processing_job_name" {
  description = "Name of the processing Cloud Run job"
  value       = google_cloud_run_v2_job.processing.name
}
