# Three-Tier Application Platform on Google Cloud (Modular, Production-Grade)

Terraform for a scalable, **security-hardened** three-tier application on Google
Cloud Platform. The infrastructure is composed from reusable modules and is
aligned with the **CIS Google Cloud Platform Foundations Benchmark**, and control
families from **ISO 27001**, **SOC 2** and **PCI-DSS**.

> Full design and compliance detail lives in
> [`docs/Project-Documentation.pdf`](docs/Project-Documentation.pdf)
> (regenerate with `python docs/generate_pdf.py`).

## Architecture

```
                        Internet
                            │
                   ┌────────▼─────────┐
                   │   Cloud Armor    │  OWASP WAF · rate limiting · L7 DDoS
                   └────────┬─────────┘
                   ┌────────▼─────────┐
                   │ Global HTTPS LB  │  Managed TLS · HTTP→HTTPS · Cloud CDN
                   └────────┬─────────┘
        ┌───────────────────▼────────────────────┐  VPC: three-tier-vpc
        │  Frontend subnet 10.0.1.0/24            │
        │  MIG (Shielded VMs, autoscaled 2–20)    │  tag: frontend
        └───────────────────┬────────────────────┘
                   ┌─────────▼─────────┐
                   │ Internal TCP LB   │  private east/west only
                   └─────────┬─────────┘
        ┌───────────────────▼────────────────────┐
        │  Backend subnet 10.0.2.0/24             │
        │  MIG (Shielded VMs, autoscaled 2–16)    │  tag: backend
        └───────────────────┬────────────────────┘
                   ┌─────────▼─────────┐
                   │ Private Svc Access │  VPC peering
                   └─────────┬─────────┘
        ┌───────────────────▼────────────────────┐
        │  Database subnet 10.0.3.0/24            │
        │  Cloud SQL (private IP, CMEK, HA, SSL)  │
        └─────────────────────────────────────────┘

Cross-cutting: Cloud NAT (egress) · Cloud KMS (CMEK) · Secret Manager ·
IAM least-privilege SAs · VPC Flow Logs · Cloud Audit Logs → GCS archive ·
Cloud Monitoring alerts.
```

## Repository layout

```
.
├── main.tf                     # Composition root — wires the modules
├── variables.tf                # Root input variables
├── outputs.tf                  # Root outputs
├── providers.tf                # Provider configuration
├── versions.tf                 # Terraform & provider version constraints
├── backend.tf                  # GCS remote state (configure per env)
├── terraform.tfvars.example    # Example variable values
├── environments/
│   ├── dev.tfvars              # Dev overrides
│   ├── prod.tfvars             # Prod overrides
│   └── prod.gcs.tfbackend      # Prod backend config
├── modules/
│   ├── project-services/       # API enablement + propagation wait
│   ├── networking/             # VPC, subnets, firewall, Cloud NAT, PSA
│   ├── security/               # CMEK keys, SAs, Cloud Armor
│   ├── compute/                # Generic hardened tier (Shielded VM MIG)
│   ├── load-balancer/          # External HTTPS LB + internal LB
│   ├── database/               # Hardened Cloud SQL + Secret Manager
│   └── monitoring/             # Alerts, audit log sink, data-access logs
├── scripts/                    # Instance startup scripts
└── docs/                       # Documentation sources + generated PDF
```

## Modules

| Module | Responsibility | Key security controls |
|--------|----------------|-----------------------|
| `project-services` | Enable required Google APIs | Explicit least-set of APIs |
| `networking` | VPC, per-tier subnets, firewall, Cloud NAT, private services access | Default-deny ingress, flow logs, NAT egress, IAP-only SSH, Private Google Access |
| `security` | CMEK key ring/keys, per-tier service accounts, Cloud Armor | Key rotation, least-privilege IAM, OWASP WAF, adaptive DDoS, rate limiting |
| `compute` | Reusable tier — instance template, MIG, autoscaler, health check | Shielded VM, CMEK disks, no public IP, OS Login, blocked project SSH keys |
| `load-balancer` | External global HTTPS LB + internal LB | Managed TLS (MODERN policy, TLS 1.2+), HTTP→HTTPS redirect, Armor attach |
| `database` | Cloud SQL primary + replicas + password secret | Private IP, CMEK, SSL-only, PITR, deletion protection, hardened flags |
| `monitoring` | Alert policy, notification channel, audit archive | Audit log sink to CMEK bucket, DATA_READ/WRITE audit logs |

## Prerequisites

- A GCP project with billing enabled and the `Owner`/appropriate admin roles
- Terraform >= 1.3.0
- Google Cloud SDK (`gcloud`) authenticated (`gcloud auth application-default login`)
- A GCS bucket for remote state (recommended, with versioning + CMEK)

## Deployment

```bash
# 1. Initialize (dev, local state)
terraform init

# For prod with remote state:
# terraform init -backend-config=environments/prod.gcs.tfbackend

# 2. Plan
terraform plan  -var-file=environments/dev.tfvars

# 3. Apply
terraform apply -var-file=environments/dev.tfvars
```

Set real values in your tfvars first (at minimum `project_id` and `alert_email`).

## Cleanup

```bash
terraform destroy -var-file=environments/dev.tfvars
```

> In `prod`, `db_deletion_protection = true` and the CMEK keys have
> `prevent_destroy = true`; disable/adjust intentionally before destroying.

## Security highlights vs. the original design

- **Added Cloud NAT** so private instances can patch without public IPs (the
  original had neither public IPs nor NAT — egress was broken).
- **Implemented Cloud Armor** (OWASP WAF, rate limiting, adaptive DDoS) — it was
  documented but not present in code.
- **CMEK everywhere** (disks, Cloud SQL, Secret Manager, log bucket) with rotation.
- **Shielded VMs**, OS Login, blocked project SSH keys, serial console disabled.
- **HTTPS by default** in prod: managed certificate, MODERN TLS policy, HTTP→HTTPS.
- **Hardened Cloud SQL**: SSL enforced, PITR, deletion protection, secure flags,
  IAM database authentication.
- **Default-deny firewall** posture with logging; frontend reachable via LB only.
- **Least-privilege IAM** (removed blanket scopes; scoped roles per tier).
- **Centralized audit logging** to a retention-locked CMEK bucket + data-access logs.
- Fixed a **duplicate KMS data source** that made the original fail `validate`.

See the PDF for the full CIS/ISO/SOC 2/PCI control mapping.
