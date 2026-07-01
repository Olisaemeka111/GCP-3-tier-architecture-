output "instance_group" {
  description = "The managed instance group self-link (for load balancer backends)."
  value       = google_compute_region_instance_group_manager.this.instance_group
}

output "instance_group_manager_id" {
  description = "The instance group manager ID."
  value       = google_compute_region_instance_group_manager.this.id
}

output "health_check_id" {
  description = "The health check ID."
  value       = google_compute_health_check.this.id
}

output "instance_template_id" {
  description = "The instance template ID."
  value       = google_compute_instance_template.this.id
}
