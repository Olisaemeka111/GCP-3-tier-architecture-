variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the internal load balancer."
  type        = string
}

variable "environment" {
  description = "Environment name used as a resource prefix."
  type        = string
}

# --- Frontend (external) ---
variable "frontend_instance_group" {
  description = "Frontend managed instance group self-link."
  type        = string
}

variable "frontend_health_check_id" {
  description = "Frontend health check ID."
  type        = string
}

variable "security_policy_id" {
  description = "Cloud Armor security policy to attach to the external backend service."
  type        = string
}

variable "enable_cdn" {
  description = "Enable Cloud CDN on the external backend service."
  type        = bool
  default     = true
}

variable "ssl_domains" {
  description = "Domains for a Google-managed SSL certificate. If empty, an HTTP-only LB is created (non-prod)."
  type        = list(string)
  default     = []
}

# --- Backend (internal) ---
variable "backend_instance_group" {
  description = "Backend managed instance group self-link."
  type        = string
}

variable "backend_health_check_id" {
  description = "Backend health check ID."
  type        = string
}

variable "backend_network" {
  description = "VPC network self-link for the internal LB."
  type        = string
}

variable "backend_subnetwork" {
  description = "Subnetwork self-link for the internal LB forwarding rule."
  type        = string
}

variable "backend_port" {
  description = "Backend service port for the internal LB."
  type        = number
  default     = 8080
}
