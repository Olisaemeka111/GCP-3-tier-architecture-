variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the static IP."
  type        = string
}

variable "zone" {
  description = "Zone for the game server instance."
  type        = string
}

variable "environment" {
  description = "Environment name used as a resource prefix."
  type        = string
}

variable "network" {
  description = "VPC network self-link."
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self-link for the instance."
  type        = string
}

variable "machine_type" {
  description = "Machine type (WorkAdventure needs >= 2 vCPU / 4 GB; 8 GB recommended)."
  type        = string
  default     = "e2-standard-2"
}

variable "source_image" {
  description = "Boot disk image."
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "disk_size_gb" {
  description = "Boot disk size (WorkAdventure images need headroom)."
  type        = number
  default     = 30
}

variable "disk_kms_key_id" {
  description = "CMEK key for the boot disk."
  type        = string
}

variable "startup_script" {
  description = "Startup script contents."
  type        = string
}

variable "acme_email" {
  description = "Email used by Let's Encrypt for certificate notifications."
  type        = string
}

variable "workadventure_version" {
  description = "WorkAdventure image tag to deploy."
  type        = string
  default     = "master"
}

variable "ssh_source_ranges" {
  description = "Source ranges allowed to SSH (IAP range by default)."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

variable "additional_web_ports" {
  description = "Extra TCP ports to open from the internet (e.g. a second app's port). Use sparingly."
  type        = list(string)
  default     = []
}
