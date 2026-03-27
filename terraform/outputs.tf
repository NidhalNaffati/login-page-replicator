output "cluster_name" {
  value = google_container_cluster.main.name
}

output "cluster_location" {
  value = google_container_cluster.main.location
}

output "gke_app_service_account_email" {
  value = google_service_account.gke_app.email
}

output "wazuh_manager_internal_ip" {
  value = google_compute_instance.wazuh_manager.network_interface[0].network_ip
}

output "wazuh_manager_external_ip" {
  value = google_compute_instance.wazuh_manager.network_interface[0].access_config[0].nat_ip
}

