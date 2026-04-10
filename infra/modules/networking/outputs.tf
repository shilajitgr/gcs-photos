output "load_balancer_ip" {
  description = "Global external IP address of the load balancer"
  value       = google_compute_global_address.default.address
}

output "ssl_certificate_name" {
  description = "Managed SSL certificate name"
  value       = var.domain_name != "" ? google_compute_managed_ssl_certificate.default[0].name : ""
}

output "security_policy_name" {
  description = "Cloud Armor security policy name"
  value       = google_compute_security_policy.default.name
}
