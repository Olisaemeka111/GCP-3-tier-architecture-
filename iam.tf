# KMS Key data source
data "google_kms_crypto_key" "secret_key" {
  name     = var.kms_key_name
  key_ring = var.kms_key_ring
}

# Frontend service account
resource "google_service_account" "frontend_sa" {
  project      = data.google_project.project.project_id
  account_id   = "${var.environment}-frontend-sa"
  display_name = "Frontend Service Account for ${var.environment}"
}

# Backend service account
resource "google_service_account" "backend_sa" {
  project      = data.google_project.project.project_id
  account_id   = "${var.environment}-backend-sa"
  display_name = "Backend Service Account for ${var.environment}"
}

# Frontend service account roles
resource "google_project_iam_member" "frontend_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer"
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.frontend_sa.email}"
}

# Backend service account roles
resource "google_project_iam_member" "backend_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/cloudsql.client"
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.backend_sa.email}"
}

# Secret Manager IAM
resource "google_kms_crypto_key_iam_member" "secret_manager_crypto_key" {
  crypto_key_id = data.google_kms_crypto_key.secret_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.secret_manager.email}"
  depends_on    = [time_sleep.wait_for_secret_manager_identity]
} 