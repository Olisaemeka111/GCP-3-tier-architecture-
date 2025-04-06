# Backend instance template
resource "google_compute_instance_template" "backend" {
  name_prefix  = "backend-template-"
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
    subnetwork = google_compute_subnetwork.subnets["backend"].name
    subnetwork_project = var.project_id
  }

  service_account {
    email  = google_service_account.backend_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["backend"]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y openjdk-11-jdk
    cat > /tmp/app.java << 'INNEREOF'
    import com.sun.net.httpserver.HttpServer;
    import java.io.IOException;
    import java.io.OutputStream;
    import java.net.InetSocketAddress;
    
    public class SimpleHttpServer {
        public static void main(String[] args) throws IOException {
            HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
            server.createContext("/", (exchange -> {
                String response = "Backend Server Response";
                exchange.sendResponseHeaders(200, response.length());
                OutputStream os = exchange.getResponseBody();
                os.write(response.getBytes());
                os.close();
            }));
            server.setExecutor(null);
            server.start();
        }
    }
    INNEREOF
    javac /tmp/app.java
    nohup java -cp /tmp SimpleHttpServer &
  EOF
}

# Backend instance group
resource "google_compute_region_instance_group_manager" "backend" {
  name                      = "${var.environment}-backend-igm"
  base_instance_name        = "${var.environment}-backend"
  region                    = var.region
  project                   = var.project_id
  distribution_policy_zones = var.zones

  version {
    instance_template = google_compute_instance_template.backend.id
  }

  named_port {
    name = "http"
    port = 8080
  }

  named_port {
    name = "https"
    port = 8443
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.backend.id
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

# Backend autoscaler
resource "google_compute_region_autoscaler" "backend" {
  name    = "${var.environment}-backend-autoscaler"
  project = var.project_id
  region  = var.region
  target  = google_compute_region_instance_group_manager.backend.id

  autoscaling_policy {
    max_replicas    = 8
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}

# Backend health check
resource "google_compute_health_check" "backend" {
  name    = "backend-health-check"
  project = var.project_id

  http_health_check {
    port = 8080
  }
}

# Backend internal load balancer
resource "google_compute_region_backend_service" "backend" {
  name                  = "${var.environment}-backend-service"
  project               = var.project_id
  region                = var.region
  protocol             = "HTTP"
  load_balancing_scheme = "INTERNAL"
  timeout_sec          = 30
  health_checks        = [google_compute_health_check.backend.id]

  backend {
    group           = google_compute_region_instance_group_manager.backend.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
} 