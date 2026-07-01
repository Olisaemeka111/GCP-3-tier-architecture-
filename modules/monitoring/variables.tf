variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the log bucket."
  type        = string
}

variable "environment" {
  description = "Environment name used as a resource prefix."
  type        = string
}

variable "alert_email" {
  description = "Email address for alert notifications."
  type        = string
}

variable "cpu_threshold" {
  description = "CPU utilization threshold (0-1) for the high-CPU alert."
  type        = number
  default     = 0.8
}

variable "log_storage_kms_key_id" {
  description = "CMEK key ID for the log archive bucket."
  type        = string
}

variable "log_retention_days" {
  description = "Retention (days) for the audit log archive bucket."
  type        = number
  default     = 365
}

variable "enable_data_access_audit_logs" {
  description = "Enable DATA_READ/DATA_WRITE audit logs for all services."
  type        = bool
  default     = true
}
