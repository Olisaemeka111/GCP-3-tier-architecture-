# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",              # Compute Engine API
    "servicenetworking.googleapis.com",    # Service Networking API
    "sqladmin.googleapis.com",             # Cloud SQL Admin API
    "monitoring.googleapis.com",           # Cloud Monitoring API
    "logging.googleapis.com",              # Cloud Logging API
    "cloudresourcemanager.googleapis.com", # Cloud Resource Manager API
    "iam.googleapis.com",                  # Identity and Access Management API
    "secretmanager.googleapis.com",        # Secret Manager API
    "cloudbuild.googleapis.com",           # Cloud Build API
    "containerregistry.googleapis.com",    # Container Registry API
    "cloudkms.googleapis.com"              # Cloud KMS API
  ])

  project = data.google_project.project.project_id
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = false
}

# Wait for API enablement to complete
resource "time_sleep" "wait_for_apis" {
  depends_on      = [google_project_service.required_apis]
  create_duration = "60s"
}

# Create Secret Manager service identity
resource "google_project_service_identity" "secret_manager" {
  provider = google-beta
  project  = data.google_project.project.project_id
  service  = "secretmanager.googleapis.com"
  depends_on = [time_sleep.wait_for_apis]
}

# Wait for Secret Manager identity creation
resource "time_sleep" "wait_for_secret_manager_identity" {
  depends_on = [google_project_service_identity.secret_manager]
  create_duration = "30s"
} 