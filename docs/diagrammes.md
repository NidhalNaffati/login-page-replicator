# Diagrammes du projet

Ce fichier contient 3 diagrammes Mermaid:
1. Diagramme DevSecOps (flux CI/CD + securite + tests)
2. Architecture physique (GCP)
3. Architecture logique (Kubernetes)

## 1) Diagramme DevSecOps

```mermaid
flowchart LR
  Dev[Developpeur]
  Git[GitHub Repository]
  GHA[GitHub Actions\nCI/CD]
  WIF[Workload Identity Federation\nOIDC Trust]
  GAR[Artifact Registry]
  TF[Terraform Apply]
  GCP[GCP Project]
  ARGO[Argo CD]
  K8S[GKE Autopilot Cluster]
  APP[App Namespace\nDeployment + Service + Ingress]
  HOOK[Playwright PostSync Hook Job]
  OBS[Observability\nPrometheus ServiceMonitor]
  SEC[Security\nNetworkPolicies + Wazuh Agent]
  WAZUH[Wazuh Manager VM]

  Dev -->|commit/push| Git
  Git -->|trigger| GHA
  GHA -->|OIDC auth| WIF
  WIF -->|short-lived credentials| GCP
  GHA -->|build/push images| GAR
  GHA -->|infra changes| TF
  TF -->|provision/update| GCP

  Git -->|manifests watched| ARGO
  ARGO -->|sync desired state| K8S
  K8S --> APP
  ARGO -->|PostSync| HOOK
  HOOK -->|E2E tests HTTP:80| APP

  OBS -->|scrape metrics :9113| APP
  SEC -->|runtime logs/events| WAZUH

  GAR -->|pull images| K8S
```

## 2) Architecture physique (GCP)

```mermaid
flowchart TB
  subgraph GCP[GCP Project]
    subgraph NET[VPC: devops-vpc]
      SUB[Subnet: devops-subnet\nNodes: 10.10.0.0/20\nPods: 10.20.0.0/16\nServices: 10.30.0.0/20]
    end

    GAR[Artifact Registry\nApp + Playwright Images]

    subgraph GKE[GKE Autopilot: devops-cluster]
      INGRESS[GKE Ingress\nExternal HTTP(S)]
      NODEPOOL[Managed Autopilot Nodes]
      NSAPP[Namespace app]
      NSTEST[Namespace testing]
      NSOBS[Namespace observability]
      NSSEC[Namespace security]
      NSARGO[Namespace argocd]
    end

    WAZUHVM[Compute Engine VM\nWazuh Manager\nPorts 1514/1515/55000]
  end

  Internet[Users / Browser] --> INGRESS
  INGRESS --> NSAPP

  GAR -->|image pull| GKE

  NSSEC -->|agent traffic| WAZUHVM
  SUB --- GKE
  SUB --- WAZUHVM
```

## 3) Architecture logique (Kubernetes)

```mermaid
flowchart LR
  subgraph A[argocd namespace]
    ARGOAPP[Argo CD Application\nk8s/app]
    ARGOTEST[Argo CD Application\nk8s/testing optional]
  end

  subgraph APPNS[app namespace]
    DEP[Deployment login-page-replicator]
    SVC[Service login-page-replicator\nPorts 80, 9113]
    ING[Ingress]
    HPA[HPA 2..8 replicas]
    HOOK[Job playwright-e2e-tests\nPostSync]
    DEP --> SVC
    HPA --> DEP
    ING --> SVC
  end

  subgraph TESTNS[testing namespace]
    PJOB[Job playwright-tests]
    PSA[ServiceAccount playwright-runner]
    PSA --> PJOB
  end

  subgraph OBSNS[observability namespace]
    SM[ServiceMonitor nginx-app]
  end

  subgraph SECNS[security namespace]
    NP0[default-deny-all]
    NPDNS[allow-dns-egress]
    NPAPP[allow-testing-to-app\nallow-playwright-hook]
    NPOBS[allow-prometheus-scrape\nallow-observability-to-app-metrics]
    WDAEMON[Wazuh Agent DaemonSet]
  end

  ARGOAPP -->|sync| APPNS
  ARGOTEST -->|sync optional| TESTNS

  HOOK -->|HTTP 80| SVC
  PJOB -->|HTTP 80| SVC
  SM -->|scrape 9113| SVC

  NP0 -. baseline .- APPNS
  NP0 -. baseline .- TESTNS
  NP0 -. baseline .- OBSNS
  NP0 -. baseline .- SECNS

  NPDNS -. DNS allowed .- APPNS
  NPDNS -. DNS allowed .- TESTNS
  NPDNS -. DNS allowed .- OBSNS
  NPDNS -. DNS allowed .- SECNS

  NPAPP -. app test flows .- APPNS
  NPOBS -. metrics flows .- OBSNS

  WDAEMON -->|1514/1515| WM[(Wazuh Manager VM)]
```

## Utilisation
- Vous pouvez copier ces blocs Mermaid dans votre rapport principal `docs/rapport_projet.md`.
- Si votre visualiseur Markdown supporte Mermaid (GitHub, GitLab, Obsidian, etc.), les schemas seront rendus automatiquement.

