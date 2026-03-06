#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Build, push to Artifact Registry, and deploy to Cloud Run
# =============================================================================
# Prerequisites:
#   - gcloud CLI installed and authenticated  (gcloud auth login)
#   - Docker installed and configured for gcloud  (gcloud auth configure-docker)
#   - Artifact Registry API enabled
#   - Cloud Run API enabled
#
# Usage:
#   chmod +x deploy.sh
#   ./deploy.sh
# =============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
PROJECT_ID="pfe-esprit-489411"       # GCP project ID
REGION="europe-west1"                   # ← Replace with your preferred region
REPO_NAME="login-page-replicator-repo"  # Artifact Registry repository name
SERVICE_NAME="login-page-replicator"    # Cloud Run service name
IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
# ──────────────────────────────────────────────────────────────────────────────

IMAGE_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}"
IMAGE_VERSIONED="${IMAGE_BASE}:${IMAGE_TAG}"
IMAGE_LATEST="${IMAGE_BASE}:latest"

echo "╔══════════════════════════════════════════════════════╗"
echo "║         GCP Artifact Registry + Cloud Run Deploy     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Project  : ${PROJECT_ID}"
echo "  Region   : ${REGION}"
echo "  Repo     : ${REPO_NAME}"
echo "  Service  : ${SERVICE_NAME}"
echo "  Tag      : ${IMAGE_TAG}"
echo ""

# ── Step 1: Set the active GCP project ───────────────────────────────────────
echo "▶ [1/5] Setting active GCP project..."
gcloud config set project "${PROJECT_ID}"

# ── Step 2: Enable required APIs ─────────────────────────────────────────────
echo "▶ [2/5] Enabling required GCP APIs (idempotent)..."
gcloud services enable \
  artifactregistry.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  --quiet

# ── Step 3: Create Artifact Registry repository (if it doesn't exist) ────────
echo "▶ [3/5] Ensuring Artifact Registry repository exists..."
if ! gcloud artifacts repositories describe "${REPO_NAME}" \
    --location="${REGION}" --quiet 2>/dev/null; then
  echo "   Repository not found — creating it..."
  gcloud artifacts repositories create "${REPO_NAME}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="Docker images for ${SERVICE_NAME}"
  echo "   ✔ Repository created."
else
  echo "   ✔ Repository already exists."
fi

# ── Step 4: Configure Docker to authenticate with Artifact Registry ───────────
echo "▶ [4/5] Configuring Docker authentication for Artifact Registry..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

# ── Step 5: Build and push the Docker image ───────────────────────────────────
echo "▶ [5/5] Building Docker image..."
docker build \
  -t "${IMAGE_VERSIONED}" \
  -t "${IMAGE_LATEST}" \
  .

echo "   Pushing versioned tag: ${IMAGE_VERSIONED}"
docker push "${IMAGE_VERSIONED}"

echo "   Pushing latest tag:    ${IMAGE_LATEST}"
docker push "${IMAGE_LATEST}"

# ── Step 6: Deploy to Cloud Run ───────────────────────────────────────────────
echo ""
echo "▶ [6/6] Deploying to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
  --image="${IMAGE_VERSIONED}" \
  --region="${REGION}" \
  --platform=managed \
  --allow-unauthenticated \
  --port=80 \
  --memory=256Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --quiet

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✅ Deployment complete!"
echo ""
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" \
  --region="${REGION}" \
  --format="value(status.url)")
echo "🌐 Service URL: ${SERVICE_URL}"

