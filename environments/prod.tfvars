project_id  = "your-prod-project-id"
alert_email = "platform-alerts@example.com"

region      = "us-central1"
zones       = ["us-central1-a", "us-central1-b", "us-central1-c"]
environment = "prod"

# Prod: HTTPS with managed cert, CDN on, HA regional DB, replicas, hardening on.
ssl_domains            = ["app.example.com"]
enable_cdn             = true
db_tier                = "db-custom-4-15360"
db_availability_type   = "REGIONAL"
db_deletion_protection = true
read_replica_count     = 1
enable_confidential_vm = false
log_retention_days     = 365

frontend_scaling = {
  min_replicas           = 3
  max_replicas           = 20
  cooldown_period        = 60
  target_cpu_utilization = 0.6
}

backend_scaling = {
  min_replicas           = 3
  max_replicas           = 16
  cooldown_period        = 60
  target_cpu_utilization = 0.6
}
