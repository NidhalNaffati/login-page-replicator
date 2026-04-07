# Login Page Replicator / Todo App

This repository contains a React + Vite Todo app (with a login gate), plus deployment assets for Docker, GKE, Cloud Run, Playwright e2e tests, Terraform, and Kubernetes security policies.

## What is in this project

- Frontend: React 18 + TypeScript + Vite + Tailwind + shadcn/ui.
- Unit tests: Vitest.
- E2E tests: Playwright (`tests/todo.spec.ts`).
- App container: multi-stage Docker build (`Dockerfile`) served by Nginx.
- E2E container: Playwright image with Bun (`tests/Dockerfile`).
- Kubernetes manifests under `k8s/`:
  - `app` namespace: app Deployment/Service/Ingress/HPA + service account.
  - `testing` namespace: Playwright Job + service account.
  - `security` namespace: default-deny and allow policies.
  - `observability` namespace: ServiceMonitor and observability policies.
- Terraform baseline under `terraform/` for GKE infrastructure.
- Cloud Run deployment script: `deploy.sh`.

## Quick start (local)

Prerequisites:

- Bun installed
- Node-compatible environment for Vite/Playwright

```bash
bun install
bun run dev
```

App default local URL in Playwright config:

- `http://localhost:8080`

Useful scripts from `package.json`:

```bash
bun run dev
bun run build
bun run lint
bun run test
bun run test:e2e
```

## DAST (OWASP ZAP)

This repository includes a dedicated GitHub Actions workflow at
`.github/workflows/dast-zap.yml` to run an OWASP ZAP baseline scan.

- Trigger types:
  - Manual (`workflow_dispatch`)
  - Weekly schedule (Monday 03:00 UTC)
- Reports uploaded as artifacts:
  - `zap-report.html`
  - `zap-report.md`
  - `zap-report.json`

Target URL resolution (in order):

1. Manual workflow input: `target_url`
2. Repository variable: `DAST_TARGET_URL`

Rule tuning lives in `.zap/rules.tsv`.

Recommended setup:

1. Add repository variable `DAST_TARGET_URL` pointing to a staging or test URL.
2. Run the workflow manually once and review artifacts before enforcing stricter fail conditions.

If you deploy via GitHub Actions to Cloud Run, use the URL printed in
`deploy.yml` step `Show Cloud Run URL` as the value of `DAST_TARGET_URL`.

## Docker

### Build and run the app image

```bash
docker build -t login-page-replicator:local .
docker run --rm -p 8080:80 login-page-replicator:local
```

### Build and run Playwright tests image

```bash
docker build -f tests/Dockerfile -t playwright-tests:local .
docker run --rm \
  -e BASE_URL=http://host.docker.internal:8080 \
  -e CI=true \
  playwright-tests:local
```

## Kubernetes layout and expected service DNS

- App namespace: `app`
- Testing namespace: `testing`
- App Service name: `login-page-replicator`
- In-cluster app URL expected by e2e job:
  - `http://login-page-replicator.app.svc.cluster.local`

The in-cluster Playwright hooks are defined in `k8s/app/playwright-hook.yaml` and use:

- service account: `gke-app-sa`
- image: `.../playwright-tests:<short_sha>` (updated by CI in GitOps manifests)
- env: `BASE_URL=http://login-page-replicator`
- env: `PW_GREP=@t1..@t6` so each test runs in its own isolated Job

## CI/CD and GitHub Actions notes (from troubleshooting)

The workflow file is present at `.github/workflows/deploy.yml`. Current pipeline behavior:

```text
build-test
  └─ prepare-release-infra
      ├─ app-image-release  (build app -> push AR) ─┐
      │    └─ cloud-run-deploy (deploy app image to Cloud Run)
      └─ playwright-release (build Playwright image -> push AR) ─┤
                                                                   └─ update-k8s-tags (update k8s image tags and commit)
                                                                         └─ e2e-tests (wait for Argo CD hooks and collect reports)
```

1. Build + push app/test images to Artifact Registry.
2. Ensure Artifact Registry repository exists (created automatically if missing).
3. Deploy app image to Cloud Run (`login-page-replicator`) on push to `master`.
4. Fetch GKE credentials.
5. Update short SHA image tags in `k8s/app/deployment.yaml` and `k8s/app/playwright-hook.yaml`, then commit back to Git.
6. Argo CD auto-syncs `k8s/app` and creates 6 PostSync Playwright Jobs (`playwright-e2e-tests-t1` ... `playwright-e2e-tests-t6`).
7. GitHub Actions waits for each hook job in a matrix and publishes isolated artifacts/checks per test.

Per-test isolation model:

- `tests/todo.spec.ts` uses markers `@t1` to `@t6`.
- Local e2e CI (`e2e-local`) runs one marker per matrix job using `--grep`.
- In-cluster e2e (`e2e-tests`) waits for one Argo PostSync hook job per marker.

### Why GitHub Actions shows Playwright results but Argo CD does not

The current setup splits responsibilities:

- **Argo CD** tracks only `k8s/app` through `k8s/argocd/app-application.yaml`.
- **GitHub Actions** updates image tags in Git and Argo CD creates the PostSync Playwright jobs from `k8s/app/playwright-hook.yaml`.
- **Playwright reports** are extracted from the finished test pod and uploaded as GitHub Actions artifacts.

That means:

1. Argo CD can show the deployed app resources, because they are inside its tracked path.
2. Argo CD does **not** automatically show resources from `k8s/testing` by default, because the main Argo CD app tracks only `k8s/app`.
3. Argo CD does **not** render Playwright HTML/JUnit/JSON reports. Those reports live in GitHub Actions artifacts unless you publish them to persistent storage yourself.

An optional Argo CD app manifest is provided at `k8s/argocd/testing-application.yaml`.
Registering it lets Argo CD also sync and display `k8s/testing` resources.

Important notes about that optional testing app:

- It is intended for **visibility**, not for replacing the current GitHub Actions execution flow.
- It does not control the PostSync hook jobs in `k8s/app/playwright-hook.yaml`; those belong to the main app Argo Application.
- Hook job TTL is `86400` seconds so completed jobs remain visible for longer.

If you want Argo-based execution instead of GitHub Actions-based execution, the next step is to move test runs to:

- an **Argo CD hook Job** (`PostSync`), or
- **Argo Workflows** / **Argo Rollouts AnalysisRun**,

and store reports in a durable location such as **GCS**, **S3**, or a **PVC-backed web endpoint**.

Observed failure progression and fixes:

1. **`ImagePullBackOff` with 403 Forbidden from Artifact Registry**
   - Symptom: kubelet cannot fetch OAuth token for image pull.
   - Actions done:
     - Granted `roles/artifactregistry.reader` to node-related identities.
     - Bound KSA `testing/playwright-runner` to GSA `gke-app-sa@...` with `roles/iam.workloadIdentityUser`.
     - Ensured `playwright-runner` service account annotation exists.
2. **`ErrImagePull` with tag `IMAGE_TAG` not found**
   - Symptom: pod tries to pull literal `...:IMAGE_TAG`.
   - Root cause: manifest applied without substitution.
   - Working command pattern:

```bash
SHORT_SHA="c45da60"
kubectl delete job playwright-tests -n testing --ignore-not-found
sed "s|IMAGE_TAG|${SHORT_SHA}|g" k8s/testing/playwright-job.yaml | kubectl apply -f -
```

3. **After pull worked, e2e runtime failures**
   - Example observed: `net::ERR_NAME_NOT_RESOLVED` on `login-page-replicator.app.svc.cluster.local`.
   - Checks used:

```bash
kubectl get pods -n app -o wide
kubectl get svc,endpoints -n app
kubectl logs -n testing -l job-name=playwright-tests --tail=200
kubectl describe pod -n testing -l job-name=playwright-tests
```

## Recommended deployment order (GKE)

```bash
kubectl apply -f k8s/namespaces.yaml
kubectl apply -f k8s/app/
kubectl apply -f k8s/testing/serviceaccount.yaml
kubectl apply -f k8s/security/
```

Optional: register the testing resources in Argo CD too:

```bash
kubectl apply -f k8s/argocd/testing-application.yaml
```

Then create the Playwright job with a real image tag (short SHA or full SHA):

```bash
SHORT_SHA="<your_short_sha>"
sed "s|IMAGE_TAG|${SHORT_SHA}|g" k8s/testing/playwright-job.yaml | kubectl apply -f -
```

## Identity/IAM model used here

- KSA in `app`: `gke-app-sa`
- KSA in `testing`: `playwright-runner`
- Both can be mapped to GSA `gke-app-sa@pfe-esprit-489411.iam.gserviceaccount.com` using Workload Identity.
- GSA must have permissions needed by workload (at minimum Artifact Registry pull for test image path).

## Cloud Run path

`deploy.sh` builds, pushes, and deploys the app image to Cloud Run.

```bash
chmod +x deploy.sh
./deploy.sh
```

It supports env overrides like `PROJECT_ID`, `REGION`, `REPO_NAME`, `SERVICE_NAME`, and `NO_PROMPT=1`.

## Troubleshooting checklist

When Playwright job fails in `testing`:

```bash
kubectl get jobs -n testing
kubectl get pods -n testing
kubectl describe job playwright-tests -n testing
kubectl describe pod -n testing -l job-name=playwright-tests
kubectl logs -n testing -l job-name=playwright-tests --tail=200
```

When image pull fails:

```bash
gcloud artifacts docker images list \
  europe-west1-docker.pkg.dev/<PROJECT_ID>/<REPO>/playwright-tests \
  --include-tags
```

Verify the pod image tag is real (not `IMAGE_TAG`) and that IAM/Workload Identity bindings are in place.

## Important placeholders to customize

- `pfe-esprit-489411`
- `europe-west1`
- `login-page-replicator-repo`
- `gke-app-sa@...`
- any hardcoded image tag in `k8s/app/deployment.yaml`

## Current known gap

- Argo CD only syncs what each `Application` tracks. The main app (`k8s/argocd/app-application.yaml`) tracks `k8s/app`; add `k8s/argocd/testing-application.yaml` if you want Argo CD visibility/sync for `k8s/testing` too.
