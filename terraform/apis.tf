resource "google_project_service" "required" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    # Required for kube-prometheus-stack / Cloud Monitoring integration
    "monitoring.googleapis.com",
    # Required by GKE Autopilot for internal cluster DNS
    "dns.googleapis.com",
    # Required by Workload Identity Federation token exchange
    "sts.googleapis.com",
    # Required for Terraform IAM data sources
    "cloudresourcemanager.googleapis.com"
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

