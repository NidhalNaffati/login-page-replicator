resource "google_container_cluster" "main" {
  name     = var.cluster_name
  location = var.region

  deletion_protection = false

  enable_autopilot = true

  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  depends_on = [
    google_project_service.required,
    google_compute_subnetwork.subnet
  ]
}
