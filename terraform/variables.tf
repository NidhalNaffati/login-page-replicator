variable "project_id" {
  type = string
  # Set this to your *GCP Project ID* (not the display name).
  default = "nidhal-pfe"

  validation {
    condition     = length(trimspace(var.project_id)) > 0
    error_message = "project_id must be a non-empty string. If you run: terraform plan -var=\"project_id=$PROJECT_ID\" then ensure PROJECT_ID is set (or omit -var to use defaults)."
  }
}

variable "region" {
  type    = string
  default = "europe-west1"

  validation {
    condition     = length(trimspace(var.region)) > 0
    error_message = "region must be a non-empty string. If you run: terraform plan -var=\"region=$REGION\" then ensure REGION is set (or omit -var to use defaults)."
  }
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "cluster_name" {
  type    = string
  default = "devops-cluster"
}

variable "gke_node_count" {
  type        = number
  description = "Node count PER ZONE for the primary node pool (regional cluster). In europe-west1 (3 zones), gke_node_count=1 results in ~3 total nodes."
  default     = 1
}

variable "gke_machine_type" {
  type        = string
  description = "GKE node machine type. Larger shapes may require increasing the project CPU quota (CPUS_ALL_REGIONS)."
  default     = "e2-standard-4"
}

variable "gke_disk_size_gb" {
  type    = number
  default = 50
}

variable "gke_disk_type" {
  type        = string
  description = "Boot disk type for GKE nodes. Use pd-standard to avoid SSD quota limits on fresh projects."
  default     = "pd-standard"
}

variable "artifact_registry_repo_name" {
  type    = string
  default = "login-page-replicator-repo"
}

