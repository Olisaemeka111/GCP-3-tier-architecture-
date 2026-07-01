###############################################################################
# Monitoring & Audit module
# - Email notification channel + high-CPU alert policy.
# - CMEK-encrypted, versioned, retention-locked log archive bucket.
# - Project log sink exporting all admin/audit activity to the archive bucket.
# - Project-wide data-access audit logging (DATA_READ / DATA_WRITE).
###############################################################################

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Email Notification Channel (${var.environment})"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "cpu_usage" {
  project      = var.project_id
  display_name = "High CPU Usage Alert (${var.environment})"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "VM Instance - CPU utilization"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.cpu_threshold

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.instance_id"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

###############################################################################
# Centralized audit log archive
###############################################################################

resource "google_storage_bucket" "log_archive" {
  project                     = var.project_id
  name                        = "${var.project_id}-${var.environment}-audit-logs"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.log_storage_kms_key_id
  }

  retention_policy {
    retention_period = var.log_retention_days * 24 * 60 * 60
  }

  lifecycle_rule {
    condition {
      age = var.log_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_logging_project_sink" "audit" {
  project     = var.project_id
  name        = "${var.environment}-audit-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.log_archive.name}"
  filter      = "logName:\"cloudaudit.googleapis.com\""

  unique_writer_identity = true
}

# Allow the sink's writer identity to write into the archive bucket.
resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = google_storage_bucket.log_archive.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.audit.writer_identity
}

###############################################################################
# Data-access audit logging (project-wide)
###############################################################################

resource "google_project_iam_audit_config" "all_services" {
  count   = var.enable_data_access_audit_logs ? 1 : 0
  project = var.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
