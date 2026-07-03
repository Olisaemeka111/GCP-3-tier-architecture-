variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the KMS key ring (must match the regional resources it encrypts)."
  type        = string
}

variable "environment" {
  description = "Environment name used as a resource prefix."
  type        = string
}

variable "key_ring_name" {
  description = "Name of the KMS key ring created by this module."
  type        = string
  default     = "three-tier-keyring"
}

variable "key_rotation_period" {
  description = "Rotation period for CMEK keys (seconds string, e.g. 7776000s = 90 days)."
  type        = string
  default     = "7776000s"
}

variable "frontend_sa_roles" {
  description = "Project IAM roles granted to the frontend service account (least privilege)."
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
}

variable "backend_sa_roles" {
  description = "Project IAM roles granted to the backend service account (least privilege)."
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
  ]
}

variable "armor_rate_limit_threshold" {
  description = "Requests per interval per client before rate-limit throttling engages."
  type        = number
  default     = 100
}

variable "armor_rate_limit_interval_sec" {
  description = "Rate-limit interval in seconds."
  type        = number
  default     = 60
}

variable "enable_adaptive_protection" {
  description = "Enable Cloud Armor Adaptive Protection (layer 7 DDoS ML defense)."
  type        = bool
  default     = true
}

variable "enable_cloud_armor" {
  description = "Create the Cloud Armor security policy. Requires SECURITY_POLICIES quota (0 by default on new projects). Set false to skip it entirely."
  type        = bool
  default     = true
}

variable "enable_cloud_armor_advanced" {
  description = "Enable Cloud Armor advanced rules (OWASP WAF, rate limiting, adaptive DDoS). Requires Managed Protection Plus / advanced-rule quota. Set false for projects without it."
  type        = bool
  default     = true
}

variable "waf_sensitivity" {
  description = "OWASP CRS preconfigured WAF sensitivity level (1-4)."
  type        = number
  default     = 1
}

variable "depends_on_id" {
  description = "Opaque dependency handle (project-services readiness)."
  type        = string
  default     = ""
}
