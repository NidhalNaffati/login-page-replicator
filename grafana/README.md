# Grafana on Cloud Run (immutable / provisioned)

This folder contains a Grafana container image designed to be **stateless** on Cloud Run.

## What you get
- A Grafana image (`grafana/Dockerfile`) that installs the **Google Cloud Monitoring** datasource plugin.
- Provisioned datasource: `Google Cloud Monitoring` (`uid: gcm`) via ADC (Cloud Run service account).
- Provisioned dashboards (JSON in `grafana/dashboards/`) loaded into the `Cloud Run` folder.

## Stateless / immutable behavior
This setup is intended to be **immutable**:
- dashboards + datasources are loaded from files at startup
- UI edits won’t persist reliably across restarts/revisions
- to change dashboards, export JSON from Grafana and commit it back into `grafana/dashboards/`

## Required IAM
Attach a service account to the Grafana Cloud Run service with (at minimum):
- `roles/monitoring.viewer`

Optional (nice to have):
- `roles/cloudasset.viewer` (resource metadata)

## Deploy via this repo
Use the root `deploy.sh`:

```bash
DEPLOY_GRAFANA=1 \
GRAFANA_SA_EMAIL="grafana-cloudrun-sa@YOUR_PROJECT.iam.gserviceaccount.com" \
./deploy.sh
```

By default the script deploys Grafana as **private** (`--no-allow-unauthenticated`).
To make it public (not recommended):

```bash
DEPLOY_GRAFANA=1 ALLOW_PUBLIC_GRAFANA=1 ./deploy.sh
```

## Local run (provisioning sanity check)
You can build and boot the image locally (Cloud Monitoring queries won’t work unless you have GCP creds available):

```bash
docker build -f grafana/Dockerfile -t local-grafana ./grafana

docker run --rm -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -e GCP_PROJECT="your-gcp-project" \
  local-grafana
```

Open http://localhost:3000 (user: `admin`).

