#+#+#+#+ Terraform Phase 0 (GKE Standard)

This folder provisions the Phase 0 baseline infrastructure for the GKE platform migration:

- VPC + subnet with secondary ranges for pods/services
- GKE **Standard** cluster (`devops-cluster`) + node pool
- GCP service account for workloads (`gke-app-sa`)
- Artifact Registry read IAM + Workload Identity binding
- Wazuh manager VM + firewall rules

Note on node sizing: this module creates a **regional** GKE cluster (location = a region).
In regional clusters, the node pool `node_count` is **per zone**. For example in
`europe-west1` (3 zones), `gke_node_count=1` results in ~3 total nodes.

## Run (fresh account / new project)

Prereqs: `gcloud`, `terraform` (>= 1.5), and billing enabled on the target project.

```bash
# 0) Pick your project id and state bucket (bucket name must be globally unique)
export PROJECT_ID="nidhal-pfe"
export REGION="europe-west1"
export TFSTATE_BUCKET="nidhal-pfe-tfstate-CHANGE-ME"

# 1) Ensure gcloud is targeting the right project
gcloud config set project "${PROJECT_ID}"

# 2) Create the remote state bucket (recommended: uniform access + versioning)
gcloud storage buckets create "gs://${TFSTATE_BUCKET}" --location="${REGION}" --uniform-bucket-level-access
gcloud storage buckets update "gs://${TFSTATE_BUCKET}" --versioning

# 3) Create a backend config file
cd terraform
cp backend.hcl.example backend.hcl
sed -i "s/nidhal-pfe-tfstate-CHANGE-ME/${TFSTATE_BUCKET}/" backend.hcl

# 4) Init/apply
terraform init -backend-config=backend.hcl

# If you exported PROJECT_ID/REGION:
terraform plan -out=tfplan -var="project_id=${PROJECT_ID}" -var="region=${REGION}"

# If your shell variables are not set, either pass explicit values:
# terraform plan -out=tfplan -var="project_id=nidhal-pfe" -var="region=europe-west1"
# or just use the defaults from variables.tf:
# terraform plan -out=tfplan

terraform apply tfplan
```

## Sizing (CPU/RAM)

The node pool is configured via variables:

- `gke_machine_type` (default: `e2-standard-4`)
- `gke_node_count` (**per zone** in a regional cluster; `1` => ~3 total nodes in `europe-west1`)

Example (bigger nodes):

```bash
terraform plan -out=tfplan \
	-var="project_id=${PROJECT_ID}" \
	-var="region=${REGION}" \
	-var="gke_machine_type=e2-highmem-4" \
	-var="gke_node_count=1"
```

If you hit `CPUS_ALL_REGIONS` quota errors, either request a quota increase or choose a smaller machine type.

## Get Cluster Credentials

```bash
gcloud container clusters get-credentials devops-cluster --region europe-west1 --project nidhal-pfe
```

## Useful Output

```bash
terraform output -raw wazuh_manager_internal_ip
```

