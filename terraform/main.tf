terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "pfe-esprit-489411-tfstate"
    prefix = "devops-cluster"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

