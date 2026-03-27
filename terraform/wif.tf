# ──────────────────────────────────────────────────────────────────────────────
# Workload Identity Federation — lets GitHub Actions authenticate to GCP
# without long-lived service account keys.
# ──────────────────────────────────────────────────────────────────────────────

# 1. WIF Pool
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
  description               = "WIF pool for GitHub Actions CI/CD"

  depends_on = [google_project_service.required]
}

# 2. WIF Provider — trusts tokens from github.com for this specific repo
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Restricts which repo can impersonate the SA:
  # attribute_condition filters to NidhalNaffati/login-page-replicator only.
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "attribute.repository == 'NidhalNaffati/login-page-replicator'"

  depends_on = [google_iam_workload_identity_pool.github]
}

# 3. Allow tokens from the WIF provider to impersonate github-actions-sa
resource "google_service_account_iam_member" "github_actions_wi" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/NidhalNaffati/login-page-replicator"
}

# 4. Output the WIF provider resource name — paste this into GitHub Actions secrets
output "workload_identity_provider" {
  description = "Value for GCP_WORKLOAD_IDENTITY_PROVIDER secret in GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_actions_sa_email" {
  description = "Value for GCP_SERVICE_ACCOUNT secret in GitHub Actions"
  value       = google_service_account.github_actions.email
}
