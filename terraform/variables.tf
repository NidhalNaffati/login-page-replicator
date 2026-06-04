variable "project_id" {
  type = string
  # Set this to your *GCP Project ID* (not the display name).
  default = "nidhal-pfe"

  validation {
    condition     = length(trimspace(var.project_id)) > 0
    error_message = "project_id must be a non-empty string. Pass via -var or set the default."
  }
}

variable "region" {
  type    = string
  default = "europe-west9"

  validation {
    condition     = length(trimspace(var.region)) > 0
    error_message = "region must be a non-empty string. Pass via -var or set the default."
  }
}

variable "zone" {
  type    = string
  default = "europe-west9-a"
}

variable "cluster_name" {
  type    = string
  default = "devops-cluster"
}

variable "artifact_registry_repo_name" {
  type    = string
  default = "login-page-replicator-repo"
}

variable "cloud_run_service_name" {
  type    = string
  default = "login-page-replicator"
}
