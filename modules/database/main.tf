###############################################################################
# Database module (Cloud SQL, hardened)
# - Private IP only (no public IP), CMEK encryption, SSL/TLS required.
# - HA (regional), automated backups + point-in-time recovery.
# - Query Insights, secure database flags, deletion protection.
# - Randomly-generated password stored CMEK-encrypted in Secret Manager.
###############################################################################

locals {
  name = "${var.environment}-db-instance"

  # Secure MySQL flags (CIS Cloud SQL benchmark aligned).
  mysql_flags = {
    "local_infile"                = "off"
    "skip_show_database"          = "on"
    "log_output"                  = "FILE"
    "slow_query_log"              = "on"
    "long_query_time"             = "2"
    "cloudsql_iam_authentication" = "on"
  }
}

resource "google_sql_database_instance" "primary" {
  project             = var.project_id
  name                = local.name
  database_version    = var.database_version
  region              = var.region
  deletion_protection = var.deletion_protection

  depends_on = [
    var.private_vpc_connection_id,
    var.sql_key_iam_dependency,
  ]

  encryption_key_name = var.sql_kms_key_id

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size_gb
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      binary_log_enabled             = true
      start_time                     = "02:00"
      point_in_time_recovery_enabled = false # binary_log_enabled provides PITR for MySQL
      transaction_log_retention_days = var.transaction_log_retention_days
      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      ssl_mode                                      = "ENCRYPTED_ONLY"
      enable_private_path_for_google_cloud_services = true
    }

    dynamic "database_flags" {
      for_each = local.mysql_flags
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }

    database_flags {
      name  = "max_connections"
      value = var.max_connections
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = false
    }
  }
}

resource "google_sql_database" "app" {
  project  = var.project_id
  name     = var.database_name
  instance = google_sql_database_instance.primary.name
}

resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_sql_user" "app" {
  project  = var.project_id
  name     = var.database_user
  instance = google_sql_database_instance.primary.name
  password = random_password.db.result
}

# CMEK-encrypted secret holding the DB password (user-managed replica in region).
resource "google_secret_manager_secret" "db_password" {
  project   = var.project_id
  secret_id = "${var.environment}-db-password"

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    purpose     = "database"
  }

  replication {
    user_managed {
      replicas {
        location = var.region
        customer_managed_encryption {
          kms_key_name = var.secret_kms_key_id
        }
      }
    }
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db.result
}

# Optional read replicas.
resource "google_sql_database_instance" "read_replica" {
  count                = var.read_replica_count
  project              = var.project_id
  name                 = "${local.name}-replica-${count.index + 1}"
  master_instance_name = google_sql_database_instance.primary.name
  region               = var.region
  database_version     = var.database_version
  deletion_protection  = var.deletion_protection
  encryption_key_name  = var.sql_kms_key_id

  replica_configuration {
    failover_target = false
  }

  settings {
    tier              = var.tier
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
      ssl_mode        = "ENCRYPTED_ONLY"
    }
  }
}
