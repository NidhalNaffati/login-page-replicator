#!/usr/bin/env bash
# =============================================================================
# deploy-grafana.sh — Deploy provisioned (immutable) Grafana to Cloud Run
# =============================================================================
# What this does:
#   - Ensures gcloud is authenticated + project is set
#   - Ensures required APIs are enabled
#   - Ensures Artifact Registry repo exists
#   - Builds/pushes the Grafana image from ./grafana
#   - Deploys a Cloud Run service running Grafana
#
# Credentials:
#   This script explicitly sets Grafana admin credentials via env vars:
#     user: TNEEIN
#     pass: 4YOU
#
#   IMPORTANT:
#   - GF_SECURITY_ADMIN_PASSWORD is deployed via Secret Manager env var (not a literal)
#     to avoid type conflicts with existing Cloud Run config.
#
# Optional environment variables:
#   - PROJECT_ID            (default: pfe-esprit-489411)
#   - REGION                (default: europe-west1)
#   - REPO_NAME             (default: login-page-replicator-repo)
#   - GRAFANA_SERVICE_NAME  (default: login-page-replicator-grafana)
#   - GRAFANA_SA_EMAIL      (default: empty; recommended to set)
#   - NO_PROMPT=1           Disable prompts (fail fast)
#   - ALLOW_PUBLIC_GRAFANA=1  Deploy with --allow-unauthenticated
# =============================================================================

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-pfe-esprit-489411}"
REGION="${REGION:-europe-west1}"
REPO_NAME="${REPO_NAME:-login-page-replicator-repo}"
GRAFANA_SERVICE_NAME="${GRAFANA_SERVICE_NAME:-login-page-replicator-grafana}"
GRAFANA_SA_EMAIL="${GRAFANA_SA_EMAIL:-}"
NO_PROMPT="${NO_PROMPT:-}"

# Explicit credentials requested
GRAFANA_ADMIN_USER="TNEEIN"
GRAFANA_ADMIN_PASSWORD="4YOU"

# Secret Manager secret used by the Cloud Run service for the admin password
GRAFANA_ADMIN_PASSWORD_SECRET_NAME="${GRAFANA_ADMIN_PASSWORD_SECRET_NAME:-grafana-admin-password}"

IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
GRAFANA_IMAGE_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${GRAFANA_SERVICE_NAME}"
GRAFANA_IMAGE_VERSIONED="${GRAFANA_IMAGE_BASE}:${IMAGE_TAG}"
GRAFANA_IMAGE_LATEST="${GRAFANA_IMAGE_BASE}:latest"

is_tty() { [[ -t 0 && -t 1 ]]; }
can_prompt() { [[ -z "${NO_PROMPT}" ]] && is_tty && [[ -z "${CI:-}" ]]; }

die() { echo "ERROR: $*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command '$1'."; }

prompt_yn() {
  local q="$1" default="${2:-y}" ans
  if ! can_prompt; then
    [[ "$default" == "y" ]] && return 0 || return 1
  fi
  local suffix="[y/N]"; [[ "$default" == "y" ]] && suffix="[Y/n]"
  while true; do
    read -r -p "${q} ${suffix} " ans || return 1
    ans="${ans:-$default}"
    case "${ans,,}" in
      y|yes) return 0;;
      n|no) return 1;;
      *) echo "Please answer y or n.";;
    esac
  done
}

ensure_gcloud_auth() {
  require_cmd gcloud

  local active
  active="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true)"
  [[ -n "$active" ]] && return 0

  local accounts
  accounts="$(gcloud auth list --format='value(account)' 2>/dev/null || true)"
  if [[ -n "$accounts" ]]; then
    die "No active gcloud account selected. Run: gcloud auth list && gcloud config set account ACCOUNT"
  fi

  if can_prompt && prompt_yn "gcloud is not authenticated. Login now?" "y"; then
    gcloud auth login
  else
    die "No active gcloud account. Run: gcloud auth login"
  fi
}

ensure_project_set() {
  gcloud config set project "${PROJECT_ID}" >/dev/null
}

echo "╔══════════════════════════════════════════════════════╗"
echo "║           Grafana (Cloud Monitoring) Deploy          ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Project : ${PROJECT_ID}"
echo "  Region  : ${REGION}"
echo "  Repo    : ${REPO_NAME}"
echo "  Service : ${GRAFANA_SERVICE_NAME}"
echo "  Tag     : ${IMAGE_TAG}"
echo ""

ensure_gcloud_auth
ensure_project_set
require_cmd docker

echo "▶ Enabling required GCP APIs (idempotent)..."
gcloud services enable \
  artifactregistry.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  --quiet

echo "▶ Ensuring Artifact Registry repository exists..."
if ! gcloud artifacts repositories describe "${REPO_NAME}" \
    --location="${REGION}" --quiet 2>/dev/null; then
  gcloud artifacts repositories create "${REPO_NAME}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="Docker images for ${GRAFANA_SERVICE_NAME}"
fi

echo "▶ Configuring Docker authentication for Artifact Registry..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

echo "▶ Building Grafana image (immutable provisioning)..."
docker build \
  -f ./grafana/Dockerfile \
  -t "${GRAFANA_IMAGE_VERSIONED}" \
  -t "${GRAFANA_IMAGE_LATEST}" \
  ./grafana

echo "▶ Pushing Grafana image..."
docker push "${GRAFANA_IMAGE_VERSIONED}"
docker push "${GRAFANA_IMAGE_LATEST}"

echo "▶ Ensuring Secret Manager secret exists (Grafana admin password)..."
if ! gcloud secrets describe "${GRAFANA_ADMIN_PASSWORD_SECRET_NAME}" --project="${PROJECT_ID}" --quiet >/dev/null 2>&1; then
  gcloud secrets create "${GRAFANA_ADMIN_PASSWORD_SECRET_NAME}" --project="${PROJECT_ID}" --replication-policy="automatic" >/dev/null
fi

# Always add a new version so the service can be redeployed deterministically.
printf "%s" "${GRAFANA_ADMIN_PASSWORD}" | gcloud secrets versions add "${GRAFANA_ADMIN_PASSWORD_SECRET_NAME}" --project="${PROJECT_ID}" --data-file=- >/dev/null

echo "▶ Deploying Grafana to Cloud Run..."
GRAFANA_ARGS=(
  run deploy "${GRAFANA_SERVICE_NAME}"
  --image="${GRAFANA_IMAGE_VERSIONED}"
  --region="${REGION}"
  --platform=managed
  --port=3000
  --memory=512Mi
  --cpu=1
  --min-instances=0
  --max-instances=2
  --set-env-vars="GCP_PROJECT=${PROJECT_ID},GF_SERVER_HTTP_PORT=3000,GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER}"
  --set-secrets="GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD_SECRET_NAME}:latest"
  --quiet
)

if [[ -n "${ALLOW_PUBLIC_GRAFANA:-}" ]]; then
  GRAFANA_ARGS+=(--allow-unauthenticated)
else
  GRAFANA_ARGS+=(--no-allow-unauthenticated)
fi

if [[ -n "${GRAFANA_SA_EMAIL}" ]]; then
  GRAFANA_ARGS+=(--service-account="${GRAFANA_SA_EMAIL}")
fi

gcloud "${GRAFANA_ARGS[@]}"

echo ""
echo "✅ Grafana deployed."
echo "URL: $(gcloud run services describe "${GRAFANA_SERVICE_NAME}" --region="${REGION}" --format="value(status.url)")"
echo "Login: ${GRAFANA_ADMIN_USER} / ${GRAFANA_ADMIN_PASSWORD}"
