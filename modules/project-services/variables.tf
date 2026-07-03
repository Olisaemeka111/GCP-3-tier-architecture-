variable "project_id" {
  description = "The GCP project ID in which to enable services."
  type        = string
}

variable "activate_apis" {
  description = "List of Google Cloud APIs (service names) to enable on the project."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "storage.googleapis.com",
    "cloudasset.googleapis.com",
    "securitycenter.googleapis.com",
    "accesscontextmanager.googleapis.com",
    "osconfig.googleapis.com",
  ]
}

variable "disable_services_on_destroy" {
  description = "Whether to disable the services when the resource is destroyed."
  type        = bool
  default     = false
}

variable "api_activation_wait_seconds" {
  description = "Seconds to wait after enabling APIs so downstream resources see propagation."
  type        = string
  default     = "60s"
}
