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

resource "google_compute_firewall" "wazuh_in" {
  name    = "allow-wazuh-agents"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["1514", "1515", "55000"]
  }

  source_ranges = ["10.10.0.0/20"]
  target_tags   = ["wazuh-manager"]
}

