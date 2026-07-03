###############################################################################
# Root outputs
###############################################################################

output "vpc_id" {
  description = "The VPC network ID."
  value       = module.networking.vpc_id
}

output "subnet_ids" {
  description = "Map of tier name to subnet ID."
  value       = module.networking.subnet_ids
}

output "frontend_lb_ip" {
  description = "The public IP of the frontend load balancer."
  value       = module.load_balancer.frontend_ip
}

output "backend_internal_ip" {
  description = "The internal IP of the backend load balancer."
  value       = module.load_balancer.backend_internal_ip
}

output "https_enabled" {
  description = "Whether HTTPS (managed certificate) is provisioned."
  value       = module.load_balancer.https_enabled
}

output "frontend_sa_email" {
  description = "Frontend service account email."
  value       = module.security.frontend_sa_email
}

output "backend_sa_email" {
  description = "Backend service account email."
  value       = module.security.backend_sa_email
}

output "cloud_armor_policy_id" {
  description = "Cloud Armor security policy ID."
  value       = module.security.security_policy_id
}

output "db_instance_connection_name" {
  description = "Cloud SQL connection name for the Auth Proxy."
  value       = module.database.instance_connection_name
}

output "db_private_ip" {
  description = "Cloud SQL private IP address."
  value       = module.database.private_ip_address
}

output "db_password_secret_id" {
  description = "Secret Manager secret ID holding the DB password (value not exposed)."
  value       = module.database.password_secret_id
}

output "audit_log_bucket" {
  description = "Centralized audit log archive bucket."
  value       = module.monitoring.log_archive_bucket
}

output "game_server_url" {
  description = "WorkAdventure URL (if the game server is deployed)."
  value       = var.enable_game_server ? module.game_server[0].url : null
}

output "game_server_ip" {
  description = "WorkAdventure public IP (if deployed)."
  value       = var.enable_game_server ? module.game_server[0].public_ip : null
}
