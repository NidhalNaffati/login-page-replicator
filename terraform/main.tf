terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    # Keep this empty and pass settings at init time:
    #   terraform init -backend-config=backend.hcl
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

