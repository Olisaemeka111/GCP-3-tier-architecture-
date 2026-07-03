variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the regional instance group."
  type        = string
}

variable "zones" {
  description = "Zones to distribute instances across."
  type        = list(string)
}

variable "environment" {
  description = "Environment name used as a resource prefix."
  type        = string
}

variable "tier_name" {
  description = "Logical tier name (e.g. frontend, backend)."
  type        = string
}

variable "machine_type" {
  description = "Machine type for the instances."
  type        = string
  default     = "e2-medium"
}

variable "source_image" {
  description = "Boot disk source image."
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 20
}

variable "disk_kms_key_id" {
  description = "CMEK key ID used to encrypt the boot disk."
  type        = string
}

variable "network" {
  description = "VPC network self-link or name."
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self-link or name for this tier."
  type        = string
}

variable "service_account_email" {
  description = "Service account attached to the instances."
  type        = string
}

variable "service_account_scopes" {
  description = "OAuth scopes. Prefer cloud-platform + fine-grained IAM roles over legacy scopes."
  type        = list(string)
  default     = ["cloud-platform"]
}

variable "network_tags" {
  description = "Network tags applied to instances (drive firewall rules)."
  type        = list(string)
}

variable "startup_script" {
  description = "Startup script contents."
  type        = string
  default     = ""
}

variable "named_ports" {
  description = "Named ports exposed by the instance group."
  type = list(object({
    name = string
    port = number
  }))
}

variable "health_check_port" {
  description = "TCP/HTTP port used for health checks."
  type        = number
}

variable "health_check_request_path" {
  description = "HTTP request path for health checks."
  type        = string
  default     = "/"
}

variable "health_check_initial_delay_sec" {
  description = "Grace period before auto-healing acts on an unhealthy instance (allow slow first-boot provisioning)."
  type        = number
  default     = 300
}

variable "autoscaling" {
  description = "Autoscaling configuration."
  type = object({
    min_replicas           = number
    max_replicas           = number
    cooldown_period        = number
    target_cpu_utilization = number
  })
}

variable "enable_confidential_vm" {
  description = "Enable Confidential VM (AMD SEV). Requires a supported machine type (e.g. n2d)."
  type        = bool
  default     = false
}
