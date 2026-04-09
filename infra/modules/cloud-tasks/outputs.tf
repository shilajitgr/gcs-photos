output "lifecycle_queue_name" {
  description = "Name of the lifecycle transitions queue"
  value       = google_cloud_tasks_queue.lifecycle_transitions.name
}

output "batch_reprocess_queue_name" {
  description = "Name of the batch reprocess queue"
  value       = google_cloud_tasks_queue.batch_reprocess.name
}
