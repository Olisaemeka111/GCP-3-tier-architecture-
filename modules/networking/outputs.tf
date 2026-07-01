output "vpc_id" {
  description = "The VPC self-link/ID."
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The VPC name."
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The VPC self link."
  value       = google_compute_network.vpc.self_link
}

output "subnet_ids" {
  description = "Map of tier name to subnet ID."
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.id }
}

output "subnet_self_links" {
  description = "Map of tier name to subnet self link."
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.self_link }
}

output "subnet_names" {
  description = "Map of tier name to subnet name."
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.name }
}

output "private_vpc_connection_id" {
  description = "The private services access peering connection ID (dependency handle for Cloud SQL)."
  value       = google_service_networking_connection.private_vpc_connection.id
}
