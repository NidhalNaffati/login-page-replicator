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
#
# Optional environment variables:
#   - PROJECT_ID        Override the default project
#   - REGION            Override the default region
#   - REPO_NAME         Override the Artifact Registry repo name
#   - SERVICE_NAME      Override the Cloud Run service name
#   - NO_PROMPT=1       Disable prompts (fail fast instead)
# =============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
PROJECT_ID="${PROJECT_ID:-pfe-esprit-489411}"       # GCP project ID
REGION="${REGION:-europe-west1}"                   # ← Replace with your preferred region
REPO_NAME="${REPO_NAME:-login-page-replicator-repo}"  # Artifact Registry repository name
SERVICE_NAME="${SERVICE_NAME:-login-page-replicator}"  # Cloud Run service name
IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
# ──────────────────────────────────────────────────────────────────────────────

IMAGE_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}"
IMAGE_VERSIONED="${IMAGE_BASE}:${IMAGE_TAG}"
IMAGE_LATEST="${IMAGE_BASE}:latest"

NO_PROMPT="${NO_PROMPT:-}"

is_tty() { [[ -t 0 && -t 1 ]]; }
can_prompt() {
  [[ -z "${NO_PROMPT}" ]] && is_tty && [[ -z "${CI:-}" ]];
}

die() { echo "ERROR: $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command '$1'. Please install it and retry."
}

prompt_yn() {
  # Usage: prompt_yn "Question" "default"(y/n)
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

prompt_choice() {
  # Usage: prompt_choice "Title" choices...
  local title="$1"; shift
  local -a choices=("$@")
  can_prompt || die "Cannot prompt in this environment. Re-run with a TTY or set NO_PROMPT= (default) and avoid CI."

  echo "$title"
  local i
  for i in "${!choices[@]}"; do
    printf "  %d) %s\n" "$((i+1))" "${choices[$i]}"
  done
  local idx
  while true; do
    read -r -p "Select an option (1-${#choices[@]}): " idx
    [[ "$idx" =~ ^[0-9]+$ ]] || { echo "Enter a number."; continue; }
    (( idx >= 1 && idx <= ${#choices[@]} )) || { echo "Out of range."; continue; }
    echo "${choices[$((idx-1))]}"
    return 0
  done
}

ensure_gcloud_auth() {
  # 1) Ensure gcloud exists
  require_cmd gcloud

  # 2) If already has an active account, we're done
  local active
  active="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true)"
  if [[ -n "$active" ]]; then
    return 0
  fi

  # 3) If there are accounts but none active, allow selecting
  local accounts
  accounts="$(gcloud auth list --format='value(account)' 2>/dev/null || true)"
  if [[ -n "$accounts" ]]; then
    if can_prompt; then
      echo "No active gcloud account is selected."
      local selected
      # Convert newline list into array
      mapfile -t _accs <<<"$accounts"
      selected="$(prompt_choice "Pick an account to use:" "${_accs[@]}")"
      gcloud config set account "$selected" >/dev/null
      return 0
    fi
    die "You have authenticated accounts but none selected. Run: gcloud auth list && gcloud config set account ACCOUNT"
  fi

  # 4) No accounts at all: suggest login
  if can_prompt; then
    echo "gcloud is not authenticated yet."
    if prompt_yn "Login now?" "y"; then
      # Offer device flow which works everywhere, and regular browser login
      local mode
      mode="$(prompt_choice "Choose login method:" \
        "Browser login (gcloud auth login)" \
        "Device login / no-browser (gcloud auth login --no-browser)")"
      if [[ "$mode" == "Device login / no-browser (gcloud auth login --no-browser)" ]]; then
        gcloud auth login --no-browser
      else
        gcloud auth login
      fi
    else
      die "Not logged in. Aborting."
    fi
  else
    die "No active gcloud account. Run: gcloud auth login"
  fi

  active="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true)"
  [[ -n "$active" ]] || die "Login did not result in an active account. Run: gcloud auth list && gcloud config set account ACCOUNT"
}

ensure_project_set() {
  local configured
  configured="$(gcloud config get-value project 2>/dev/null || true)"

  if [[ -n "$configured" && "$configured" == "$PROJECT_ID" ]]; then
    return 0
  fi

  if [[ -n "$configured" && "$configured" != "(unset)" && "$configured" != "" ]]; then
    echo "Current gcloud project: $configured"
  fi

  if can_prompt; then
    if prompt_yn "Use project '${PROJECT_ID}' for this deploy?" "y"; then
      gcloud config set project "${PROJECT_ID}" >/dev/null
      return 0
    fi

    # Allow user to enter an alternative project ID
    local new_project
    read -r -p "Enter GCP project ID to use: " new_project
    [[ -n "$new_project" ]] || die "Project ID cannot be empty."
    PROJECT_ID="$new_project"
    IMAGE_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}"
    IMAGE_VERSIONED="${IMAGE_BASE}:${IMAGE_TAG}"
    IMAGE_LATEST="${IMAGE_BASE}:latest"
    gcloud config set project "${PROJECT_ID}" >/dev/null
    return 0
  fi

  # Non-interactive: just set it
  gcloud config set project "${PROJECT_ID}" >/dev/null
}

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

# ── Preflight: tools + auth + project ────────────────────────────────────────
ensure_gcloud_auth
ensure_project_set
require_cmd docker

# ── Step 1: Set the active GCP project ───────────────────────────────────────
echo "▶ [1/5] Setting active GCP project..."
gcloud config set project "${PROJECT_ID}" >/dev/null

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
