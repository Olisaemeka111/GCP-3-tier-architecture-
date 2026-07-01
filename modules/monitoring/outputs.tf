output "notification_channel_id" {
  description = "The email notification channel ID."
  value       = google_monitoring_notification_channel.email.id
}

output "alert_policy_id" {
  description = "The high-CPU alert policy ID."
  value       = google_monitoring_alert_policy.cpu_usage.id
}

output "log_archive_bucket" {
  description = "The audit log archive bucket name."
  value       = google_storage_bucket.log_archive.name
}
