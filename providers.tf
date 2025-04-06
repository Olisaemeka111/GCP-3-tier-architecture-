# Provider and Terraform configuration
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Provider configuration
provider "google" {
  region = var.region
}

provider "google-beta" {
  region = var.region
}

# State management with GCS backend can be uncommented and configured
# terraform {
#   backend "gcs" {
#     bucket = "your-terraform-state-bucket"
#     prefix = "terraform/state"
#   }
# }

# Project data source
data "google_project" "project" {
  project_id = var.project_id
}

# Common labels local variable
locals {
  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.project_id
  }
} 