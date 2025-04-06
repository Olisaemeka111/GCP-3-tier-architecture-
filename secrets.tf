# Random password generation for database
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a Secret Manager secret for database password
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.environment}-db-password"
  project   = var.project_id

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    purpose     = "database"
  }

  replication {
    auto {
      customer_managed_encryption {
        kms_key_name = data.google_kms_crypto_key.secret_key.id
      }
    }
  }
}

# Store the database password in Secret Manager
resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# KMS key ring for encrypting secrets
data "google_kms_key_ring" "secrets" {
  name     = "dev-secrets-ring"
  location = "global"
  project  = var.project_id
}

# KMS key for encrypting secrets
data "google_kms_crypto_key" "secret_key" {
  name     = "dev-secret-key"
  key_ring = data.google_kms_key_ring.secrets.id
}

# Output the Secret Manager secret name (not the value) for reference
output "db_password_secret_name" {
  description = "The name of the Secret Manager secret containing the database password"
  value       = google_secret_manager_secret.db_password.name
} 