# ── GKE App Service Account ───────────────────────────────────────────────────
# Used by pods in the `app` namespace to pull images from Artifact Registry
# via Workload Identity (no static keys).

resource "google_service_account" "gke_app" {
  account_id   = "gke-app-sa"
  display_name = "GKE App Service Account"

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_app.email}"
}

data "google_project" "current" {
  project_id = var.project_id
}

# GKE image pulls are performed by cluster runtime identities, not pod workload identity.
# Autopilot commonly uses these service accounts to fetch Artifact Registry tokens.
resource "google_project_iam_member" "artifact_reader_node_sa" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# Required for non-degraded GKE node operations when using the default node SA.
resource "google_project_iam_member" "gke_default_node_sa" {
  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "artifact_reader_gke_service_agent" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:service-${data.google_project.current.number}@container-engine-robot.iam.gserviceaccount.com"
}

# Workload Identity binding: pod SA `app/gke-app-sa` → GCP SA `gke-app-sa`
resource "google_service_account_iam_member" "wi_binding" {
  service_account_id = google_service_account.gke_app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[app/gke-app-sa]"

  depends_on = [google_container_cluster.main]
}

# Workload Identity binding: `testing/playwright-runner` KSA → same GCP SA
# Needed so Playwright Jobs in the `testing` namespace can pull from Artifact Registry.
resource "google_service_account_iam_member" "wi_binding_testing" {
  service_account_id = google_service_account.gke_app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[testing/playwright-runner]"

  depends_on = [google_container_cluster.main]
}

# ── GitHub Actions Service Account ────────────────────────────────────────────
# Used by GitHub Actions CI/CD to: push Docker images, deploy to Cloud Run,
# and get GKE credentials to apply k8s manifests / run Playwright jobs.

resource "google_service_account" "github_actions" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions CI/CD Service Account"

  depends_on = [google_project_service.required]
}

# Push images to Artifact Registry
resource "google_project_iam_member" "github_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Enable/disable GCP APIs from CI (gcloud services enable)
resource "google_project_iam_member" "github_service_usage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Get GKE credentials (needed for kubectl / Playwright Job)
resource "google_project_iam_member" "github_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Deploy to Cloud Run
resource "google_project_iam_member" "github_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Allow SA to act as itself (required for Cloud Run deployments)
resource "google_service_account_iam_member" "github_sa_user" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

# Allow GitHub Actions SA to act as the default compute SA (Cloud Run runtime identity)
resource "google_service_account_iam_member" "github_actas_compute_sa" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.current.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

# Allow unauthenticated access to Cloud Run (public URL)
# Note: apply after the service exists, or Terraform will error if the service is missing.
# TODO: Uncomment after first Cloud Run deploy via GitHub Actions
# resource "google_cloud_run_service_iam_member" "cloud_run_public_invoker" {
#   project  = var.project_id
#   location = var.region
#   service  = var.cloud_run_service_name

#   role   = "roles/run.invoker"
#   member = "allUsers"
# }
