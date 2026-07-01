###############################################################################
# Root input variables
###############################################################################

variable "project_id" {
  description = "The GCP project ID to deploy into."
  type        = string
}

variable "region" {
  description = "Primary GCP region."
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "Zones to distribute instances across (must be in var.region)."
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

# --- Networking ---
variable "vpc_name" {
  description = "Name of the VPC network."
  type        = string
  default     = "three-tier-vpc"
}

variable "subnet_cidrs" {
  description = "Per-tier subnet CIDR ranges."
  type        = map(string)
  default = {
    frontend = "10.0.1.0/24"
    backend  = "10.0.2.0/24"
    database = "10.0.3.0/24"
  }
}

variable "flow_logs_sampling" {
  description = "VPC flow-log sampling rate (0.0-1.0)."
  type        = number
  default     = 0.5
}

# --- Compute ---
variable "frontend_machine_type" {
  description = "Frontend instance machine type."
  type        = string
  default     = "e2-medium"
}

variable "backend_machine_type" {
  description = "Backend instance machine type."
  type        = string
  default     = "e2-medium"
}

variable "frontend_scaling" {
  description = "Frontend autoscaling configuration."
  type = object({
    min_replicas           = number
    max_replicas           = number
    cooldown_period        = number
    target_cpu_utilization = number
  })
  default = {
    min_replicas           = 2
    max_replicas           = 10
    cooldown_period        = 60
    target_cpu_utilization = 0.7
  }
}

variable "backend_scaling" {
  description = "Backend autoscaling configuration."
  type = object({
    min_replicas           = number
    max_replicas           = number
    cooldown_period        = number
    target_cpu_utilization = number
  })
  default = {
    min_replicas           = 2
    max_replicas           = 8
    cooldown_period        = 60
    target_cpu_utilization = 0.7
  }
}

# --- Load balancer / TLS ---
variable "ssl_domains" {
  description = "Domains for the Google-managed SSL certificate. Empty => HTTP-only (non-prod)."
  type        = list(string)
  default     = []
}

variable "enable_cdn" {
  description = "Enable Cloud CDN on the external load balancer."
  type        = bool
  default     = true
}

# --- Database ---
variable "db_version" {
  description = "Cloud SQL database version."
  type        = string
  default     = "MYSQL_8_0"
}

variable "db_tier" {
  description = "Cloud SQL machine tier."
  type        = string
  default     = "db-custom-2-7680"
}

variable "db_availability_type" {
  description = "Cloud SQL availability (REGIONAL for HA, ZONAL otherwise)."
  type        = string
  default     = "REGIONAL"
}

variable "db_deletion_protection" {
  description = "Protect the Cloud SQL instance from deletion."
  type        = bool
  default     = true
}

variable "read_replica_count" {
  description = "Number of Cloud SQL read replicas."
  type        = number
  default     = 0
}

# --- Monitoring ---
variable "alert_email" {
  description = "Email address for monitoring alerts."
  type        = string
}

variable "log_retention_days" {
  description = "Retention (days) for the audit log archive bucket."
  type        = number
  default     = 365
}

# --- Security toggles ---
variable "enable_confidential_vm" {
  description = "Enable Confidential VMs (requires a compatible machine type such as n2d)."
  type        = bool
  default     = false
}

variable "key_rotation_period" {
  description = "CMEK rotation period (seconds string)."
  type        = string
  default     = "7776000s"
}
