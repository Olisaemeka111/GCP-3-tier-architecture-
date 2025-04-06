# Network tier
resource "google_compute_network" "vpc" {
  project                  = data.google_project.project.project_id
  name                     = "three-tier-vpc"
  auto_create_subnetworks  = false
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each      = var.subnet_cidrs
  name          = "${var.environment}-${each.key}-subnet"
  ip_cidr_range = each.value
  network       = google_compute_network.vpc.id
  region        = var.region
  project       = var.project_id
  
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
    filter_expr          = "true"
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_frontend" {
  name    = "allow-frontend"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["frontend"]
}

resource "google_compute_firewall" "allow_backend" {
  name    = "allow-backend"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080", "8443"]
  }

  source_tags = ["frontend"]
  target_tags = ["backend"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # GCP IAP for secure SSH tunneling
  target_tags   = ["frontend", "backend"]
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-health-checks"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # GCP Load Balancer health checks
  target_tags   = ["frontend", "backend"]
}

# Private IP address for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

# VPC peering connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
} 