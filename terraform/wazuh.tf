resource "google_compute_instance" "wazuh_manager" {
  name         = "wazuh-manager"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {}
  }

  metadata_startup_script = file("${path.module}/scripts/wazuh-manager-init.sh")
  tags                    = ["wazuh-manager"]

  depends_on = [
    google_project_service.required,
    google_compute_subnetwork.subnet
  ]
}

# Agent communication — nodes CIDR + pods CIDR
resource "google_compute_firewall" "wazuh_agents" {
  name    = "allow-wazuh-agents"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["1514", "1515", "55000"]
  }

  # 10.10.0.0/20 = node subnet, 10.20.0.0/16 = pods CIDR
  source_ranges = ["10.10.0.0/20", "10.20.0.0/16"]
  target_tags   = ["wazuh-manager"]
}

# Dashboard access — restrict to your IP in production
resource "google_compute_firewall" "wazuh_dashboard" {
  name    = "allow-wazuh-dashboard"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"] # restrict to your IP for production
  target_tags   = ["wazuh-manager"]
}

# SSH access via IAP
resource "google_compute_firewall" "wazuh_ssh" {
  name    = "allow-ssh-wazuh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP range — allows gcloud compute ssh without exposing port 22 publicly
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["wazuh-manager"]
}
