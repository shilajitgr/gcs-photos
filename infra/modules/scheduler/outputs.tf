output "lifecycle_sweep_job_name" {
  description = "Name of the lifecycle sweep scheduler job"
  value       = google_cloud_scheduler_job.lifecycle_sweep.name
}

output "orphan_cleanup_job_name" {
  description = "Name of the orphan cleanup scheduler job"
  value       = google_cloud_scheduler_job.orphan_cleanup.name
}
