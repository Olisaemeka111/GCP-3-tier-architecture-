project_id  = "your-dev-project-id"
alert_email = "platform-alerts@example.com"

region      = "us-central1"
zones       = ["us-central1-a", "us-central1-b", "us-central1-c"]
environment = "dev"

# Dev: HTTP-only LB, smaller DB, replicas off, deletion protection off for churn.
ssl_domains            = []
enable_cdn             = false
db_tier                = "db-custom-1-3840"
db_availability_type   = "ZONAL"
db_deletion_protection = false
read_replica_count     = 0
enable_confidential_vm = false
log_retention_days     = 30
