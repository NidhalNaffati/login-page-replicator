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

# Get GKE credentials (needed for kubectl / Playwright Job)
resource "google_project_iam_member" "github_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Deploy to Cloud Run
resource "google_project_iam_member" "github_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Allow SA to act as itself (required for Cloud Run deployments)
resource "google_service_account_iam_member" "github_sa_user" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

