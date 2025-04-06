# Data tier (Database)
resource "google_sql_database_instance" "database" {
  name                = "${var.environment}-db-instance"
  database_version    = "MYSQL_8_0"
  region              = var.region
  project             = var.project_id
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.db_tier
    availability_type = "REGIONAL"

    backup_configuration {
      enabled            = true
      binary_log_enabled = true
      start_time         = "02:00"
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }

    database_flags {
      name  = "max_connections"
      value = "1000"
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

resource "google_sql_database" "database" {
  name            = "app-database"
  instance        = google_sql_database_instance.database.name
  project         = var.project_id
  deletion_policy = "DELETE"
}

resource "google_sql_user" "database_user" {
  name     = "app-user"
  instance = google_sql_database_instance.database.name
  project  = var.project_id
  password = random_password.db_password.result
}

# Optional: Database read replica for high availability
resource "google_sql_database_instance" "read_replica" {
  count                = var.read_replica_count
  name                 = "my-database-replica"
  master_instance_name = google_sql_database_instance.database.name
  region              = var.region
  project             = var.project_id
  database_version    = "MYSQL_8_0"
  deletion_protection = false

  replica_configuration {
    failover_target = false
  }

  settings {
    tier              = var.db_tier
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }
} 