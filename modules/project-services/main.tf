###############################################################################
# Project Services module
# Enables the set of Google Cloud APIs required by the platform and provides a
# propagation wait so downstream modules do not race API enablement.
###############################################################################

resource "google_project_service" "this" {
  for_each = toset(var.activate_apis)

  project = var.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = var.disable_services_on_destroy
}

# Give the control plane time to propagate newly-enabled APIs before other
# modules start creating resources that depend on them.
resource "time_sleep" "wait_for_apis" {
  depends_on      = [google_project_service.this]
  create_duration = var.api_activation_wait_seconds
}
