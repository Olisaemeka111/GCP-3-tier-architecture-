###############################################################################
# Networking module
# - Custom-mode VPC with per-tier subnets, VPC flow logs and Private Google
#   Access.
# - Cloud Router + Cloud NAT so private (no public IP) instances have controlled
#   egress for patching without being reachable from the internet.
# - Least-privilege firewall rules (default-deny posture) with firewall logging.
# - Private Services Access range + peering for private Cloud SQL.
###############################################################################

locals {
  name_prefix = var.environment
}

resource "google_compute_network" "vpc" {
  project                         = var.project_id
  name                            = var.vpc_name
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = false
}

# Per-tier subnets with flow logs and Private Google Access enabled.
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnet_cidrs

  project                  = var.project_id
  name                     = "${local.name_prefix}-${each.key}-subnet"
  ip_cidr_range            = each.value
  network                  = google_compute_network.vpc.id
  region                   = var.region
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = var.flow_logs_sampling
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

###############################################################################
# Cloud Router + Cloud NAT (controlled egress for private instances)
###############################################################################

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${local.name_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "${local.name_prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

###############################################################################
# Firewall rules (default-deny ingress + explicit least-privilege allows)
###############################################################################

# Explicit lowest-priority deny for all ingress. GCP has an implied deny, but an
# explicit logged deny gives visibility into dropped traffic (CIS 3.x posture).
resource "google_compute_firewall" "deny_all_ingress" {
  project       = var.project_id
  name          = "${local.name_prefix}-deny-all-ingress"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow external traffic to the frontend ONLY from the Google load balancer /
# health-check ranges. Public clients reach the app via the LB, not the VMs.
resource "google_compute_firewall" "allow_frontend_from_lb" {
  project       = var.project_id
  name          = "${local.name_prefix}-allow-frontend-from-lb"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.health_check_ranges
  target_tags   = ["frontend"]

  allow {
    protocol = "tcp"
    ports    = var.frontend_ports
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Frontend -> Backend east/west traffic only.
resource "google_compute_firewall" "allow_backend_from_frontend" {
  project     = var.project_id
  name        = "${local.name_prefix}-allow-backend-from-frontend"
  network     = google_compute_network.vpc.name
  direction   = "INGRESS"
  priority    = 1000
  source_tags = ["frontend"]
  target_tags = ["backend"]

  allow {
    protocol = "tcp"
    ports    = var.backend_ports
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# SSH only through Identity-Aware Proxy (no public SSH exposure).
resource "google_compute_firewall" "allow_iap_ssh" {
  project       = var.project_id
  name          = "${local.name_prefix}-allow-iap-ssh"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = [var.iap_source_range]
  target_tags   = ["frontend", "backend"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Google health checks to both tiers.
resource "google_compute_firewall" "allow_health_checks" {
  project       = var.project_id
  name          = "${local.name_prefix}-allow-health-checks"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.health_check_ranges
  target_tags   = ["frontend", "backend"]

  allow {
    protocol = "tcp"
    ports    = concat(var.frontend_ports, var.backend_ports)
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

###############################################################################
# Private Services Access for Cloud SQL (private IP only)
###############################################################################

resource "google_compute_global_address" "private_service_range" {
  project       = var.project_id
  name          = "${local.name_prefix}-private-service-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_access_prefix_length
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
}
