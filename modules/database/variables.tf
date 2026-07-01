variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the Cloud SQL instance."
  type        = string
}

variable "environment" {
  description = "Environment name used as a resource prefix."
  type        = string
}

variable "database_version" {
  description = "Cloud SQL database version (e.g. MYSQL_8_0, POSTGRES_15)."
  type        = string
  default     = "MYSQL_8_0"
}

variable "tier" {
  description = "Cloud SQL machine tier."
  type        = string
  default     = "db-custom-2-7680"
}

variable "network_id" {
  description = "VPC network ID for private IP."
  type        = string
}

variable "private_vpc_connection_id" {
  description = "Private services access connection ID (ensures peering exists before DB creation)."
  type        = string
}

variable "sql_kms_key_id" {
  description = "CMEK key ID for Cloud SQL encryption."
  type        = string
}

variable "secret_kms_key_id" {
  description = "CMEK key ID for the Secret Manager secret."
  type        = string
}

variable "sql_key_iam_dependency" {
  description = "Dependency handle ensuring the SQL agent can use the CMEK key first."
  type        = string
  default     = ""
}

variable "database_name" {
  description = "Application database name."
  type        = string
  default     = "app-database"
}

variable "database_user" {
  description = "Application database user."
  type        = string
  default     = "app-user"
}

variable "deletion_protection" {
  description = "Protect the instance from deletion (should be true in prod)."
  type        = bool
  default     = true
}

variable "availability_type" {
  description = "REGIONAL (HA) or ZONAL."
  type        = string
  default     = "REGIONAL"
}

variable "disk_size_gb" {
  description = "Data disk size in GB."
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Number of automated backups to retain."
  type        = number
  default     = 30
}

variable "transaction_log_retention_days" {
  description = "Days of transaction logs retained for point-in-time recovery."
  type        = number
  default     = 7
}

variable "read_replica_count" {
  description = "Number of read replicas to create."
  type        = number
  default     = 0
}

variable "max_connections" {
  description = "Max database connections flag."
  type        = string
  default     = "1000"
}
