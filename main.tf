###############################################################################
# Three-Tier Application Platform — composition root
# Wires together the reusable modules under ./modules into a complete,
# production-grade, security-hardened three-tier deployment.
###############################################################################

locals {
  frontend_named_ports = [
    { name = "http", port = 80 },
    { name = "https", port = 443 },
  ]
  backend_named_ports = [
    { name = "http", port = 8080 },
    { name = "https", port = 8443 },
  ]
}

# 1. Enable required APIs (all other modules depend on this being ready).
module "project_services" {
  source     = "./modules/project-services"
  project_id = var.project_id
}

# 2. Networking: VPC, subnets, firewall, Cloud NAT, private services access.
module "networking" {
  source = "./modules/networking"

  project_id         = var.project_id
  region             = var.region
  environment        = var.environment
  vpc_name           = var.vpc_name
  subnet_cidrs       = var.subnet_cidrs
  flow_logs_sampling = var.flow_logs_sampling
  depends_on_id      = module.project_services.apis_ready_id

  depends_on = [module.project_services]
}

# 3. Security: CMEK keys, service accounts, Cloud Armor.
module "security" {
  source = "./modules/security"

  project_id          = var.project_id
  region              = var.region
  environment         = var.environment
  key_rotation_period = var.key_rotation_period
  depends_on_id       = module.project_services.apis_ready_id

  depends_on = [module.project_services]
}

# 4. Frontend tier.
module "frontend" {
  source = "./modules/compute"

  project_id             = var.project_id
  region                 = var.region
  zones                  = var.zones
  environment            = var.environment
  tier_name              = "frontend"
  machine_type           = var.frontend_machine_type
  disk_kms_key_id        = module.security.disk_key_id
  network                = module.networking.vpc_self_link
  subnetwork             = module.networking.subnet_self_links["frontend"]
  service_account_email  = module.security.frontend_sa_email
  network_tags           = ["frontend"]
  startup_script         = file("${path.module}/scripts/frontend-startup.sh")
  named_ports            = local.frontend_named_ports
  health_check_port      = 80
  autoscaling            = var.frontend_scaling
  enable_confidential_vm = var.enable_confidential_vm
}

# 5. Backend tier.
module "backend" {
  source = "./modules/compute"

  project_id             = var.project_id
  region                 = var.region
  zones                  = var.zones
  environment            = var.environment
  tier_name              = "backend"
  machine_type           = var.backend_machine_type
  disk_kms_key_id        = module.security.disk_key_id
  network                = module.networking.vpc_self_link
  subnetwork             = module.networking.subnet_self_links["backend"]
  service_account_email  = module.security.backend_sa_email
  network_tags           = ["backend"]
  startup_script         = file("${path.module}/scripts/backend-startup.sh")
  named_ports            = local.backend_named_ports
  health_check_port      = 8080
  autoscaling            = var.backend_scaling
  enable_confidential_vm = var.enable_confidential_vm
}

# 6. Load balancers (external HTTPS for frontend + internal for backend).
module "load_balancer" {
  source = "./modules/load-balancer"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  frontend_instance_group  = module.frontend.instance_group
  frontend_health_check_id = module.frontend.health_check_id
  security_policy_id       = module.security.security_policy_id
  enable_cdn               = var.enable_cdn
  ssl_domains              = var.ssl_domains

  backend_instance_group  = module.backend.instance_group
  backend_health_check_id = module.backend.health_check_id
  backend_network         = module.networking.vpc_self_link
  backend_subnetwork      = module.networking.subnet_self_links["backend"]
  backend_port            = 8080
}

# 7. Database (Cloud SQL, hardened).
module "database" {
  source = "./modules/database"

  project_id                = var.project_id
  region                    = var.region
  environment               = var.environment
  database_version          = var.db_version
  tier                      = var.db_tier
  availability_type         = var.db_availability_type
  deletion_protection       = var.db_deletion_protection
  read_replica_count        = var.read_replica_count
  network_id                = module.networking.vpc_id
  private_vpc_connection_id = module.networking.private_vpc_connection_id
  sql_kms_key_id            = module.security.sql_key_id
  secret_kms_key_id         = module.security.secret_key_id
  sql_key_iam_dependency    = module.security.sql_key_iam_dependency
}

# 8. Monitoring, alerting and centralized audit logging.
module "monitoring" {
  source = "./modules/monitoring"

  project_id             = var.project_id
  region                 = var.region
  environment            = var.environment
  alert_email            = var.alert_email
  log_storage_kms_key_id = module.security.storage_key_id
  log_retention_days     = var.log_retention_days

  depends_on = [module.project_services]
}
