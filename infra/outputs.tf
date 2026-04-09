output "api_url" {
  description = "Cloud Run API service URL"
  value       = module.cloud_run.api_service_url
}

output "proxy_url" {
  description = "Cloud Run image proxy service URL"
  value       = module.cloud_run.proxy_service_url
}

output "load_balancer_ip" {
  description = "Global external IP address for the load balancer"
  value       = module.networking.load_balancer_ip
}

output "artifact_registry_url" {
  description = "Artifact Registry Docker repository URL"
  value       = module.artifact_registry.repository_url
}

output "firestore_database" {
  description = "Firestore database name"
  value       = module.firestore.database_name
}

output "api_service_account" {
  description = "Email of the API service account"
  value       = module.iam.api_sa_email
}

output "processing_service_account" {
  description = "Email of the processing service account"
  value       = module.iam.processing_sa_email
}

output "proxy_service_account" {
  description = "Email of the proxy service account"
  value       = module.iam.proxy_sa_email
}
