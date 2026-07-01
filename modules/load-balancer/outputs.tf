output "frontend_ip" {
  description = "The external IP address of the frontend load balancer."
  value       = google_compute_global_address.frontend.address
}

output "frontend_backend_service_id" {
  description = "The external backend service ID."
  value       = google_compute_backend_service.frontend.id
}

output "backend_internal_ip" {
  description = "The internal load balancer IP for the backend tier."
  value       = google_compute_forwarding_rule.backend_internal.ip_address
}

output "https_enabled" {
  description = "Whether the HTTPS listener (managed certificate) was provisioned."
  value       = local.https_enabled
}
