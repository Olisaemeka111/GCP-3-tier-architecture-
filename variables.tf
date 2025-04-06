variable "organization_id" {
  description = "The organization ID where the project will be created"
  type        = string
}

variable "billing_account" {
  description = "The billing account ID to associate with the project"
  type        = string
}

variable "project_name" {
  description = "The display name of the project"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "folder_id" {
  description = "The folder ID where the project will be created (optional)"
  type        = string
  default     = null
}

variable "region" {
  description = "The GCP region where resources will be created"
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "Name of the Virtual Private Cloud network"
  type        = string
}

variable "subnet_cidrs" {
  description = "CIDR ranges for subnets"
  type        = map(string)
  default     = {
    frontend = "10.0.1.0/24"
    backend  = "10.0.2.0/24"
    database = "10.0.3.0/24"
  }
}

variable "machine_type" {
  description = "Machine type for compute instances"
  type        = string
  default     = "e2-micro"
}

variable "instance_count" {
  description = "Number of instances in each tier"
  type        = number
  default     = 2
}

variable "db_version" {
  description = "Database version (e.g., MYSQL_5_7, POSTGRES_13)"
  type        = string
}

variable "db_tier" {
  description = "Database machine tier"
  type        = string
  default     = "db-f1-micro"
}

variable "create_read_replica" {
  description = "Whether to create a read replica for the database"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "frontend_scaling" {
  description = "Frontend autoscaling configuration"
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
  description = "Backend autoscaling configuration"
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

variable "enable_ssl" {
  description = "Enable SSL/TLS for frontend load balancer"
  type        = bool
  default     = false
}

variable "ssl_certificates" {
  description = "List of SSL certificate self links for HTTPS load balancer"
  type        = list(string)
  default     = []
}

variable "zones" {
  description = "The zones to distribute instances across"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "read_replica_count" {
  description = "Number of read replicas to create for the database"
  type        = number
  default     = 1
}

# Add reference to the KMS key
variable "kms_key_ring" {
  description = "The name of the Cloud KMS key ring"
  type        = string
}

variable "kms_key_name" {
  description = "The name of the Cloud KMS key"
  type        = string
}