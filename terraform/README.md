# Terraform Phase 0

This folder provisions the Phase 0 baseline infrastructure for the GKE platform migration:

- VPC + subnet with secondary ranges for pods/services
- GKE Autopilot cluster (`devops-cluster`)
- GCP service account for workloads (`gke-app-sa`)
- Artifact Registry read IAM + Workload Identity binding
- Wazuh manager VM + firewall rules

## Run

```bash
gcloud storage buckets create gs://pfe-esprit-489411-tfstate --location=europe-west1
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Get Cluster Credentials

```bash
gcloud container clusters get-credentials devops-cluster --region europe-west1 --project pfe-esprit-489411
```

## Useful Output

```bash
terraform output -raw wazuh_manager_internal_ip
```

