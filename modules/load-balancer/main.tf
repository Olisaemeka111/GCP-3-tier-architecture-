###############################################################################
# Load Balancer module
# - External global HTTP(S) load balancer for the frontend tier with Cloud Armor,
#   Cloud CDN, a Google-managed SSL certificate and HTTP->HTTPS redirect.
# - Internal regional load balancer for the backend tier (private east/west).
###############################################################################

locals {
  name_prefix   = var.environment
  https_enabled = length(var.ssl_domains) > 0
}

###############################################################################
# External frontend load balancer
###############################################################################

resource "google_compute_global_address" "frontend" {
  project = var.project_id
  name    = "${local.name_prefix}-frontend-lb-ip"
}

resource "google_compute_backend_service" "frontend" {
  project               = var.project_id
  name                  = "${local.name_prefix}-frontend-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  health_checks         = [var.frontend_health_check_id]
  security_policy       = var.security_policy_id
  enable_cdn            = var.enable_cdn

  backend {
    group           = var.frontend_instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "frontend" {
  project         = var.project_id
  name            = "${local.name_prefix}-frontend-url-map"
  default_service = google_compute_backend_service.frontend.id
}

# --- HTTPS path (managed certificate) ---
resource "google_compute_managed_ssl_certificate" "frontend" {
  count   = local.https_enabled ? 1 : 0
  project = var.project_id
  name    = "${local.name_prefix}-frontend-cert"

  managed {
    domains = var.ssl_domains
  }
}

resource "google_compute_target_https_proxy" "frontend" {
  count            = local.https_enabled ? 1 : 0
  project          = var.project_id
  name             = "${local.name_prefix}-frontend-https-proxy"
  url_map          = google_compute_url_map.frontend.id
  ssl_certificates = [google_compute_managed_ssl_certificate.frontend[0].id]
  ssl_policy       = google_compute_ssl_policy.modern[0].id
}

resource "google_compute_global_forwarding_rule" "https" {
  count                 = local.https_enabled ? 1 : 0
  project               = var.project_id
  name                  = "${local.name_prefix}-frontend-https-fr"
  target                = google_compute_target_https_proxy.frontend[0].id
  port_range            = "443"
  ip_address            = google_compute_global_address.frontend.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# Modern TLS policy (TLS 1.2+, restricted cipher suites).
resource "google_compute_ssl_policy" "modern" {
  count           = local.https_enabled ? 1 : 0
  project         = var.project_id
  name            = "${local.name_prefix}-modern-tls"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

# --- HTTP path: redirect to HTTPS when TLS is enabled, otherwise serve directly ---
resource "google_compute_url_map" "http_redirect" {
  count   = local.https_enabled ? 1 : 0
  project = var.project_id
  name    = "${local.name_prefix}-frontend-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "frontend" {
  project = var.project_id
  name    = "${local.name_prefix}-frontend-http-proxy"
  url_map = local.https_enabled ? google_compute_url_map.http_redirect[0].id : google_compute_url_map.frontend.id
}

resource "google_compute_global_forwarding_rule" "http" {
  project               = var.project_id
  name                  = "${local.name_prefix}-frontend-http-fr"
  target                = google_compute_target_http_proxy.frontend.id
  port_range            = "80"
  ip_address            = google_compute_global_address.frontend.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

###############################################################################
# Internal backend load balancer
###############################################################################

resource "google_compute_region_backend_service" "backend" {
  project               = var.project_id
  name                  = "${local.name_prefix}-backend-service"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  timeout_sec           = 30
  health_checks         = [var.backend_health_check_id]

  backend {
    group          = var.backend_instance_group
    balancing_mode = "CONNECTION"
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_forwarding_rule" "backend_internal" {
  project               = var.project_id
  name                  = "${local.name_prefix}-backend-ilb-fr"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.backend.id
  ports                 = [var.backend_port]
  network               = var.backend_network
  subnetwork            = var.backend_subnetwork
}
