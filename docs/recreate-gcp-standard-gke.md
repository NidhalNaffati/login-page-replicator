# Recreate the project on a fresh GCP account (Standard GKE)

This runbook recreates the infra + cluster bootstrap + app deploy for a fresh GCP project.

Assumptions (adjust as needed):
- Project ID: `nidhal-pfe`
- Region: `europe-west1`
- Standard GKE cluster (not Autopilot)

## 0) Prereqs

Install locally:
- `gcloud`
- `terraform` (>= 1.5)
- `kubectl`
- `helm`
- `docker` (optional if you build locally)

Authenticate + pick project:

```bash
gcloud auth login

gcloud config set project nidhal-pfe
gcloud config set compute/region europe-west1
```

Ensure billing is enabled for the project (Console → Billing). Terraform will enable required APIs.

## 1) Terraform (Phase 0 baseline)

The Terraform baseline is in [terraform/README.md](../terraform/README.md).

Quick path:

```bash
export PROJECT_ID="nidhal-pfe"
export REGION="europe-west1"
export TFSTATE_BUCKET="nidhal-pfe-tfstate-CHANGE-ME"  # must be globally unique

# Create remote state bucket

gcloud storage buckets create "gs://${TFSTATE_BUCKET}" \
  --location="${REGION}" \
  --uniform-bucket-level-access

gcloud storage buckets update "gs://${TFSTATE_BUCKET}" --versioning

# Init/apply
cd terraform
cp backend.hcl.example backend.hcl
sed -i "s/nidhal-pfe-tfstate-CHANGE-ME/${TFSTATE_BUCKET}/" backend.hcl

terraform init -backend-config=backend.hcl
terraform plan -out=tfplan -var="project_id=${PROJECT_ID}" -var="region=${REGION}"
terraform apply tfplan
```

Outputs you’ll likely use:

```bash
terraform output -raw cluster_name
terraform output -raw cluster_location
terraform output -raw github_actions_sa_email
terraform output -raw workload_identity_provider
```

## 2) Get GKE credentials

```bash
cd terraform
CLUSTER_NAME="$(terraform output -raw cluster_name)"
CLUSTER_LOCATION="$(terraform output -raw cluster_location)"
cd ..

# cluster_location is a *region* (ex: europe-west1)
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --region "${CLUSTER_LOCATION}" \
  --project "nidhal-pfe"
```

Sanity checks:

```bash
kubectl get nodes
kubectl get ns
```

## 3) Namespaces + minimal network policy (to match CI)

This is the same order the GitHub Actions workflow uses:

```bash
kubectl apply -f k8s/namespaces.yaml
kubectl apply -f k8s/security/allow-playwright-hook.yaml
```

## 4) Install Argo CD

```bash
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait until Argo CD is ready:

```bash
kubectl rollout status deploy/argocd-server -n argocd
```

Optional: use the dashboard runbook in [docs/argocd-port-forward.md](argocd-port-forward.md).

## 5) Register the GitOps applications

If you forked the repo, update `repoURL:` in:
- [k8s/argocd/app-application.yaml](../k8s/argocd/app-application.yaml)
- [k8s/argocd/testing-application.yaml](../k8s/argocd/testing-application.yaml)

Then apply:

```bash
kubectl apply -f k8s/argocd/app-application.yaml
kubectl apply -f k8s/argocd/testing-application.yaml
```

## 6) Create `ar-pull-secret` (required by Playwright Jobs)

The Playwright jobs reference an imagePullSecret named `ar-pull-secret`.

Create/refresh it in both namespaces:

```bash
for NS in app testing; do
  kubectl create secret docker-registry ar-pull-secret \
    --docker-server=europe-west1-docker.pkg.dev \
    --docker-username=oauth2accesstoken \
    --docker-password="$(gcloud auth print-access-token)" \
    --namespace=${NS} \
    --dry-run=client -o yaml | kubectl apply -f -
done
```

## 7) Build + push images (choose one)

### Option A — Use GitHub Actions (recommended)

1) Ensure Terraform WIF repo restriction matches your repo.

In [terraform/wif.tf](../terraform/wif.tf), these must match your GitHub org/user + repo:
- `attribute_condition = "attribute.repository == 'OWNER/REPO'"`
- `principalSet://.../attribute.repository/OWNER/REPO`

If you changed them, re-run `terraform apply`.

2) Set GitHub Secrets:

```bash
cd terraform
terraform output -raw workload_identity_provider   # -> GCP_WORKLOAD_IDENTITY_PROVIDER
terraform output -raw github_actions_sa_email      # -> GCP_SERVICE_ACCOUNT
```

Then in GitHub → Settings → Secrets and variables → Actions → New repository secret:
- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_SERVICE_ACCOUNT`

Trigger the deploy workflow; it will build/push images, update tags in GitOps manifests, create `ar-pull-secret`, and Argo CD will run PostSync Playwright jobs.

### Option B — Build locally and apply manifests yourself

Build and push to Artifact Registry:

```bash
export PROJECT_ID="nidhal-pfe"
export REGION="europe-west1"
export REPO="login-page-replicator-repo"
export TAG="manual-$(date +%Y%m%d-%H%M%S)"

# Authenticate Docker to Artifact Registry

gcloud auth configure-docker "${REGION}-docker.pkg.dev"

# App image

docker build -t "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/login-page-replicator:${TAG}" .
docker push "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/login-page-replicator:${TAG}"

# Playwright image

docker build -f tests/Dockerfile -t "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/playwright-tests:${TAG}" tests
docker push "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/playwright-tests:${TAG}"
```

Update tags in:
- [k8s/app/deployment.yaml](../k8s/app/deployment.yaml)
- [k8s/app/playwright-hook.yaml](../k8s/app/playwright-hook.yaml)
- (optional) [k8s/testing/playwright-job.yaml](../k8s/testing/playwright-job.yaml)

Then apply:

```bash
kubectl apply -f k8s/app
kubectl apply -f k8s/testing
```

## 8) Get the external URL

```bash
kubectl get ingress -n app
```

It can take a few minutes for GKE to provision the load balancer.

## 9) Observability (Prometheus/Grafana)

Install `kube-prometheus-stack` into the `observability` namespace.

```bash
kubectl create namespace observability || true

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Keep using values-autopilot.yaml if you want a lighter install.
# On Standard GKE you can also omit -f values-autopilot.yaml for full metrics.

helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
  -n observability \
  -f values-autopilot.yaml

# After CRDs exist, apply the ServiceMonitor
kubectl apply -f k8s/observability/servicemonitor-nginx.yaml
```

Optional: Grafana port-forward runbook is in [docs/grafana-port-forward.md](grafana-port-forward.md).

## 10) Security policies (optional)

Once you’re comfortable with connectivity, you can apply the full set of NetworkPolicies:

```bash
kubectl apply -k k8s/security
```

If something breaks, revert by deleting the applied policies (or apply allow rules first).

---

### Notes

- This repo is a DevSecOps demo: some workloads/manifests are intentionally insecure.
- Standard GKE + NetworkPolicy: Terraform enables Calico so NetworkPolicies work as expected.
