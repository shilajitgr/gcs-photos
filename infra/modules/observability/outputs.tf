output "uptime_check_id" {
  description = "Uptime check ID for the API health endpoint"
  value       = google_monitoring_uptime_check_config.api_health.uptime_check_id
}

output "processing_error_metric_name" {
  description = "Log-based metric name for processing errors"
  value       = google_logging_metric.processing_errors.name
}
