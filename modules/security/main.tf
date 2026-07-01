###############################################################################
# Security module
# - Customer-managed encryption keys (CMEK) with automatic rotation for disks,
#   Cloud SQL, Secret Manager and Cloud Storage.
# - Least-privilege service accounts for each application tier.
# - Grants for the Google-managed service agents that need the CMEK keys.
# - Cloud Armor edge security policy (OWASP WAF, rate limiting, adaptive DDoS).
# - CMEK-encrypted Secret Manager secret for the database password.
###############################################################################

data "google_project" "project" {
  project_id = var.project_id
}

locals {
  name_prefix    = var.environment
  project_number = data.google_project.project.number

  compute_agent = "serviceAccount:service-${local.project_number}@compute-system.iam.gserviceaccount.com"
  sql_agent     = "serviceAccount:service-${local.project_number}@gcp-sa-cloud-sql.iam.gserviceaccount.com"
  storage_agent = "serviceAccount:service-${local.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

###############################################################################
# KMS: key ring + per-purpose CMEK keys with rotation
###############################################################################

resource "google_kms_key_ring" "this" {
  project  = var.project_id
  name     = "${local.name_prefix}-${var.key_ring_name}"
  location = var.region
}

resource "google_kms_crypto_key" "disk" {
  name            = "${local.name_prefix}-disk-key"
  key_ring        = google_kms_key_ring.this.id
  rotation_period = var.key_rotation_period
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "sql" {
  name            = "${local.name_prefix}-sql-key"
  key_ring        = google_kms_key_ring.this.id
  rotation_period = var.key_rotation_period
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "secret" {
  name            = "${local.name_prefix}-secret-key"
  key_ring        = google_kms_key_ring.this.id
  rotation_period = var.key_rotation_period
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "storage" {
  name            = "${local.name_prefix}-storage-key"
  key_ring        = google_kms_key_ring.this.id
  rotation_period = var.key_rotation_period
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Service identities (Google-managed agents) that must use the CMEK keys
###############################################################################

resource "google_project_service_identity" "secretmanager" {
  provider = google-beta
  project  = var.project_id
  service  = "secretmanager.googleapis.com"
}

resource "google_project_service_identity" "sqladmin" {
  provider = google-beta
  project  = var.project_id
  service  = "sqladmin.googleapis.com"
}

# Compute Engine agent -> disk CMEK
resource "google_kms_crypto_key_iam_member" "compute_disk" {
  crypto_key_id = google_kms_crypto_key.disk.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = local.compute_agent
}

# Cloud SQL agent -> SQL CMEK
resource "google_kms_crypto_key_iam_member" "sql" {
  crypto_key_id = google_kms_crypto_key.sql.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.sqladmin.email}"
}

# Secret Manager agent -> secret CMEK
resource "google_kms_crypto_key_iam_member" "secret" {
  crypto_key_id = google_kms_crypto_key.secret.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.secretmanager.email}"
}

# Cloud Storage agent -> storage CMEK
resource "google_kms_crypto_key_iam_member" "storage" {
  crypto_key_id = google_kms_crypto_key.storage.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = local.storage_agent
}

###############################################################################
# Least-privilege service accounts per tier
###############################################################################

resource "google_service_account" "frontend" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-frontend-sa"
  display_name = "Frontend tier service account (${var.environment})"
}

resource "google_service_account" "backend" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-backend-sa"
  display_name = "Backend tier service account (${var.environment})"
}

resource "google_project_iam_member" "frontend_roles" {
  for_each = toset(var.frontend_sa_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.frontend.email}"
}

resource "google_project_iam_member" "backend_roles" {
  for_each = toset(var.backend_sa_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.backend.email}"
}

###############################################################################
# Cloud Armor: edge WAF / rate limiting / adaptive DDoS
###############################################################################

resource "google_compute_security_policy" "edge" {
  project     = var.project_id
  name        = "${local.name_prefix}-edge-security-policy"
  description = "Edge security policy: OWASP WAF, rate limiting, adaptive DDoS."

  # Adaptive Protection (ML-based L7 DDoS detection).
  dynamic "adaptive_protection_config" {
    for_each = var.enable_adaptive_protection ? [1] : []
    content {
      layer_7_ddos_defense_config {
        enable = true
      }
    }
  }

  # Preconfigured OWASP Core Rule Set WAF signatures.
  rule {
    action      = "deny(403)"
    priority    = 1000
    description = "Block SQL injection"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': ${var.waf_sensitivity}})"
      }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = 1001
    description = "Block cross-site scripting"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': ${var.waf_sensitivity}})"
      }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = 1002
    description = "Block local/remote file inclusion"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('lfi-v33-stable', {'sensitivity': ${var.waf_sensitivity}}) || evaluatePreconfiguredWaf('rfi-v33-stable', {'sensitivity': ${var.waf_sensitivity}})"
      }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = 1003
    description = "Block remote code execution"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('rce-v33-stable', {'sensitivity': ${var.waf_sensitivity}})"
      }
    }
  }

  # Per-client rate limiting (throttle abusive sources).
  rule {
    action      = "rate_based_ban"
    priority    = 2000
    description = "Rate limit per client IP"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = var.armor_rate_limit_threshold
        interval_sec = var.armor_rate_limit_interval_sec
      }
      ban_duration_sec = 600
    }
  }

  # Default allow (lowest priority).
  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default allow rule"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
