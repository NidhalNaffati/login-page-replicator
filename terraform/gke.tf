resource "google_container_cluster" "main" {
  name     = var.cluster_name
  location = var.region

  deletion_protection = false

  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  # VPC-native (alias IPs) using secondary ranges defined in network.tf.
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # This repo relies heavily on NetworkPolicies (default-deny + allow rules).
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  # We'll manage node pools explicitly.
  remove_default_node_pool = true
  initial_node_count       = 1

  depends_on = [
    google_project_service.required,
    google_compute_subnetwork.subnet
  ]
}

resource "google_container_node_pool" "primary" {
  name     = "primary-pool"
  location = var.region
  cluster  = google_container_cluster.main.name

  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }

  node_count = var.gke_node_count

  node_config {
    machine_type = var.gke_machine_type
    disk_size_gb = var.gke_disk_size_gb
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

