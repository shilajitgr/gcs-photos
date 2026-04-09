output "workload_identity_pool_id" {
  description = "Workload Identity Pool ID"
  value       = google_iam_workload_identity_pool.firebase.workload_identity_pool_id
}

output "workload_identity_pool_name" {
  description = "Workload Identity Pool full resource name"
  value       = google_iam_workload_identity_pool.firebase.name
}

output "workload_identity_provider_id" {
  description = "Workload Identity Provider ID"
  value       = google_iam_workload_identity_pool_provider.firebase.workload_identity_pool_provider_id
}

output "user_storage_sa_email" {
  description = "Service account email for user storage access"
  value       = google_service_account.user_storage_access.email
}
