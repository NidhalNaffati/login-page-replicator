# Full Project Recreation Guide — DevSecOps GKE Platform

> **Target:** Recreate the entire DevSecOps platform from scratch on a **new GCP project**.
> **Cluster type:** GKE Standard (regional, with Calico NetworkPolicies)
> **Region:** `europe-west1`
> **Estimated time:** 45–60 minutes (excluding Terraform provisioning)

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Phase 1 — GCP Project Setup](#2-phase-1--gcp-project-setup)
3. [Phase 2 — Terraform Infrastructure](#3-phase-2--terraform-infrastructure)
4. [Phase 3 — Connect to GKE Cluster](#4-phase-3--connect-to-gke-cluster)
5. [Phase 4 — Create Namespaces](#5-phase-4--create-namespaces)
6. [Phase 5 — Install Helm](#6-phase-5--install-helm)
7. [Phase 6 — Install Argo CD](#7-phase-6--install-argo-cd)
8. [Phase 7 — Install Prometheus & Grafana](#8-phase-7--install-prometheus--grafana)
9. [Phase 8 — Install & Configure Wazuh](#9-phase-8--install--configure-wazuh)
10. [Phase 9 — Deploy Application via Argo CD](#10-phase-9--deploy-application-via-argo-cd)
11. [Phase 10 — Apply Network Policies](#11-phase-10--apply-network-policies)
12. [Phase 11 — Configure GitHub Actions](#12-phase-11--configure-github-actions)
13. [Phase 12 — Validation & Smoke Tests](#13-phase-12--validation--smoke-tests)
14. [Improvements & Recommendations](#14-improvements--recommendations)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. Prerequisites

### Tools to install locally

| Tool | Version | Install |
|------|---------|---------|
| `gcloud` CLI | Latest | https://cloud.google.com/sdk/docs/install |
| `terraform` | >= 1.5 | https://developer.hashicorp.com/terraform/install |
| `kubectl` | >= 1.28 | `gcloud components install kubectl` |
| `helm` | >= 3.12 | See [Phase 5](#6-phase-5--install-helm) |
| `docker` | Latest | https://docs.docker.com/get-docker/ |
| `bun` | Latest | https://bun.sh/ (optional, for local dev) |

### GCP requirements

- A new GCP project with **billing enabled**
- Owner or Editor role on the project
- Sufficient quotas in `europe-west1`:
  - CPUs (all regions): at least 12 vCPUs (3 nodes × e2-standard-4)
  - In-use IP addresses: at least 5
  - Persistent disk (pd-standard): at least 200 GB

---

## 2. Phase 1 — GCP Project Setup

### 2.1 Authenticate and set project

```bash
# Login to GCP
gcloud auth login

# Set your NEW project ID (replace with your actual project ID)
export PROJECT_ID="your-new-project-id"
export REGION="europe-west1"
export ZONE="europe-west1-b"

gcloud config set project ${PROJECT_ID}
gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${ZONE}
```

### 2.2 Verify billing is enabled

```bash
gcloud billing projects describe ${PROJECT_ID}
```

> If billing is not linked, go to: https://console.cloud.google.com/billing/linkedaccount?project=${PROJECT_ID}

### 2.3 Enable base APIs (Terraform will enable the rest, but these are needed to start)

```bash
gcloud services enable \
  serviceusage.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project=${PROJECT_ID}
```

---

## 3. Phase 2 — Terraform Infrastructure

Terraform provisions: VPC, subnet, GKE cluster, node pool, Artifact Registry, IAM service accounts, Workload Identity Federation, Wazuh VM + firewall rules.

### 3.1 Create the remote state bucket

```bash
export TFSTATE_BUCKET="${PROJECT_ID}-tfstate"

# Create the GCS bucket for Terraform state
gcloud storage buckets create "gs://${TFSTATE_BUCKET}" \
  --location="${REGION}" \
  --uniform-bucket-level-access \
  --project=${PROJECT_ID}

# Enable versioning (state recovery)
gcloud storage buckets update "gs://${TFSTATE_BUCKET}" --versioning
```

### 3.2 Configure Terraform backend

```bash
cd terraform

# Create backend config from template
cp backend.hcl.example backend.hcl
```

Edit `backend.hcl`:
```hcl
bucket = "your-new-project-id-tfstate"
prefix = "devops-cluster"
```

### 3.3 Update variables for your new project

Before running Terraform, you need to update the project-specific references:

**Option A (recommended):** Pass variables via CLI:
```bash
terraform plan -var="project_id=${PROJECT_ID}" -var="region=${REGION}"
```

**Option B:** Edit `variables.tf` default values to match your new project ID.

### 3.4 Update WIF repo restriction (IMPORTANT)

In `terraform/wif.tf`, update the GitHub repository reference to match YOUR repository:

```hcl
# Line: attribute_condition
attribute_condition = "attribute.repository == 'YOUR-GITHUB-USERNAME/login-page-replicator'"
```

And the IAM member:
```hcl
member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/YOUR-GITHUB-USERNAME/login-page-replicator"
```

### 3.5 Update Kubernetes manifest references

The following files reference the GCP project ID. Update them **before** deploying:

| File | What to change |
|------|---------------|
| `k8s/namespaces.yaml` | `gke-app-sa@PROJECT_ID.iam.gserviceaccount.com` |
| `k8s/app/serviceaccount.yaml` | `gke-app-sa@PROJECT_ID.iam.gserviceaccount.com` |
| `k8s/testing/serviceaccount.yaml` | `gke-app-sa@PROJECT_ID.iam.gserviceaccount.com` |
| `k8s/app/deployment.yaml` | Image URL `europe-west1-docker.pkg.dev/PROJECT_ID/...` |
| `k8s/app/playwright-hook.yaml` | Image URL `europe-west1-docker.pkg.dev/PROJECT_ID/...` |
| `.github/workflows/deploy.yml` | `env.PROJECT_ID`, `env.IMAGE_BASE`, `env.PW_IMAGE` |

Quick sed replacement (Linux/macOS):
```bash
# From project root
OLD_PROJECT="nidhal-pfe"
NEW_PROJECT="${PROJECT_ID}"

find k8s/ .github/ -type f \( -name "*.yaml" -o -name "*.yml" \) \
  -exec sed -i "s/${OLD_PROJECT}/${NEW_PROJECT}/g" {} +
```

### 3.6 Initialize and apply Terraform

```bash
cd terraform

# Initialize with backend config
terraform init -backend-config=backend.hcl

# Preview changes
terraform plan \
  -var="project_id=${PROJECT_ID}" \
  -var="region=${REGION}" \
  -out=tfplan

# Review the plan, then apply
terraform apply tfplan
```

> ⏱ This takes **10–15 minutes** (GKE cluster creation is the slowest part).

### 3.7 Save Terraform outputs

```bash
# These are needed later for GitHub secrets and Wazuh config
terraform output -raw cluster_name
terraform output -raw cluster_location
terraform output -raw workload_identity_provider
terraform output -raw github_actions_sa_email
terraform output -raw wazuh_manager_internal_ip
terraform output -raw wazuh_manager_external_ip
```

**Save these values — you'll need them in Phase 11.**

---

## 4. Phase 3 — Connect to GKE Cluster

```bash
# Get cluster credentials
CLUSTER_NAME=$(cd terraform && terraform output -raw cluster_name)
CLUSTER_LOCATION=$(cd terraform && terraform output -raw cluster_location)

gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --region "${CLUSTER_LOCATION}" \
  --project "${PROJECT_ID}"
```

### Verify connection

```bash
kubectl get nodes
# Expected: 3 nodes (1 per zone in europe-west1)

kubectl cluster-info
```

---

## 5. Phase 4 — Create Namespaces

The project uses 4 namespaces + `argocd`:

| Namespace | Purpose |
|-----------|---------|
| `app` | Main application deployment |
| `testing` | Playwright E2E test jobs |
| `observability` | Prometheus, Grafana |
| `security` | Wazuh agent DaemonSet |
| `argocd` | Argo CD (GitOps controller) |

```bash
# Apply namespace definitions (app, testing, observability, security)
kubectl apply -f k8s/namespaces.yaml

# Create argocd namespace
kubectl create namespace argocd

# Verify
kubectl get namespaces
```

Expected output:
```
NAME              STATUS   AGE
app               Active   ...
argocd            Active   ...
default           Active   ...
kube-node-lease   Active   ...
kube-public       Active   ...
kube-system       Active   ...
observability     Active   ...
security          Active   ...
testing           Active   ...
```

---

## 6. Phase 5 — Install Helm

### Linux/macOS

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Windows (PowerShell)

```powershell
# Using Chocolatey
choco install kubernetes-helm

# Or using Scoop
scoop install helm
```

### Alternative: gcloud component

```bash
gcloud components install helm
```

### Verify installation

```bash
helm version
# Expected: version.BuildInfo{Version:"v3.x.x", ...}
```

### Add required Helm repositories

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

---

## 7. Phase 6 — Install Argo CD

Argo CD is the GitOps engine that automatically deploys your application when K8s manifests change in Git.

### 7.1 Install Argo CD

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 7.2 Wait for Argo CD to be ready

```bash
echo "Waiting for Argo CD components to start..."
kubectl rollout status deploy/argocd-server -n argocd --timeout=300s
kubectl rollout status deploy/argocd-repo-server -n argocd --timeout=300s
kubectl rollout status deploy/argocd-applicationset-controller -n argocd --timeout=300s
```

### 7.3 Get the initial admin password

```bash
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD admin password: ${ARGOCD_PASSWORD}"
```

> **Save this password!** You'll need it to access the Argo CD dashboard.

### 7.4 Access the Argo CD Dashboard (optional)

```bash
# Port-forward to access locally
kubectl port-forward svc/argocd-server -n argocd 8081:443 &

# Open in browser
echo "Argo CD UI: https://localhost:8081"
echo "Username: admin"
echo "Password: ${ARGOCD_PASSWORD}"
```

### 7.5 Register GitOps Applications

These tell Argo CD to watch your Git repo and auto-deploy changes:

```bash
# Main application (deploys k8s/app/ → app namespace)
kubectl apply -f k8s/argocd/app-application.yaml

# Testing resources (deploys k8s/testing/ → testing namespace)
kubectl apply -f k8s/argocd/testing-application.yaml
```

> **If you forked the repo:** Update `repoURL` in both files to point to YOUR repository URL.

### 7.6 Verify Argo CD Applications

```bash
kubectl get applications -n argocd
```

Expected:
```
NAME                             SYNC STATUS   HEALTH STATUS
login-page-replicator            Synced        Healthy
login-page-replicator-testing    Synced        Healthy
```

> Note: The apps will initially show as `OutOfSync` or `Degraded` until images are pushed (Phase 9).

---

## 8. Phase 7 — Install Prometheus & Grafana

We use the `kube-prometheus-stack` Helm chart with custom values optimized for GKE Standard (lighter resources, disabled node-level components that require host access).

### 8.1 Install kube-prometheus-stack

```bash
helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
  --namespace observability \
  --create-namespace \
  -f values-autopilot.yaml \
  --wait --timeout 10m
```

> ⏱ This takes **3–5 minutes** to deploy all components.

### 8.2 Verify installation

```bash
kubectl get pods -n observability
```

Expected pods:
```
NAME                                                   READY   STATUS    RESTARTS
kube-prom-grafana-xxxxx                                3/3     Running   0
kube-prom-kube-state-metrics-xxxxx                     1/1     Running   0
kube-prom-prometheus-operator-xxxxx                    1/1     Running   0
prometheus-kube-prom-prometheus-0                      2/2     Running   0
alertmanager-kube-prom-alertmanager-0                  2/2     Running   0
```

### 8.3 Apply ServiceMonitor for the application

This tells Prometheus to scrape metrics from the nginx-exporter sidecar:

```bash
kubectl apply -f k8s/observability/servicemonitor-nginx.yaml
```

### 8.4 Access Grafana (optional)

```bash
kubectl port-forward svc/kube-prom-grafana -n observability 3000:80 &

echo "Grafana UI: http://localhost:3000"
echo "Username: admin"
echo "Password: DevOps2025!"
```

### 8.5 Verify Prometheus targets

```bash
kubectl port-forward svc/kube-prom-prometheus -n observability 9090:9090 &
# Open http://localhost:9090/targets — look for "serviceMonitor/observability/nginx-metrics"
```

---

## 9. Phase 8 — Install & Configure Wazuh

Wazuh provides security monitoring (SIEM) with agents running on each GKE node collecting container logs.

### Architecture

```
┌─────────────────────────────────────────────────────┐
│  GKE Standard Cluster                               │
│                                                     │
│  ┌─────────────┐     TCP 1514    ┌──────────────┐  │
│  │ security ns │ ──────────────► │  Wazuh VM    │  │
│  │ DaemonSet   │     TCP 1515    │  10.10.0.x   │  │
│  │ (3 agents)  │                 │  e2-medium   │  │
│  └─────────────┘                 └──────────────┘  │
│                                       │             │
│  Collects:                            │ HTTPS:443   │
│  /var/log/containers/*.log            ▼             │
│  /var/log/pods/*/*/*.log         Dashboard          │
│                                  (external IP)      │
└─────────────────────────────────────────────────────┘
```

### 9.1 Verify Wazuh VM is running (created by Terraform)

```bash
# Get the Wazuh VM IPs
WAZUH_INTERNAL_IP=$(cd terraform && terraform output -raw wazuh_manager_internal_ip)
WAZUH_EXTERNAL_IP=$(cd terraform && terraform output -raw wazuh_manager_external_ip)

echo "Wazuh Internal IP: ${WAZUH_INTERNAL_IP}"
echo "Wazuh External IP: ${WAZUH_EXTERNAL_IP}"

# Check VM status
gcloud compute instances describe wazuh-manager \
  --zone=${ZONE} \
  --project=${PROJECT_ID} \
  --format='get(status)'
# Expected: RUNNING
```

### 9.2 Wait for Wazuh installation to complete (first boot)

The Wazuh bootstrap script (`terraform/scripts/wazuh-manager-init.sh`) runs on first boot and takes **5–10 minutes**. Check progress:

```bash
# SSH into the VM via IAP
gcloud compute ssh wazuh-manager \
  --zone=${ZONE} \
  --project=${PROJECT_ID} \
  --tunnel-through-iap \
  --command='tail -20 /var/log/wazuh-install.log'
```

Wait until you see `Installation finished` or similar success message.

### 9.3 Retrieve Wazuh admin credentials

```bash
gcloud compute ssh wazuh-manager \
  --zone=${ZONE} \
  --project=${PROJECT_ID} \
  --tunnel-through-iap \
  --command='cat /etc/motd'
```

Output will show:
```
Wazuh 4.14 installed successfully.
Dashboard: https://<external-ip>
User:       admin
Password:   <auto-generated-password>
```

**Save the password!**

Alternative — extract from the install archive:
```bash
gcloud compute ssh wazuh-manager \
  --zone=${ZONE} \
  --project=${PROJECT_ID} \
  --tunnel-through-iap \
  --command='sudo tar -xOf ~/wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt | grep -A2 "username: .admin."'
```

### 9.4 Verify Wazuh services are healthy

```bash
gcloud compute ssh wazuh-manager \
  --zone=${ZONE} \
  --project=${PROJECT_ID} \
  --tunnel-through-iap \
  --command='sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard --no-pager'
```

All 3 services must show `active (running)`.

### 9.5 Update Wazuh agent DaemonSet with correct manager IP

Edit `k8s/security/wazuh-agent-daemonset.yaml` — ensure the `<address>` matches your Wazuh VM's internal IP:

```xml
<server>
  <address>10.10.0.2</address>   <!-- Replace with ${WAZUH_INTERNAL_IP} if different -->
  <port>1514</port>
  <protocol>tcp</protocol>
</server>
```

Also update `k8s/security/allow-wazuh-egress.yaml` if the IP differs:
```yaml
- ipBlock:
    cidr: 10.10.0.2/32    # Replace with ${WAZUH_INTERNAL_IP}/32
```

### 9.6 Deploy Wazuh agents to GKE

```bash
# Apply the required network policies first
kubectl apply -f k8s/security/default-deny.yaml
kubectl apply -f k8s/security/allow-dns-egress.yaml
kubectl apply -f k8s/security/allow-wazuh-egress.yaml

# Deploy the Wazuh agent DaemonSet
kubectl apply -f k8s/security/wazuh-agent-daemonset.yaml

# Wait for rollout
kubectl rollout status daemonset/wazuh-agent -n security --timeout=180s
```

### 9.7 Verify agent enrollment

```bash
# Check pods are running (1 per node = 3 for a 3-node cluster)
kubectl get pods -n security -l app=wazuh-agent -o wide

# Check agent logs for successful enrollment
kubectl logs -n security -l app=wazuh-agent --tail=30 | grep -E "INFO|ERROR|Started"
```

Look for:
- ✅ `Requesting a key from server: 10.10.0.x`
- ✅ `wazuh-agentd: INFO: Started`
- ✅ `wazuh-logcollector: INFO: Started`

### 9.8 Verify agents appear in Wazuh Manager

```bash
gcloud compute ssh wazuh-manager \
  --zone=${ZONE} \
  --project=${PROJECT_ID} \
  --tunnel-through-iap \
  --command='sudo /var/ossec/bin/agent_control -l'
```

Expected: 3 active agents (one per GKE node).

### 9.9 Access Wazuh Dashboard

Open in browser:
```
URL:      https://<WAZUH_EXTERNAL_IP>
Username: admin
Password: <from step 9.3>
```

> Accept the self-signed certificate warning.

---

## 10. Phase 9 — Deploy Application via Argo CD

### 10.1 Create the image pull secret

The cluster needs credentials to pull images from Artifact Registry:

```bash
# Authenticate Docker locally
gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

# Create ar-pull-secret in both namespaces
for NS in app testing; do
  kubectl create secret docker-registry ar-pull-secret \
    --docker-server=${REGION}-docker.pkg.dev \
    --docker-username=oauth2accesstoken \
    --docker-password="$(gcloud auth print-access-token)" \
    --namespace=${NS} \
    --dry-run=client -o yaml | kubectl apply -f -
done
```

### 10.2 Build and push images (initial manual push)

For the first deployment, you need images in Artifact Registry. Choose ONE option:

#### Option A — Trigger GitHub Actions (recommended if secrets are configured)

Push a commit to `master` — the workflow will build, push, and deploy automatically.

#### Option B — Build locally

```bash
export TAG="initial-$(date +%Y%m%d-%H%M%S)"
export IMAGE_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/login-page-replicator-repo/login-page-replicator"
export PW_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/login-page-replicator-repo/playwright-tests"

# Build and push app image
docker build -t ${IMAGE_BASE}:${TAG} -t ${IMAGE_BASE}:latest .
docker push ${IMAGE_BASE}:${TAG}
docker push ${IMAGE_BASE}:latest

# Build and push Playwright test image
docker build -f tests/Dockerfile -t ${PW_IMAGE}:${TAG} -t ${PW_IMAGE}:latest .
docker push ${PW_IMAGE}:${TAG}
docker push ${PW_IMAGE}:latest

# Update manifests with the new tag
sed -i "s|${IMAGE_BASE}:[^ ]*|${IMAGE_BASE}:${TAG}|g" k8s/app/deployment.yaml
sed -i "s|${PW_IMAGE}:[^ ]*|${PW_IMAGE}:${TAG}|g" k8s/app/playwright-hook.yaml

# Commit and push (Argo CD will auto-sync)
git add k8s/app/deployment.yaml k8s/app/playwright-hook.yaml
git commit -m "ci: initial image deploy ${TAG}"
git push
```

### 10.3 Verify application deployment

```bash
# Wait for Argo CD to sync
kubectl get applications -n argocd

# Check the app deployment
kubectl get pods -n app
kubectl rollout status deployment/login-page-replicator -n app --timeout=300s
```

### 10.4 Get the external URL

```bash
# The GCE Ingress creates a Load Balancer (takes 3-5 minutes)
kubectl get ingress -n app

# Wait until ADDRESS is populated
kubectl get ingress -n app -w
```

Once you have the IP, open `http://<EXTERNAL_IP>` in your browser.

---

## 11. Phase 10 — Apply Network Policies

Apply the full suite of Calico NetworkPolicies for zero-trust networking:

```bash
# Apply all policies at once using kustomize
kubectl apply -k k8s/security
```

Or apply individually in order:

```bash
# Default deny all traffic in all namespaces
kubectl apply -f k8s/security/default-deny.yaml

# Allow DNS resolution (required for all pods)
kubectl apply -f k8s/security/allow-dns-egress.yaml

# Allow health checks from GCP Load Balancer + node kubelet
kubectl apply -f k8s/security/allow-kubelet-probes-app.yaml
kubectl apply -f k8s/security/allow-kubelet-probes-observability.yaml

# Allow Prometheus to scrape app metrics
kubectl apply -f k8s/security/allow-prometheus-scrape.yaml
kubectl apply -f k8s/security/allow-observability-to-app-metrics.yaml
kubectl apply -f k8s/security/allow-observability-internal.yaml

# Allow observability → Kubernetes API (for kube-state-metrics)
kubectl apply -f k8s/security/allow-apiserver-egress.yaml

# Allow testing namespace to reach the app
kubectl apply -f k8s/security/allow-testing-to-app.yaml

# Allow Playwright PostSync hooks to reach the app
kubectl apply -f k8s/security/allow-playwright-hook.yaml

# Allow Wazuh agents to communicate with manager
kubectl apply -f k8s/security/allow-wazuh-egress.yaml
```

### Verify policies

```bash
kubectl get networkpolicies --all-namespaces
```

> ⚠️ After applying network policies, verify that:
> - The app is still accessible via the Ingress IP
> - Prometheus can still scrape metrics (`kubectl port-forward svc/kube-prom-prometheus -n observability 9090:9090` → check targets)
> - Wazuh agents remain connected

---

## 12. Phase 11 — Configure GitHub Actions

### 12.1 Get WIF values from Terraform

```bash
cd terraform

# These two values go into GitHub Secrets
WIF_PROVIDER=$(terraform output -raw workload_identity_provider)
SA_EMAIL=$(terraform output -raw github_actions_sa_email)

echo "GCP_WORKLOAD_IDENTITY_PROVIDER: ${WIF_PROVIDER}"
echo "GCP_SERVICE_ACCOUNT: ${SA_EMAIL}"
```

### 12.2 Set GitHub repository secrets

Go to: `https://github.com/YOUR-USERNAME/login-page-replicator/settings/secrets/actions`

Add these **Repository Secrets**:

| Secret Name | Value |
|-------------|-------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Output of `terraform output -raw workload_identity_provider` |
| `GCP_SERVICE_ACCOUNT` | Output of `terraform output -raw github_actions_sa_email` |
| `SONAR_TOKEN` | From https://sonarcloud.io → Your project → Administration → Analysis Token |

### 12.3 Update workflow environment variables

In `.github/workflows/deploy.yml`, update the `env:` section:

```yaml
env:
  PROJECT_ID:   your-new-project-id          # <-- CHANGE
  REGION:       europe-west1
  REPO_NAME:    login-page-replicator-repo
  SERVICE_NAME: login-page-replicator
  IMAGE_BASE:   europe-west1-docker.pkg.dev/your-new-project-id/login-page-replicator-repo/login-page-replicator  # <-- CHANGE
  PW_IMAGE:     europe-west1-docker.pkg.dev/your-new-project-id/login-page-replicator-repo/playwright-tests       # <-- CHANGE
  CLUSTER_NAME: devops-cluster
```

### 12.4 Update SonarCloud configuration (if needed)

In `sonar-project.properties`, update the organization and project key if you created a new SonarCloud project:

```properties
sonar.projectKey=YOUR-USERNAME_login-page-replicator
sonar.organization=your-sonarcloud-org
```

### 12.5 Trigger the pipeline

```bash
# Push any commit to master to trigger the full pipeline
git add -A
git commit -m "chore: configure for new GCP project"
git push origin master
```

Or trigger manually:
1. Go to GitHub → Actions → "CI (GitHub Actions) + CD (Argo CD) + Playwright Reports"
2. Click "Run workflow" → deploy: `true`

### 12.6 Workflow jobs overview

| Job | Purpose | Blocking? |
|-----|---------|-----------|
| `build-test` | Install deps, lint, build | Yes |
| `prepare-release-infra` | Enable APIs, ensure Artifact Registry exists | Yes |
| `app-image-release` | Build + push app Docker image | Yes |
| `trivy-image-app` | Scan app image for vulnerabilities | Yes (blocks deploy on CRITICAL) |
| `playwright-release` | Build + push Playwright test image | Yes |
| `trivy-image-playwright` | Scan test image (informational) | No |
| `cloud-run-deploy` | Deploy to Cloud Run (staging) | No (parallel) |
| `zap-baseline` | OWASP ZAP DAST scan on Cloud Run | No |
| `update-k8s-tags` | Update K8s manifests + Git push → triggers Argo CD | Yes |
| `e2e-tests` (×6) | Wait for Argo CD PostSync hooks, collect results | No |

---

## 13. Phase 12 — Validation & Smoke Tests

### 13.1 Application health

```bash
# Pods running
kubectl get pods -n app
kubectl get pods -n testing
kubectl get pods -n observability
kubectl get pods -n security

# All deployments ready
kubectl get deployments --all-namespaces

# Ingress has external IP
kubectl get ingress -n app
```

### 13.2 Argo CD status

```bash
kubectl get applications -n argocd
# Both should show: Synced / Healthy
```

### 13.3 Prometheus scraping

```bash
kubectl port-forward svc/kube-prom-prometheus -n observability 9090:9090 &
# Open http://localhost:9090/targets
# Verify "serviceMonitor/observability/nginx-metrics" shows UP
```

### 13.4 Grafana dashboards

```bash
kubectl port-forward svc/kube-prom-grafana -n observability 3000:80 &
# Open http://localhost:3000
# Login: admin / DevOps2025!
```

### 13.5 Wazuh agents

```bash
kubectl get ds wazuh-agent -n security
# DESIRED = CURRENT = READY = 3 (one per node)

gcloud compute ssh wazuh-manager --zone=${ZONE} --project=${PROJECT_ID} \
  --tunnel-through-iap \
  --command='sudo /var/ossec/bin/agent_control -l'
```

### 13.6 GitHub Actions

Check the Actions tab on your GitHub repository — the latest workflow run should complete successfully through all jobs.

### 13.7 Complete system port-forward (all dashboards)

```bash
# All services at once (from project root)
chmod +x port-forward-dashboards.sh
./port-forward-dashboards.sh
```

This opens:
- Grafana: http://localhost:3000
- Argo CD: https://localhost:8081
- App: http://localhost:8080
- Wazuh: https://<external-ip>

---

## 14. Improvements & Recommendations

### Security improvements

| # | Improvement | Priority | Description |
|---|------------|----------|-------------|
| 1 | **Restrict Wazuh Dashboard firewall** | 🔴 High | Change `allow-wazuh-dashboard` source from `0.0.0.0/0` to your IP `/32` in `terraform/wazuh.tf` |
| 2 | **Rotate Wazuh admin password** | 🔴 High | The auto-generated password should be changed. Use the Wazuh API or dashboard settings |
| 3 | **Remove hardcoded secrets from Dockerfile** | 🟡 Medium | The `APP_SECRET`, `DB_PASSWORD`, `JWT_SECRET` ENV vars are intentional vulnerabilities — document clearly they're for demo only |
| 4 | **Add SONAR_TOKEN to GitHub Secrets** | 🟡 Medium | Required for the SonarCloud workflow to pass |
| 5 | **Pin Argo CD version** | 🟡 Medium | Instead of `stable/manifests/install.yaml`, pin a specific version like `v2.13.0` for reproducibility |
| 6 | **Use sealed-secrets or External Secrets** | 🟡 Medium | Replace `ar-pull-secret` (short-lived token) with a proper secret management solution |
| 7 | **Enable Trivy exit-code 1** | 🟢 Low | Currently the Trivy scan is non-blocking (`exit-code: 0`). For production, gate deploys on HIGH+ vulns |

### Infrastructure improvements

| # | Improvement | Priority | Description |
|---|------------|----------|-------------|
| 1 | **Add `terraform.tfvars`** | 🟡 Medium | Create a `.tfvars` file (gitignored) to avoid passing `-var` every time |
| 2 | **Separate Wazuh into its own Terraform module** | 🟢 Low | Better separation of concerns |
| 3 | **Add node auto-scaling** | 🟢 Low | Add `autoscaling` block to the node pool (min 1, max 5 per zone) |
| 4 | **Use private GKE cluster** | 🟢 Low | Disable public endpoint for production |
| 5 | **Add Cloud Armor WAF** | 🟢 Low | In front of the GCE Ingress for DDoS protection |

### CI/CD improvements

| # | Improvement | Priority | Description |
|---|------------|----------|-------------|
| 1 | **ar-pull-secret expiration** | 🔴 High | `gcloud auth print-access-token` expires in 1h. Consider using a cronjob or Workload Identity for image pulls instead |
| 2 | **Add branch protection rules** | 🟡 Medium | Require PR reviews + passing checks before merge to master |
| 3 | **Cache Docker layers in CI** | 🟢 Low | Use `actions/cache` or registry-based caching for faster builds |
| 4 | **Add Slack/Discord notifications** | 🟢 Low | Notify on pipeline failures |

---

## 15. Troubleshooting

### Terraform errors

| Error | Solution |
|-------|----------|
| `Error 403: The caller does not have permission` | Run `gcloud auth application-default login` |
| `Error creating WIF pool: already exists` | Import it: `terraform import google_iam_workload_identity_pool.github projects/PROJECT_ID/locations/global/workloadIdentityPools/github` |
| `Quota CPUS_ALL_REGIONS exceeded` | Request quota increase or use smaller machine type: `-var="gke_machine_type=e2-standard-2"` |
| `Error creating GCS bucket: 409 conflict` | Bucket name is globally unique — change `TFSTATE_BUCKET` |

### GKE / Kubernetes errors

| Error | Solution |
|-------|----------|
| Pods stuck in `ImagePullBackOff` | Refresh `ar-pull-secret` (see Phase 9.1) or check Workload Identity bindings |
| `networkpolicy blocking traffic` | Temporarily delete: `kubectl delete -k k8s/security` then reapply one by one |
| Argo CD app shows `OutOfSync` | Check the repoURL in Application CRs matches your fork |
| HPA not scaling | Verify metrics-server is running: `kubectl get deploy metrics-server -n kube-system` |

### Wazuh errors

| Error | Solution |
|-------|----------|
| Agents stuck `Disconnected` | Remove stale agents: `sudo /var/ossec/bin/manage_agents -r <ID>` on the VM |
| `Unable to connect to enrollment service` (port 1515) | Check firewall source includes `10.20.0.0/16` (pods CIDR) |
| Dashboard shows 500 error | Restart services in order: indexer → wait 45s → manager + filebeat → dashboard |
| VM not responding | Check VM status: `gcloud compute instances describe wazuh-manager --zone=${ZONE}` |

### GitHub Actions errors

| Error | Solution |
|-------|----------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER is EMPTY` | Add the secret in GitHub repo settings |
| `Error: google-github-actions/auth failed` | Verify WIF attribute_condition matches your repo name exactly |
| `Permission denied on Artifact Registry` | Check `github-actions-sa` has `artifactregistry.writer` role |
| `e2e-tests: Job never appeared` | Argo CD may not be syncing — check `kubectl get applications -n argocd` |

---

## Quick Reference — Complete Command Sequence

```bash
# ═══════════════════════════════════════════════════════
# FULL RECREATION — Copy-paste friendly sequence
# ═══════════════════════════════════════════════════════

export PROJECT_ID="your-new-project-id"
export REGION="europe-west1"
export ZONE="europe-west1-b"
export TFSTATE_BUCKET="${PROJECT_ID}-tfstate"

# ── 1. GCP Setup ──
gcloud auth login
gcloud config set project ${PROJECT_ID}
gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com

# ── 2. Terraform ──
gcloud storage buckets create "gs://${TFSTATE_BUCKET}" --location="${REGION}" --uniform-bucket-level-access
gcloud storage buckets update "gs://${TFSTATE_BUCKET}" --versioning

cd terraform
cp backend.hcl.example backend.hcl
sed -i "s/nidhal-pfe-tfstate-CHANGE-ME/${TFSTATE_BUCKET}/" backend.hcl
terraform init -backend-config=backend.hcl
terraform plan -var="project_id=${PROJECT_ID}" -var="region=${REGION}" -out=tfplan
terraform apply tfplan

# ── 3. Connect to cluster ──
CLUSTER_NAME=$(terraform output -raw cluster_name)
CLUSTER_LOCATION=$(terraform output -raw cluster_location)
cd ..
gcloud container clusters get-credentials "${CLUSTER_NAME}" --region "${CLUSTER_LOCATION}" --project "${PROJECT_ID}"

# ── 4. Namespaces ──
kubectl apply -f k8s/namespaces.yaml
kubectl create namespace argocd

# ── 5. Helm ──
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# ── 6. Argo CD ──
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deploy/argocd-server -n argocd --timeout=300s
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD password: ${ARGOCD_PASSWORD}"

# ── 7. Prometheus + Grafana ──
helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack -n observability -f values-autopilot.yaml --wait --timeout 10m
kubectl apply -f k8s/observability/servicemonitor-nginx.yaml

# ── 8. Wazuh agents ──
kubectl apply -f k8s/security/default-deny.yaml
kubectl apply -f k8s/security/allow-dns-egress.yaml
kubectl apply -f k8s/security/allow-wazuh-egress.yaml
kubectl apply -f k8s/security/wazuh-agent-daemonset.yaml
kubectl rollout status daemonset/wazuh-agent -n security --timeout=180s

# ── 9. Deploy app ──
kubectl apply -f k8s/argocd/app-application.yaml
kubectl apply -f k8s/argocd/testing-application.yaml

gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet
for NS in app testing; do
  kubectl create secret docker-registry ar-pull-secret \
    --docker-server=${REGION}-docker.pkg.dev \
    --docker-username=oauth2accesstoken \
    --docker-password="$(gcloud auth print-access-token)" \
    --namespace=${NS} --dry-run=client -o yaml | kubectl apply -f -
done

# ── 10. Network policies ──
kubectl apply -k k8s/security

# ── 11. GitHub secrets ──
cd terraform
echo "GCP_WORKLOAD_IDENTITY_PROVIDER: $(terraform output -raw workload_identity_provider)"
echo "GCP_SERVICE_ACCOUNT: $(terraform output -raw github_actions_sa_email)"
cd ..
# → Add these to GitHub repo Settings → Secrets → Actions

# ── 12. Trigger pipeline ──
git push origin master
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GCP Project                                   │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  VPC: devops-vpc (10.10.0.0/20)                              │  │
│  │                                                              │  │
│  │  ┌─────────────────────────────────────────────────────┐    │  │
│  │  │  GKE Standard Cluster (3 nodes, e2-standard-4)      │    │  │
│  │  │                                                     │    │  │
│  │  │  ┌─────────┐ ┌───────────┐ ┌─────────┐ ┌───────┐ │    │  │
│  │  │  │   app   │ │  testing  │ │observ.  │ │securi.│ │    │  │
│  │  │  │ ns      │ │  ns       │ │ ns      │ │ ns    │ │    │  │
│  │  │  │         │ │           │ │         │ │       │ │    │  │
│  │  │  │ Nginx   │ │Playwright │ │Prometheus│ │Wazuh │ │    │  │
│  │  │  │ App     │ │  Jobs     │ │Grafana  │ │Agents │ │    │  │
│  │  │  │ HPA 2-8 │ │ (hooks)   │ │         │ │(DS)  │ │    │  │
│  │  │  └────┬────┘ └───────────┘ └─────────┘ └───┬──┘ │    │  │
│  │  │       │                                      │     │    │  │
│  │  └───────┼──────────────────────────────────────┼─────┘    │  │
│  │          │                                      │           │  │
│  │          ▼                                      ▼           │  │
│  │  ┌──────────────┐                    ┌──────────────────┐  │  │
│  │  │  GCE L7 LB   │                    │  Wazuh VM        │  │  │
│  │  │  (Ingress)    │                    │  e2-medium       │  │  │
│  │  └──────────────┘                    │  10.10.0.2       │  │  │
│  │                                      │  Manager+Indexer  │  │  │
│  │  ┌──────────────┐                    │  +Dashboard       │  │  │
│  │  │ Artifact Reg │                    └──────────────────┘  │  │
│  │  │ Docker repo  │                                          │  │
│  │  └──────────────┘                                          │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────┐                           │
│  │  Cloud Run (staging/DAST target)    │                           │
│  └─────────────────────────────────────┘                           │
└─────────────────────────────────────────────────────────────────────┘

         ▲                    ▲
         │ WIF (OIDC)        │ GitOps (auto-sync)
         │                    │
┌────────┴────────┐  ┌───────┴───────┐
│  GitHub Actions  │  │   Argo CD     │
│  (CI/CD)         │  │   (in-cluster)│
│                  │  │               │
│  Build/Push      │──►  Sync K8s    │
│  Trivy/ZAP       │  │  manifests   │
│  SonarCloud      │  └───────────────┘
└──────────────────┘
```

---

*Generated for the `login-page-replicator` DevSecOps PFE project.*
