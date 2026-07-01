output "instance_name" {
  description = "The Cloud SQL instance name."
  value       = google_sql_database_instance.primary.name
}

output "instance_connection_name" {
  description = "The Cloud SQL connection name (for the Auth Proxy)."
  value       = google_sql_database_instance.primary.connection_name
}

output "private_ip_address" {
  description = "The private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.primary.private_ip_address
}

output "database_name" {
  description = "The application database name."
  value       = google_sql_database.app.name
}

output "database_user" {
  description = "The application database user."
  value       = google_sql_user.app.name
}

output "password_secret_id" {
  description = "The Secret Manager secret ID holding the DB password (value not exposed)."
  value       = google_secret_manager_secret.db_password.secret_id
}
