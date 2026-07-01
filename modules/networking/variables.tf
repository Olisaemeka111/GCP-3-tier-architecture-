variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for regional networking resources (subnets, router, NAT)."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod) used as a resource prefix."
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC network."
  type        = string
  default     = "three-tier-vpc"
}

variable "subnet_cidrs" {
  description = "Map of tier name to primary CIDR range for the subnet."
  type        = map(string)
  default = {
    frontend = "10.0.1.0/24"
    backend  = "10.0.2.0/24"
    database = "10.0.3.0/24"
  }
}

variable "flow_logs_sampling" {
  description = "VPC flow log sampling rate (0.0 - 1.0). 1.0 = all flows (recommended for prod audit)."
  type        = number
  default     = 0.5
}

variable "iap_source_range" {
  description = "Google IAP TCP forwarding source range for SSH via IAP."
  type        = string
  default     = "35.235.240.0/20"
}

variable "health_check_ranges" {
  description = "Google Front End / health-check source ranges."
  type        = list(string)
  default     = ["130.211.0.0/22", "35.191.0.0/16"]
}

variable "frontend_ports" {
  description = "Ports served by the frontend tier."
  type        = list(string)
  default     = ["80", "443"]
}

variable "backend_ports" {
  description = "Ports served by the backend tier."
  type        = list(string)
  default     = ["8080", "8443"]
}

variable "private_service_access_prefix_length" {
  description = "Prefix length for the private services access range used by Cloud SQL."
  type        = number
  default     = 16
}

variable "depends_on_id" {
  description = "Opaque dependency handle (e.g. project-services readiness) to order module creation."
  type        = string
  default     = ""
}
