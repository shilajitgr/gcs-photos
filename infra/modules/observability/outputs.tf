output "uptime_check_id" {
  description = "Uptime check ID for the API health endpoint"
  value       = var.domain_name != "" ? google_monitoring_uptime_check_config.api_health[0].uptime_check_id : ""
}

output "processing_error_metric_name" {
  description = "Log-based metric name for processing errors"
  value       = google_logging_metric.processing_errors.name
}
