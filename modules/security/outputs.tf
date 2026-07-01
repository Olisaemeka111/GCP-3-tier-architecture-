output "key_ring_id" {
  description = "The KMS key ring ID."
  value       = google_kms_key_ring.this.id
}

output "disk_key_id" {
  description = "CMEK key ID for compute disks."
  value       = google_kms_crypto_key.disk.id
}

output "sql_key_id" {
  description = "CMEK key ID for Cloud SQL."
  value       = google_kms_crypto_key.sql.id
}

output "secret_key_id" {
  description = "CMEK key ID for Secret Manager."
  value       = google_kms_crypto_key.secret.id
}

output "storage_key_id" {
  description = "CMEK key ID for Cloud Storage."
  value       = google_kms_crypto_key.storage.id
}

output "frontend_sa_email" {
  description = "Frontend tier service account email."
  value       = google_service_account.frontend.email
}

output "backend_sa_email" {
  description = "Backend tier service account email."
  value       = google_service_account.backend.email
}

output "security_policy_id" {
  description = "Cloud Armor edge security policy ID (attach to backend services)."
  value       = google_compute_security_policy.edge.id
}

output "sql_key_iam_dependency" {
  description = "Dependency handle ensuring the SQL agent has CMEK access before DB creation."
  value       = google_kms_crypto_key_iam_member.sql.id
}

output "secret_key_iam_dependency" {
  description = "Dependency handle ensuring the Secret Manager agent has CMEK access."
  value       = google_kms_crypto_key_iam_member.secret.id
}
