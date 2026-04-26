# PFE Report — TODO Tracker

> Master status board for the LaTeX report (`pfe_master_latex/`), screenshots, diagrams, and remaining work.

---

## 1. Placeholder Figures — Screenshots to Take

These figures currently have `\fbox{Espace réservé}` in the LaTeX. Replace them with actual screenshots.

Save all screenshots as **PNG** in `pfe_master_latex/images/screenshots/`.

| # | Label | Description | File to Edit | How to Get |
|---|-------|-------------|-------------|------------|
| 1 | `fig:app_screenshot_login` | Login page of the Todo App | chapitre4.tex | Open app → screenshot login page |
| 2 | `fig:app_screenshot_dashboard` | Dashboard after login | chapitre4.tex | Login → screenshot todo dashboard |
| 3 | `fig:build_test_screenshot` | GitHub Actions build-test step | chapitre4.tex | GitHub → Actions → workflow run → screenshot |
| 4 | `fig:vitest_coverage` | Vitest coverage report | chapitre4.tex | Run `bun run test:coverage` → screenshot terminal |
| 5 | `fig:playwright_results` | Playwright E2E results (6 scenarios) | chapitre4.tex | Run `bun run test:e2e` → screenshot report |
| 6 | `fig:grafana_dashboard` | Grafana monitoring dashboard | chapitre4.tex | Port-forward Grafana → screenshot |
| 7 | `fig:wazuh_dashboard` | Wazuh SIEM dashboard | chapitre4.tex | Open Wazuh dashboard → screenshot |
| 8 | `fig:xss_demo` | XSS alert box demo | chapitre4.tex | Add `<img src=x onerror=alert('XSS')>` as todo → screenshot alert |
| 9 | `fig:debug_mode_demo` | Debug mode credentials panel | chapitre4.tex | Navigate to `/?debug=true` → screenshot |

### Already Done (13 screenshots exist)
- [x] `terraform-plan-gke-node-service-account-changes.png`
- [x] `gke-cluster-observability-dashboard.png`
- [x] `github-actions-ci-cd-workflow-summary.png`
- [x] `sonarqube-overview-dashboard.png`
- [x] `sonarqube-issues-list.png`
- [x] `trivy-debian-vulnerability-report-overview.png`
- [x] `trivy-debian-curl-critical-vulnerabilities.png`
- [x] `owasp-zap-alerts-summary.png`
- [x] `owasp-zap-csp-header-not-set-details.png`
- [x] `argocd-applications-tiles-login-page-replicator.png`
- [x] `argocd-application-details-tree-view.png`
- [x] `argocd-application-details-pods-view.png`
- [x] `argocd-application-details-network-view.png`

---

## 2. Placeholder Figures — Excalidraw Diagrams to Create

These need to be created in Excalidraw and exported as PNG.

| # | Label | Description | File to Edit | Suggested Content |
|---|-------|-------------|-------------|-------------------|
| 1 | `fig:couches` | Architecture en 6 couches | chapitre3.tex | 6 layers: Frontend → Containerisation → Orchestration → Sécurité → Observabilité → IaC |
| 2 | `fig:archi_physique` | Architecture physique GCP | chapitre3.tex | VPC devops-vpc → GKE cluster → 5 namespaces → Wazuh VM → Internet (Ingress) |
| 3 | `fig:archi_k8s` | Architecture Kubernetes | chapitre3.tex | 5 namespaces (app, testing, observability, security, argocd) with pods, services, NetworkPolicies |
| 4 | `fig:seq_pipeline` | Diagramme de séquence CI/CD | chapitre3.tex | Developer → GitHub → Actions (build/test/scan) → GHCR → ArgoCD → GKE |
| 5 | `fig:seq_wif` | Diagramme de séquence WIF | chapitre3.tex | GitHub Actions → OIDC token → GCP STS → Service Account → GKE/GHCR |
| 6 | `fig:act_gitops` | Diagramme d'activité GitOps | chapitre3.tex | Push → CI → Build image → Update tag → ArgoCD detect → Sync → Deploy → Health check |
| 7 | `fig:deployment_diagram` | Diagramme de déploiement UML | chapitre3.tex | GCP cloud → GKE node → pods, VM → Wazuh, GitHub → Actions runners |
| 8 | `fig:class_diagram` | Diagramme de classes React | chapitre4.tex | AuthContext, TodoDashboard, TodoItem, Login components + hooks + contexts |
| 9 | `fig:shiftleft` | Shift-Left Security diagram | chapitre2.tex | Traditional (security at end) vs Shift-Left (security at each stage) timeline |
| 10 | `fig:use_case_global` | Diagramme de cas d'utilisation | chapitre2.tex | 3 actors (Dev, Ops, Security) → use cases (commit, deploy, scan, monitor, alert) |
| 11 | `fig:scrum_process` | Processus Scrum du projet | chapitre2.tex | Sprint cycle: Backlog → Sprint Planning → Daily → Sprint Review → Retrospective |
| 12 | `fig:gantt` | Diagramme de Gantt | chapitre2.tex | 4 sprints timeline: Feb-Jun 2025, overlapping phases |

### Company/Context Figures
| # | Label | Description | File to Edit | How to Get |
|---|-------|-------------|-------------|------------|
| 13 | `fig:sopra_overview` (1.1) | Vue globale de Sopra HR | chapitre1.tex | Company website / internal docs |
| 14 | `fig:organigramme` (1.2) | Organigramme Sopra HR | chapitre1.tex | HR / internal org chart |
| 15 | `fig:t4t_overview` | Portail T4T interne | chapitre1.tex | Screenshot of T4T portal or description diagram |

---

## 3. Bibliography — Missing/Placeholder References

The `Biblio.bib` file contains several **placeholder entries** that need real references:

| Entry Key | Current State | Action Needed |
|-----------|--------------|---------------|
| `Nom2012` | Placeholder "Mon livre" | Remove or replace with real reference |
| `web001` | Placeholder "Mon livre" | Remove or replace with real reference |
| `gen1972` | Genette (literary theory) | **Remove** — not relevant to DevSecOps |
| `schaeffer99` | Schaeffer (fiction theory) | **Remove** — not relevant |
| `caillois1` | Caillois (game theory) | **Remove** — not relevant |
| `jenkins2004` | Jenkins (game design) | **Remove** — not relevant |
| `hui` | Huizinga (game theory) | **Remove** — not relevant |
| `Bird02nltk` | NLTK (NLP toolkit) | **Remove** — not relevant |

### References to Add
- [ ] Trivy official documentation (Aqua Security)
- [ ] OWASP ZAP official documentation
- [ ] SonarSource/SonarCloud documentation
- [ ] Wazuh official documentation
- [ ] ArgoCD official documentation
- [ ] Kubernetes official documentation
- [ ] Terraform by HashiCorp documentation
- [ ] Docker official documentation
- [ ] GitHub Actions documentation
- [ ] Workload Identity Federation (Google Cloud docs)
- [ ] NIST SP 800-190 (Container Security Guide)
- [ ] CIS Kubernetes Benchmark

---

## 4. Content Gaps in LaTeX Report

### High Priority
- [ ] **Chapitre 1**: Verify the OWASP mapping table renders correctly (it was at the end of the file)
- [ ] **Chapitre 4**: Add actual scan result numbers from latest pipeline run to the KPI table
- [ ] **Chapitre 4**: The `fig:class_diagram` placeholder — consider if a React component diagram is useful or replace with a simpler component tree

### Medium Priority
- [ ] **Conclusion**: Coverage metric now says 13% — consider adding a justification paragraph explaining this is a demo app focused on DevSecOps infrastructure, not application code quality
- [ ] **Annexe A**: Add commands for running security scans locally (trivy, sonarcloud, zap)
- [ ] **Annexe B**: Add Wazuh API port (55000) and ArgoCD server port (8080) to the ports table
- [ ] **Annexe C**: Add missing glossary terms: SBOM, GHCR, STS, NetworkPolicy, Quality Gate

### Low Priority
- [ ] **chapitre5.tex** and **chapitre6.tex** exist but are NOT included in `rapport.tex` — verify if they contain content or are just empty stubs
- [ ] Consider adding an **Annexe D** summarizing the vulnerability demonstration (reference `VULNERABILITY-DEMO.md`)
- [ ] French accents: Some `.tex` files use accented characters directly — verify UTF-8 encoding is consistent

---

## 5. Pipeline / Screenshot Verification Checklist

Before final submission, run the full pipeline and capture fresh screenshots:

- [ ] Push code to GitHub → trigger all 4 workflows
- [ ] **deploy.yml**: Capture successful build + test + deploy steps
- [ ] **sonarcloud.yml**: Capture SonarCloud dashboard showing issues, duplications, security hotspots
- [ ] **trivy.yml**: Capture Trivy scan output (vulnerable deps, Dockerfile, IaC)
- [ ] **dast-zap.yml**: Capture ZAP report with all findings
- [ ] **ArgoCD**: Capture sync status after deployment
- [ ] **Grafana**: Capture monitoring dashboard with metrics
- [ ] **Wazuh**: Capture SIEM dashboard showing security events
- [ ] **App**: Capture login page + dashboard + XSS demo + debug mode

---

## 6. Excalidraw Files to Create

Create `.excalidraw` files in `public/` or `pfe_master_latex/images/`, then export as PNG.

| # | Filename | For Figure | Priority |
|---|----------|-----------|----------|
| 1 | `architecture-6-couches.excalidraw` | fig:couches | HIGH |
| 2 | `architecture-gcp.excalidraw` | fig:archi_physique | HIGH |
| 3 | `architecture-k8s.excalidraw` | fig:archi_k8s | HIGH |
| 4 | `ci-cd-sequence.excalidraw` | fig:seq_pipeline | HIGH |
| 5 | `wif-sequence.excalidraw` | fig:seq_wif | MEDIUM |
| 6 | `gitops-activity.excalidraw` | fig:act_gitops | MEDIUM |
| 7 | `deployment-diagram.excalidraw` | fig:deployment_diagram | MEDIUM |
| 8 | `shift-left.excalidraw` | fig:shiftleft | MEDIUM |
| 9 | `use-case.excalidraw` | fig:use_case_global | LOW |
| 10 | `scrum-process.excalidraw` | fig:scrum_process | LOW |
| 11 | `gantt-chart.excalidraw` | fig:gantt | LOW (can use gantt-pfe.html) |
| 12 | `class-diagram.excalidraw` | fig:class_diagram | LOW |

---

## 7. Quick Reference — File Locations

| Item | Path |
|------|------|
| LaTeX source | `pfe_master_latex/` |
| Images folder | `pfe_master_latex/images/` |
| Screenshots | `pfe_master_latex/images/screenshots/` |
| Main report | `pfe_master_latex/rapport.tex` |
| Bibliography | `pfe_master_latex/Biblio.bib` |
| Vuln demo guide | `VULNERABILITY-DEMO.md` |
| App source | `src/` |
| K8s manifests | `k8s/` |
| Terraform | `terraform/` |
| GitHub Actions | `.github/workflows/` |

---

## 8. Summary — Work Remaining

| Category | Items | Effort |
|----------|-------|--------|
| Screenshots to take | 9 | ~1 hour |
| Excalidraw diagrams to create | 12 (4 HIGH, 4 MEDIUM, 4 LOW) | ~3-4 hours |
| Bibliography cleanup | Remove 8 irrelevant + add 12 new | ~30 min |
| Content gaps (high priority) | 3 items | ~1 hour |
| Content gaps (medium priority) | 4 items | ~1 hour |
| Pipeline verification | Full pipeline run + screenshots | ~1 hour |
| **Total estimated** | | **~8-10 hours** |
