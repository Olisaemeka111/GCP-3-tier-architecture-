output "enabled_apis" {
  description = "The set of APIs that were enabled by this module."
  value       = [for s in google_project_service.this : s.service]
}

output "apis_ready_id" {
  description = "Dependency handle that is only resolved once APIs have propagated."
  value       = time_sleep.wait_for_apis.id
}
