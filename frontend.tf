# Frontend instance template
resource "google_compute_instance_template" "frontend" {
  name_prefix  = "${var.environment}-frontend-template-"
  machine_type = "e2-medium"
  project      = var.project_id

  lifecycle {
    create_before_destroy = true
  }

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnets["frontend"].name
    subnetwork_project = var.project_id
  }

  service_account {
    email  = google_service_account.frontend_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["frontend"]

  metadata_startup_script = file("${path.module}/scripts/frontend-startup.sh")
}

# Frontend instance group
resource "google_compute_region_instance_group_manager" "frontend" {
  name                      = "${var.environment}-frontend-igm"
  base_instance_name        = "${var.environment}-frontend"
  region                    = var.region
  project                   = var.project_id
  distribution_policy_zones = var.zones

  version {
    instance_template = google_compute_instance_template.frontend.id
  }

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "https"
    port = 443
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.frontend.id
    initial_delay_sec = 300
  }

  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed             = 3
    max_unavailable_fixed       = 0
    replacement_method          = "SUBSTITUTE"
    instance_redistribution_type = "PROACTIVE"
  }
}

# Frontend autoscaler
resource "google_compute_region_autoscaler" "frontend" {
  name    = "${var.environment}-frontend-autoscaler"
  project = var.project_id
  region  = var.region
  target  = google_compute_region_instance_group_manager.frontend.id

  autoscaling_policy {
    max_replicas    = 10
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}

# Frontend health check
resource "google_compute_health_check" "frontend" {
  name    = "frontend-health-check"
  project = var.project_id

  http_health_check {
    port = 80
  }
}

# Frontend load balancer components
resource "google_compute_global_address" "frontend" {
  name    = "${var.environment}-frontend-lb-ip"
  project = var.project_id
}

resource "google_compute_url_map" "frontend_http" {
  name            = "${var.environment}-frontend-lb"
  project         = var.project_id
  default_service = google_compute_backend_service.frontend.id
}

resource "google_compute_target_http_proxy" "frontend" {
  name    = "${var.environment}-frontend-lb-proxy"
  project = var.project_id
  url_map = google_compute_url_map.frontend_http.id
}

resource "google_compute_global_forwarding_rule" "frontend_http" {
  name       = "${var.environment}-frontend-lb-forwarding-rule"
  project    = var.project_id
  target     = google_compute_target_http_proxy.frontend.id
  port_range = "80"
  ip_address = google_compute_global_address.frontend.address
}

# Frontend backend service
resource "google_compute_backend_service" "frontend" {
  name                  = "${var.environment}-frontend-backend-service"
  project               = var.project_id
  protocol             = "HTTP"
  port_name            = "http"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec          = 30
  health_checks        = [google_compute_health_check.frontend.id]

  backend {
    group           = google_compute_region_instance_group_manager.frontend.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
} 