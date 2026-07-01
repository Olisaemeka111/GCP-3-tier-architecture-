###############################################################################
# Remote state backend (GCS).
# The bucket must exist beforehand and should have versioning enabled and CMEK.
# Initialize with per-environment config, e.g.:
#   terraform init -backend-config=environments/prod.gcs.tfbackend
###############################################################################
terraform {
  backend "gcs" {
    # bucket = "my-org-terraform-state"      # provide via -backend-config
    # prefix = "three-tier/prod"             # provide via -backend-config
  }
}
