# Monitoring and Alerting
resource "google_monitoring_alert_policy" "cpu_usage" {
  display_name = "High CPU Usage Alert"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "VM Instance - CPU utilization"

    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.instance_id"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Email Notification Channel"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
} 