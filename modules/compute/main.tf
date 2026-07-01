###############################################################################
# Compute module (generic application tier)
# Reusable for any tier (frontend/backend). Provides a hardened instance
# template with:
#   - Shielded VM (secure boot, vTPM, integrity monitoring)
#   - CMEK-encrypted boot disk
#   - No public IP (egress via Cloud NAT), IP forwarding disabled
#   - OS Login enforced, serial-port access disabled
# ...fronted by a regional managed instance group, autoscaler, auto-healing
# health check.
###############################################################################

locals {
  name = "${var.environment}-${var.tier_name}"
}

resource "google_compute_health_check" "this" {
  project             = var.project_id
  name                = "${local.name}-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_request_path
  }

  log_config {
    enable = true
  }
}

resource "google_compute_instance_template" "this" {
  project      = var.project_id
  name_prefix  = "${local.name}-template-"
  machine_type = var.machine_type
  region       = var.region

  lifecycle {
    create_before_destroy = true
  }

  disk {
    source_image = var.source_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-ssd"

    disk_encryption_key {
      kms_key_self_link = var.disk_kms_key_id
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    # No access_config block => no external/public IP.
  }

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  # Shielded VM hardening.
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  dynamic "confidential_instance_config" {
    for_each = var.enable_confidential_vm ? [1] : []
    content {
      enable_confidential_compute = true
    }
  }

  # Confidential VM requires the instances to terminate (not migrate) on host maintenance.
  scheduling {
    on_host_maintenance = var.enable_confidential_vm ? "TERMINATE" : "MIGRATE"
    automatic_restart   = true
  }

  can_ip_forward = false

  tags = var.network_tags

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
    serial-port-enable     = "FALSE"
  }

  metadata_startup_script = var.startup_script != "" ? var.startup_script : null
}

resource "google_compute_region_instance_group_manager" "this" {
  project                   = var.project_id
  name                      = "${local.name}-igm"
  base_instance_name        = local.name
  region                    = var.region
  distribution_policy_zones = var.zones

  version {
    instance_template = google_compute_instance_template.this.id
  }

  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.this.id
    initial_delay_sec = 300
  }

  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = length(var.zones)
    max_unavailable_fixed        = 0
    replacement_method           = "SUBSTITUTE"
    instance_redistribution_type = "PROACTIVE"
  }
}

resource "google_compute_region_autoscaler" "this" {
  project = var.project_id
  name    = "${local.name}-autoscaler"
  region  = var.region
  target  = google_compute_region_instance_group_manager.this.id

  autoscaling_policy {
    max_replicas    = var.autoscaling.max_replicas
    min_replicas    = var.autoscaling.min_replicas
    cooldown_period = var.autoscaling.cooldown_period

    cpu_utilization {
      target = var.autoscaling.target_cpu_utilization
    }
  }
}
