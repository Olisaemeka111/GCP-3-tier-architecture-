# Three-Tier Application Infrastructure on Google Cloud Platform

This repository contains Terraform configurations for deploying a scalable three-tier application infrastructure on Google Cloud Platform.

## Prerequisites

- Google Cloud Platform account with billing enabled
- Terraform (version >= 1.0.0)
- Google Cloud SDK installed and configured
- Required APIs enabled in your GCP project:
  - Compute Engine API
  - Cloud SQL Admin API
  - Secret Manager API
  - Cloud KMS API
  - Cloud Monitoring API
  - Cloud Logging API
  - Service Networking API
  - Identity and Access Management (IAM) API

## Infrastructure Components

### Network Infrastructure
- **VPC Network**: `three-tier-vpc`
  - Frontend subnet: `dev-frontend-subnet` (10.0.1.0/24)
  - Backend subnet: `dev-backend-subnet` (10.0.2.0/24)
  - Database subnet: `dev-database-subnet` (10.0.3.0/24)

- **Firewall Rules**:
  - `allow-frontend`: Allows HTTP(80) and HTTPS(443) from internet
  - `allow-backend`: Allows ports 8080 and 8443 from frontend instances
  - `allow-ssh`: Allows SSH access through IAP (35.235.240.0/20)
  - `allow-health-checks`: Allows health check access from Google Load Balancer

### Compute Resources

#### Frontend Tier
- **Instance Template**: `dev-frontend-template-*`
  - Debian 11 base image
  - Nginx web server
  - Custom startup script
  - Service account with logging and monitoring permissions

- **Instance Group**:
  - Name: `dev-frontend-igm`
  - Regional deployment across 3 zones
  - Autoscaling enabled (2-10 instances)
  - Health checks on port 80

- **Load Balancer**:
  - Global HTTP(S) load balancer
  - Cloud CDN enabled
  - WAF security policy

#### Backend Tier
- **Instance Template**: `backend-template-*`
  - Debian 11 base image
  - Java 11 runtime
  - Simple HTTP server on port 8080
  - Service account with SQL access permissions

- **Instance Group**:
  - Name: `dev-backend-igm`
  - Regional deployment across 3 zones
  - Autoscaling enabled (2-8 instances)
  - Health checks on port 8080

- **Load Balancer**:
  - Internal load balancer
  - Session affinity enabled
  - Connection draining configured

### Database Tier
- **Cloud SQL**:
  - Primary Instance: `dev-db-instance`
    - MySQL 8.0
    - Regional availability
    - Private IP only
    - Automated backups enabled
  - Read Replica (optional): `my-database-replica`
  - Database: `app-database`
  - User: `app-user`

### Security
- **Service Accounts**:
  - Frontend SA: `dev-frontend-sa`
  - Backend SA: `dev-backend-sa`

- **Secret Management**:
  - Cloud KMS key ring: `dev-secrets-ring`
  - Database password stored in Secret Manager

### Monitoring
- **Alert Policies**:
  - High CPU usage alert (>80% threshold)
  - Email notifications configured

## Infrastructure Management

### Deployment
1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the deployment plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

### Cleanup
To destroy the infrastructure:

1. Remove database read replica (if exists):
   ```bash
   gcloud sql instances delete my-database-replica --project=<project-id> --quiet
   ```

2. Remove backend instance group and autoscaler:
   ```bash
   gcloud compute instance-groups managed delete dev-backend-igm --region=us-central1 --project=<project-id> --quiet
   ```

3. Remove database instance:
   ```bash
   gcloud sql instances delete dev-db-instance --project=<project-id> --quiet
   ```

4. Destroy remaining infrastructure:
   ```bash
   terraform destroy
   ```

Note: Always verify that all resources are properly cleaned up using:
```bash
gcloud compute instances list
gcloud compute instance-groups list
gcloud sql instances list
gcloud compute networks list
gcloud iam service-accounts list
gcloud compute firewall-rules list
gcloud compute forwarding-rules list
```

## Access Methods

### Frontend Access
- The frontend application is accessible through the global load balancer IP address
- URL format: `http://<load-balancer-ip>`
- Public access is protected by Cloud Armor security policies

### Backend Access
- Backend services are not directly accessible from the internet
- Access is only available:
  1. From frontend instances through internal load balancer
  2. Through Cloud IAP for administrative access

### Database Access
- No direct external access - private IP only
- Access methods:
  1. From backend instances using Cloud SQL Auth proxy
  2. Through Cloud SQL Admin console
  3. Using Cloud Shell with proper IAP configuration

### Administrative Access
- SSH access to instances:
  ```bash
  gcloud compute ssh --zone <zone> <instance-name> --tunnel-through-iap
  ```

- Database administrative access:
  ```bash
  gcloud sql connect dev-db-instance --user=app-user
  ```

## Security Considerations
1. All internal communication uses private IP addresses
2. External access is protected by:
   - Cloud Armor security policies
   - IAP for administrative access
   - Firewall rules limiting access to specific IP ranges
3. Service accounts follow principle of least privilege
4. Secrets are managed through Secret Manager and KMS

## Monitoring and Logging
- All instances have logging and monitoring enabled
- Custom alerts for:
  - High CPU utilization
  - Instance health status
  - Load balancer metrics
- Logs are available through Cloud Logging
- Metrics are available through Cloud Monitoring dashboards

## Troubleshooting

### Common Issues
1. **Resource Deletion Order**: Some resources have dependencies and may need to be deleted in a specific order. Follow the cleanup instructions carefully.
2. **API Enablement**: Ensure all required APIs are enabled in your project before deployment.
3. **IAM Permissions**: Verify that your account has sufficient permissions to create and manage all resources.
4. **Quota Limits**: Check if you have sufficient quota for all required resources in your target region.

### Getting Help
- Review the GCP documentation for specific services
- Check Terraform logs using `TF_LOG=DEBUG terraform <command>`
- Consult the project's issue tracker for known issues and solutions 