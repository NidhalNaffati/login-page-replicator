#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
# Post-Terraform Cluster Configuration Script
# ═══════════════════════════════════════════════════════════════════════
# This script configures the GKE cluster AFTER Terraform has provisioned
# the infrastructure. It handles:
#   1. Connect to the GKE cluster
#   2. Create namespaces
#   3. Install Helm (if not present)
#   4. Install Argo CD
#   5. Install Prometheus & Grafana
#   6. Deploy Wazuh agents
#   7. Register Argo CD applications
#   8. Create image pull secrets
#   9. Apply network policies
#  10. Display all dashboard credentials
# ═══════════════════════════════════════════════════════════════════════

# ─── Configuration ────────────────────────────────────────────────────
GCP_PROJECT="${GCP_PROJECT:-project-68ed22e3-fde5-4fac-90c}"
GCP_REGION="${GCP_REGION:-europe-west9}"
GCP_ZONE="${GCP_ZONE:-europe-west9-a}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── Helper Functions ─────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[⚠]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*"; }
header()  { echo -e "\n${CYAN}═══════════════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"; }

check_command() {
  if ! command -v "$1" &> /dev/null; then
    error "$1 is not installed. Please install it first."
    return 1
  fi
}

# Portable base64 decode
decode_base64() {
  if echo "" | base64 -d &>/dev/null 2>&1; then
    base64 -d
  else
    base64 --decode
  fi
}

# ─── Pre-flight Checks ───────────────────────────────────────────────
header "Pre-flight Checks"

info "Checking required tools..."
check_command gcloud
check_command kubectl
check_command terraform
success "All required CLI tools are available."

# Check if Helm is installed, install if not
if ! command -v helm &> /dev/null; then
  warn "Helm not found. Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  success "Helm installed."
else
  success "Helm is available: $(helm version --short 2>/dev/null)"
fi

# ═══════════════════════════════════════════════════════════════════════
# PHASE 1: Connect to GKE Cluster
# ═══════════════════════════════════════════════════════════════════════
header "Phase 1: Connecting to GKE Cluster"

info "Reading Terraform outputs..."
cd "${TERRAFORM_DIR}"
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "devops-cluster")
CLUSTER_LOCATION=$(terraform output -raw cluster_location 2>/dev/null || echo "${GCP_REGION}")
WAZUH_INTERNAL_IP=$(terraform output -raw wazuh_manager_internal_ip 2>/dev/null || echo "10.10.0.2")
WAZUH_EXTERNAL_IP=$(terraform output -raw wazuh_manager_external_ip 2>/dev/null || echo "")
cd "${SCRIPT_DIR}"

info "Connecting to cluster '${CLUSTER_NAME}' in '${CLUSTER_LOCATION}'..."
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --region "${CLUSTER_LOCATION}" \
  --project "${GCP_PROJECT}"

# Verify connection
if kubectl cluster-info &>/dev/null; then
  success "Connected to GKE cluster."
  info "Nodes:"
  kubectl get nodes -o wide
else
  error "Failed to connect to cluster. Exiting."
  exit 1
fi

# ═══════════════════════════════════════════════════════════════════════
# PHASE 2: Create Namespaces
# ═══════════════════════════════════════════════════════════════════════
header "Phase 2: Creating Namespaces"

info "Applying namespace definitions..."
kubectl apply -f "${SCRIPT_DIR}/k8s/namespaces.yaml"

info "Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

success "Namespaces created:"
kubectl get namespaces --no-headers | awk '{print "  - " $1}'

# ═══════════════════════════════════════════════════════════════════════
# PHASE 3: Add Helm Repositories
# ═══════════════════════════════════════════════════════════════════════
header "Phase 3: Configuring Helm Repositories"

info "Adding Helm repos..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update

success "Helm repositories configured."

# ═══════════════════════════════════════════════════════════════════════
# PHASE 4: Install Argo CD
# ═══════════════════════════════════════════════════════════════════════
header "Phase 4: Installing Argo CD"

info "Deploying Argo CD to 'argocd' namespace..."
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

info "Waiting for Argo CD components to be ready (timeout: 5 min)..."
kubectl rollout status deploy/argocd-server -n argocd --timeout=300s
kubectl rollout status deploy/argocd-repo-server -n argocd --timeout=300s
kubectl rollout status deploy/argocd-applicationset-controller -n argocd --timeout=300s

success "Argo CD is ready."

# ═══════════════════════════════════════════════════════════════════════
# PHASE 5: Install Prometheus & Grafana
# ═══════════════════════════════════════════════════════════════════════
header "Phase 5: Installing Prometheus & Grafana (kube-prometheus-stack)"

info "Installing kube-prometheus-stack via Helm (timeout: 10 min)..."
helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
  --namespace observability \
  --create-namespace \
  -f "${SCRIPT_DIR}/values-autopilot.yaml" \
  --wait --timeout 10m

info "Applying ServiceMonitor for nginx metrics..."
kubectl apply -f "${SCRIPT_DIR}/k8s/observability/servicemonitor-nginx.yaml"

success "Prometheus & Grafana installed."
info "Observability pods:"
kubectl get pods -n observability --no-headers | awk '{print "  " $1 " → " $3}'

# ═══════════════════════════════════════════════════════════════════════
# PHASE 6: Deploy Wazuh Agents
# ═══════════════════════════════════════════════════════════════════════
header "Phase 6: Deploying Wazuh Agents"

info "Wazuh Manager Internal IP: ${WAZUH_INTERNAL_IP}"

info "Applying base network policies for Wazuh..."
kubectl apply -f "${SCRIPT_DIR}/k8s/security/default-deny.yaml"
kubectl apply -f "${SCRIPT_DIR}/k8s/security/allow-dns-egress.yaml"
kubectl apply -f "${SCRIPT_DIR}/k8s/security/allow-wazuh-egress.yaml"

info "Deploying Wazuh agent DaemonSet..."
kubectl apply -f "${SCRIPT_DIR}/k8s/security/wazuh-agent-daemonset.yaml"

info "Waiting for Wazuh agents rollout (timeout: 3 min)..."
kubectl rollout status daemonset/wazuh-agent -n security --timeout=180s || warn "Wazuh agents may still be starting."

success "Wazuh agents deployed."
kubectl get pods -n security -l app=wazuh-agent --no-headers | awk '{print "  " $1 " → " $3 " (Node: " $7 ")"}'

# ═══════════════════════════════════════════════════════════════════════
# PHASE 7: Register Argo CD Applications
# ═══════════════════════════════════════════════════════════════════════
header "Phase 7: Registering Argo CD Applications"

info "Applying Argo CD Application CRDs..."
kubectl apply -f "${SCRIPT_DIR}/k8s/argocd/app-application.yaml"
kubectl apply -f "${SCRIPT_DIR}/k8s/argocd/testing-application.yaml"

success "Argo CD applications registered."
kubectl get applications -n argocd --no-headers 2>/dev/null | awk '{print "  " $1 " → Sync: " $2 ", Health: " $3}' || warn "Applications may take a moment to appear."

# ═══════════════════════════════════════════════════════════════════════
# PHASE 8: Create Image Pull Secrets
# ═══════════════════════════════════════════════════════════════════════
header "Phase 8: Creating Image Pull Secrets"

info "Configuring Docker authentication for Artifact Registry..."
gcloud auth configure-docker "${GCP_REGION}-docker.pkg.dev" --quiet 2>/dev/null || true

info "Creating ar-pull-secret in app and testing namespaces..."
for NS in app testing; do
  kubectl create secret docker-registry ar-pull-secret \
    --docker-server="${GCP_REGION}-docker.pkg.dev" \
    --docker-username=oauth2accesstoken \
    --docker-password="$(gcloud auth print-access-token)" \
    --namespace="${NS}" \
    --dry-run=client -o yaml | kubectl apply -f -
  success "ar-pull-secret created/updated in '${NS}' namespace."
done

warn "Note: This secret uses a short-lived token (1h). For production, use Workload Identity."

# ═══════════════════════════════════════════════════════════════════════
# PHASE 9: Apply All Network Policies
# ═══════════════════════════════════════════════════════════════════════
header "Phase 9: Applying Network Policies (Zero-Trust)"

info "Applying all network policies via kustomize..."
kubectl apply -k "${SCRIPT_DIR}/k8s/security"

success "Network policies applied:"
kubectl get networkpolicies --all-namespaces --no-headers | awk '{print "  [" $1 "] " $2}'

# ═══════════════════════════════════════════════════════════════════════
# PHASE 10: Final Validation
# ═══════════════════════════════════════════════════════════════════════
header "Phase 10: Validation"

info "Checking all deployments..."
echo ""
kubectl get deployments --all-namespaces --no-headers | awk '{
  status = ($3 == $4) ? "✓" : "⚠";
  printf "  [%s] %-40s %s/%s ready\n", $1, $2, $3, $4
}'

echo ""
info "Checking DaemonSets..."
kubectl get daemonsets --all-namespaces --no-headers | awk '{printf "  [%s] %-30s %s/%s ready\n", $1, $2, $4, $3}'

echo ""
info "Checking Ingress..."
kubectl get ingress --all-namespaces 2>/dev/null || warn "No Ingress found yet (will be created when app is deployed)."

# ═══════════════════════════════════════════════════════════════════════
# SUMMARY: Dashboard Credentials
# ═══════════════════════════════════════════════════════════════════════
header "🎉 Configuration Complete — Dashboard Credentials"

# Retrieve credentials
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" 2>/dev/null | decode_base64 2>/dev/null || echo "<unavailable>")

GRAFANA_PASSWORD=$(kubectl get secret kube-prom-grafana -n observability \
  -o jsonpath='{.data.admin-password}' 2>/dev/null | decode_base64 2>/dev/null || echo "DevOps2025!")

echo -e "
${CYAN}┌──────────────────────────────────────────────────────────────┐${NC}
${CYAN}│${NC}  ${GREEN}📊 GRAFANA${NC}                                                  ${CYAN}│${NC}
${CYAN}│${NC}  URL:      http://localhost:3000  (after port-forward)        ${CYAN}│${NC}
${CYAN}│${NC}  Username: admin                                              ${CYAN}│${NC}
${CYAN}│${NC}  Password: ${GRAFANA_PASSWORD}                                          ${CYAN}│${NC}
${CYAN}├──────────────────────────────────────────────────────────────┤${NC}
${CYAN}│${NC}  ${GREEN}🐙 ARGO CD${NC}                                                  ${CYAN}│${NC}
${CYAN}│${NC}  URL:      https://localhost:8081 (after port-forward)        ${CYAN}│${NC}
${CYAN}│${NC}  Username: admin                                              ${CYAN}│${NC}
${CYAN}│${NC}  Password: ${ARGOCD_PASSWORD}  ${CYAN}│${NC}
${CYAN}├──────────────────────────────────────────────────────────────┤${NC}
${CYAN}│${NC}  ${GREEN}🛡️  WAZUH DASHBOARD${NC}                                          ${CYAN}│${NC}
${CYAN}│${NC}  URL:      https://${WAZUH_EXTERNAL_IP:-<pending>}                          ${CYAN}│${NC}
${CYAN}│${NC}  Username: admin                                              ${CYAN}│${NC}
${CYAN}│${NC}  Password: (retrieve via SSH — see guide Phase 8, step 9.3)  ${CYAN}│${NC}
${CYAN}├──────────────────────────────────────────────────────────────┤${NC}
${CYAN}│${NC}  ${GREEN}🚀 APPLICATION${NC}                                               ${CYAN}│${NC}
${CYAN}│${NC}  URL:      http://localhost:8080  (after port-forward)        ${CYAN}│${NC}
${CYAN}│${NC}  Ingress:  $(kubectl get ingress -n app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '<pending>')                                  ${CYAN}│${NC}
${CYAN}└──────────────────────────────────────────────────────────────┘${NC}
"

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  NEXT STEPS:${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  1. Access dashboards locally:"
echo "     ${GREEN}./port-forward-dashboards.sh${NC}"
echo ""
echo "  2. Get Wazuh password (SSH into VM):"
echo "     ${GREEN}gcloud compute ssh wazuh-manager --zone=${GCP_ZONE} --project=${GCP_PROJECT} \\${NC}"
echo "     ${GREEN}  --tunnel-through-iap --command='cat /etc/motd'${NC}"
echo ""
echo "  3. Push a commit to trigger CI/CD pipeline:"
echo "     ${GREEN}git push origin master${NC}"
echo ""
echo "  4. Get GitHub Actions WIF secrets:"
echo "     ${GREEN}cd terraform && terraform output -raw workload_identity_provider${NC}"
echo "     ${GREEN}cd terraform && terraform output -raw github_actions_sa_email${NC}"
echo ""
echo -e "${GREEN}Done! Your DevSecOps platform is ready. 🚀${NC}"

