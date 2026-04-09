# GitHub Self-Hosted Runner on GKE (for private SonarQube)

This folder contains starter configuration notes for running GitHub Actions jobs
inside your GKE VPC so workflows can access a private/internal SonarQube
endpoint.

## Why this is needed

GitHub-hosted runners cannot reach private in-cluster URLs such as:

- `http://sonarqube.<namespace>.svc.cluster.local:9000`

Use a self-hosted runner in your cluster and target it from
`.github/workflows/sonarqube.yml`.

## Runner labels expected by workflow

The Sonar workflow currently uses:

- `self-hosted`
- `linux`
- `gke`
- `sonar`

Adjust labels in the workflow if your runner uses different labels.

## Quick bootstrap commands (ARC)

```bash
kubectl create namespace github-runners
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update
helm upgrade --install arc actions-runner-controller/actions-runner-controller \
  --namespace github-runners
```

Then create runner auth secrets (GitHub App recommended) and install a runner
scale set/runner deployment with labels that include `gke` and `sonar`.

## GitHub secrets required for Sonar workflow

- `SONAR_HOST_URL`
- `SONAR_TOKEN`

## Suggested hardening baseline

- Dedicated namespace (`github-runners`)
- Ephemeral runners (one job per pod)
- Non-root containers
- Egress allowlist (GitHub + Sonar + DNS)
- Least-privilege service accounts/RBAC

