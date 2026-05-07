resource "google_artifact_registry_repository" "docker_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.artifact_registry_repo_name
  description   = "Docker images for login-page-replicator"
  format        = "DOCKER"

  depends_on = [google_project_service.required]
}
