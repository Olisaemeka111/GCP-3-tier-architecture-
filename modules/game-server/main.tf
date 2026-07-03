###############################################################################
# Game server module
# A single, dedicated Compute Engine VM (public IP) that runs the WorkAdventure
# production stack via Docker Compose. This is intentionally NOT part of the
# autoscaled MIG tiers: WorkAdventure is a stateful single-host application.
###############################################################################

locals {
  name = "${var.environment}-game-server"
}

resource "google_compute_address" "this" {
  project = var.project_id
  name    = "${local.name}-ip"
  region  = var.region
}

# Public web traffic (Traefik / Let's Encrypt HTTP-01 + HTTPS).
resource "google_compute_firewall" "web" {
  project       = var.project_id
  name          = "${local.name}-allow-web"
  network       = var.network
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["game-server"]

  allow {
    protocol = "tcp"
    ports    = concat(["80", "443"], var.additional_web_ports)
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# SSH via IAP only.
resource "google_compute_firewall" "ssh" {
  project       = var.project_id
  name          = "${local.name}-allow-iap-ssh"
  network       = var.network
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.ssh_source_ranges
  target_tags   = ["game-server"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_instance" "this" {
  project      = var.project_id
  name         = local.name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["game-server"]

  boot_disk {
    initialize_params {
      image = var.source_image
      size  = var.disk_size_gb
      type  = "pd-ssd"
    }
    kms_key_self_link = var.disk_kms_key_id
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    access_config {
      nat_ip = google_compute_address.this.address
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
    acme-email     = var.acme_email
    wa-version     = var.workadventure_version
  }

  metadata_startup_script = var.startup_script

  # Boot disk CMEK requires the Compute Engine service agent to have access to
  # the key; that grant lives in the security module.
  allow_stopping_for_update = true
}
