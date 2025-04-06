# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.id }
}

# Load Balancer Outputs
output "frontend_lb_ip" {
  description = "The IP address of the frontend load balancer"
  value       = google_compute_global_address.frontend.address
}

# Service Account Outputs
output "frontend_sa_email" {
  description = "Email address of the frontend service account"
  value       = google_service_account.frontend_sa.email
}

output "backend_sa_email" {
  description = "Email address of the backend service account"
  value       = google_service_account.backend_sa.email
}

# Instance Group Outputs
output "frontend_instance_group" {
  description = "The instance group URL of the frontend instances"
  value       = google_compute_region_instance_group_manager.frontend.instance_group
}

output "backend_instance_group" {
  description = "The instance group URL of the backend instances"
  value       = google_compute_region_instance_group_manager.backend.instance_group
} 