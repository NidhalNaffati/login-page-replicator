# Rapport Complet de Projet DevSecOps

## Fiche d'identite du projet
- Intitule: Industrialisation DevSecOps d'une application Todo Web.
- Contexte: projet de fin d'etudes / projet d'ingenierie cloud-native.
- Application cible: frontend React servi par Nginx.
- Objectif principal: deployer de facon fiable, securisee et observable.
- Perimetre technique: Terraform, GCP, GKE Autopilot, Argo CD, Playwright, Wazuh.
- Perimetre organisationnel: developpement, securite, operations, qualite.
- Livrable principal: plateforme DevSecOps reproductible et documentee.
- Depot de reference: structure `terraform/`, `k8s/`, `src/`, `tests/`.
- Date de redaction: Avril 2026.

## Resume executif
- Ce rapport presente la demarche complete de conception et d'implementation.
- Le besoin initial etait de depasser un simple deploiement applicatif.
- L'objectif final est une chaine de valeur logicielle securisee de bout en bout.
- L'infrastructure est geree en IaC avec Terraform.
- L'orchestration est assuree par GKE Autopilot sur Google Cloud.
- Le mode de livraison adopte est GitOps avec Argo CD.
- Les tests E2E sont executes dans le cluster avec Playwright.
- La posture reseau suit un modele Zero Trust par NetworkPolicies.
- La supervision combine metriques applicatives et signaux de securite.
- La detection securite est prise en charge par Wazuh.
- Les identites machines sont gerees sans cles statiques via Workload Identity.
- Le resultat est une base solide pour une production a grande echelle.

## Table des matieres
- 1. Problematique
- 2. Etude de l'existant
- 3. Vision cible et principes directeurs
- 4. Besoins fonctionnels et non fonctionnels
- 5. Votre solution: approche globale
- 6. Technologies utilisees
- 7. Architecture physique
- 8. Architecture logique
- 9. Architecture reseau et securite
- 10. CI/CD, GitOps et strategie de tests
- 11. Observabilite, exploitation et operations
- 12. Gouvernance IAM et identites federes
- 13. Details d'implementation Terraform
- 14. Details d'implementation Kubernetes
- 15. Resultats obtenus et valeur metier
- 16. Risques, limites et points de vigilance
- 17. Plan d'amelioration continue
- 18. Conclusion generale
- 19. Annexes techniques

## 1. Problematique
- Les applications cloud modernes exigent un niveau d'automatisation eleve.
- Les deploiements manuels introduisent des erreurs difficiles a tracer.
- Les environnements heterogenes rendent la reproducibilite complexe.
- Les equipes doivent livrer vite sans sacrifier la securite.
- Le modele "deploy first, secure later" n'est plus acceptable.
- Kubernetes expose une grande puissance, mais aussi une grande surface de risque.
- Sans politiques reseau strictes, un pod compromis peut se propager lateralement.
- Sans modele d'identite robuste, les secrets CI/CD peuvent fuiter.
- Sans tests post-deploiement, les regressions arrivent en production.
- Sans observabilite, les incidents sont detectes trop tardivement.
- Sans SIEM, les signaux de compromission restent invisibles.
- La problematique centrale est donc multidimensionnelle.
- Elle couvre la qualite logicielle, la securite, et l'operabilite.
- Elle inclut la gouvernance des droits cloud et cluster.
- Elle implique aussi la conformite des flux inter-services.
- Le projet devait proposer une reponse coherente de bout en bout.
- La solution devait etre mesurable, evolutive, et documentable.

## 2. Etude de l'existant
- L'existant type observé dans de nombreux projets est centré sur la rapidité initiale.
- L'infrastructure est souvent preparee via console cloud (ClickOps).
- La documentation technique est parcellaire et peu synchronisee au reel.
- Les pipelines CI poussent des images, puis deployent de facon imperative.
- Les deploiements sont parfois faits via commandes ponctuelles non versionnees.
- Les identifiants cloud sont souvent des cles longues durees.
- Les tests E2E sont executes hors cluster et peu representatifs.
- Les flux reseau intra-cluster restent generalement ouverts.
- Les namespaces sont parfois utilises sans veritable isolation.
- Le monitoring est souvent limite a l'etat de pods et CPU.
- Les signaux de securite runtime ne sont pas centralises.
- Le diagnostic en incident depend de l'expertise individuelle.
- La dette operationnelle augmente a chaque evolution.
- Le temps de reprise apres echec reste eleve.
- Les audits de conformite sont longs et laborieux.
- Les preuves de controle sont difficilement consolidables.
- L'existant permet de "faire fonctionner".
- L'existant ne garantit pas de "fonctionner correctement dans la duree".

## 3. Vision cible et principes directeurs
- La vision cible repose sur une chaine DevSecOps unifiee.
- Le code est la source unique de verite.
- L'infrastructure est declarative et versionnee.
- L'etat du cluster est reconcilie automatiquement via GitOps.
- La securite est integree des la conception.
- Le reseau suit le principe du moindre privilege.
- L'identite suit le principe "keyless first".
- La qualite est verifiee automatiquement a chaque changement.
- Les tests doivent se rapprocher du contexte reel d'execution.
- Les metriques et logs doivent soutenir l'operationnel quotidien.
- Les alertes doivent etre exploitables par les equipes.
- Les decisions techniques doivent rester auditables.
- La plateforme doit rester evolutive et modulaire.
- Les environnements doivent etre reproductibles.
- Les risques doivent etre controles et documentes.

## 4. Besoins fonctionnels et non fonctionnels
### 4.1 Besoins fonctionnels
- Deployer l'application frontend sur Kubernetes.
- Exposer le service via Ingress HTTP.
- Supporter l'auto-scalabilite de la charge applicative.
- Permettre l'execution de tests E2E automatises.
- Assurer la collecte des metriques applicatives.
- Garantir l'accessibilite des composants critiques.
- Integrer des mecanismes de securite runtime.

### 4.2 Besoins non fonctionnels
- Reproductibilite complete des environnements.
- Traçabilite de tous les changements.
- Haute maintenabilite des configurations.
- Reduction de la surface d'attaque reseau.
- Reduction des secrets persistants dans CI/CD.
- Support d'une gouvernance IAM granulaire.
- Capacite d'audit des deploiements.
- Capacite de diagnostic en incident.
- Evolutivite de l'architecture.
- Lisibilite documentaire pour transfert d'equipe.

## 5. Votre solution: approche globale
- La solution combine IaC, GitOps, securite et tests continus.
- Terraform provisionne le socle cloud.
- GKE Autopilot heberge les workloads applicatifs.
- Argo CD synchronise les manifests Kubernetes depuis Git.
- Les namespaces structurent les responsabilites.
- Les NetworkPolicies implementent un Zero Trust concret.
- Playwright valide fonctionnellement les deploiements.
- Wazuh fournit une couche de detection securite supplementaire.
- Prometheus collecte les metriques exposees par l'app.
- Workload Identity limite l'usage de secrets statiques.
- Workload Identity Federation securise l'auth GitHub Actions vers GCP.
- L'ensemble forme une plateforme operationnelle coherente.

## 6. Technologies utilisees
### 6.1 Couche applicative
- React 18 pour la couche UI.
- TypeScript pour la robustesse du code.
- Vite pour le bundling rapide.
- Tailwind CSS et composants UI pour la productivite frontend.
- Nginx pour servir les assets statiques en production.

### 6.2 Couche qualite
- Vitest pour les tests unitaires et d'integration front.
- Playwright pour les tests end-to-end.
- Execution E2E en conteneur pour la reproductibilite.

### 6.3 Couche infrastructure
- Terraform pour definir VPC, GKE, IAM, WIF, VM Wazuh.
- Google Cloud Platform comme cloud provider.
- Artifact Registry pour stocker les images Docker.
- Compute Engine pour l'instance Wazuh Manager.

### 6.4 Couche orchestration
- Kubernetes sur GKE Autopilot.
- Objets principaux: Deployment, Service, Ingress, HPA, Job.
- Objets securite: NetworkPolicy, ServiceAccount.
- Objets observabilite: ServiceMonitor.

### 6.5 Couche delivery
- GitHub Actions pour build/push/deploiement pilote.
- Argo CD pour reconciliation GitOps continue.
- Hooks Argo CD pour lancer les tests apres sync.

### 6.6 Couche securite
- Workload Identity pour l'identite pods vers IAM.
- Workload Identity Federation pour CI sans cles longues.
- Wazuh Manager + Wazuh Agent pour SIEM runtime.

## 7. Architecture physique
### 7.1 Vue globale physique
- Un projet GCP centralise les ressources.
- Un backend Terraform en GCS stocke l'etat.
- Un VPC dedie isole le domaine applicatif.
- Un subnet principal heberge les ressources compute.
- Deux ranges secondaires adressent pods et services.
- Un cluster GKE Autopilot execute les workloads.
- Une VM Compute Engine heberge Wazuh Manager.
- Un registre Artifact Registry heberge les images.

### 7.2 Reseau GCP
- VPC: `devops-vpc`.
- Subnet: `devops-subnet`.
- CIDR noeuds: `10.10.0.0/20`.
- CIDR pods: `10.20.0.0/16`.
- CIDR services: `10.30.0.0/20`.
- Ces plages facilitent le controle des flux et firewall.

### 7.3 Cluster GKE
- Nom logique: `devops-cluster`.
- Mode: Autopilot.
- Region: `europe-west1`.
- Canal de release: `REGULAR`.
- Workload pool active pour identites KSA/GSA.
- Autoscaling infra gere par la couche managée.

### 7.4 Composant Wazuh
- VM dediee `wazuh-manager`.
- Type machine: `e2-medium`.
- Image: Ubuntu LTS.
- Bootstrap automatisé via script d'init.
- Ports agents autorises: 1514, 1515, 55000.
- Dashboard accessible via 443 (a restreindre en prod).

### 7.5 Flux physiques majeurs
- Pods applicatifs tirent images depuis Artifact Registry.
- Actions GitHub s'authentifient a GCP via WIF.
- Argo CD recupere manifests depuis Git.
- Pods Wazuh Agent envoient flux au manager VM.
- Scraping metriques depuis observability vers app.

## 8. Architecture logique
### 8.1 Segmentation par namespaces
- Namespace `app` pour le produit applicatif.
- Namespace `testing` pour jobs de validation.
- Namespace `observability` pour supervision metriques.
- Namespace `security` pour politiques et agents securite.
- Namespace `argocd` pour controle GitOps.

### 8.2 Domaine `app`
- Deployment principal `login-page-replicator`.
- Service interne expose port HTTP et metrics.
- Ingress GCE expose l'application en externe.
- HPA ajuste le nombre de replicas selon CPU.
- Sidecar exporter publie des metriques Nginx.

### 8.3 Domaine `testing`
- Job Playwright disponible pour tests E2E.
- ServiceAccount dedie pour execution securisee.
- Base URL orientee service intra-cluster.
- Politique de retention des jobs pour analyse.

### 8.4 Domaine `observability`
- ServiceMonitor cible les metriques de l'app.
- Namespace autorise a joindre port metrics.
- Separation claire entre collecte et application.

### 8.5 Domaine `security`
- NetworkPolicies definissent la matrice de flux.
- DaemonSet Wazuh Agent sur chaque noeud.
- ConfigMap centralise la config agent.
- Egress limite vers le manager Wazuh.

### 8.6 Domaine `argocd`
- Application Argo CD pour `k8s/app`.
- Application Argo CD optionnelle pour `k8s/testing`.
- Sync auto, self-heal et prune actives.
- Mode declaratif et auditable.

## 9. Architecture reseau et securite
### 9.1 Strategie Zero Trust
- Politique de base: `default-deny` en ingress et egress.
- Chaque flux necessaire est explicitement autorise.
- Aucune communication implicite entre namespaces.
- Le modele reduit fortement les mouvements lateraux.

### 9.2 Flux DNS
- `allow-dns-egress` autorise TCP/UDP 53.
- Sans cette regle, la resolution de noms serait bloquee.
- Cette regle est appliquee namespace par namespace.

### 9.3 Flux applicatifs
- `allow-testing-to-app` autorise testing vers app:80.
- `allow-playwright-hook` autorise hook PostSync vers app.
- Les regles ingress app filtrent la source par labels.

### 9.4 Flux observabilite
- `allow-prometheus-scrape` autorise scraping sur 9113.
- `allow-observability-to-app-metrics` precise la cible.
- `allow-observability-internal` structure les flux internes.

### 9.5 Flux systeme
- Regles kubelet probes dediees pour app/observability.
- Regles API server egress pour besoin observability.
- Equilibre entre securite stricte et operabilite.

### 9.6 Flux securite Wazuh
- Agents autorises uniquement vers IP manager dediee.
- Ports limites au strict necessaire.
- Tracabilite renforcée des evenements runtime.

## 10. CI/CD, GitOps et strategie de tests
### 10.1 Pipeline CI/CD cible
- Build de l'image applicative.
- Build de l'image Playwright.
- Push des images dans Artifact Registry.
- Mise a jour des tags d'images.
- Deploiement ou sync des manifests.

### 10.2 Authentification CI/CD
- GitHub Actions utilise WIF vers GCP.
- Pas de cle JSON statique dans les secrets.
- Reduction du risque de compromission long terme.

### 10.3 GitOps avec Argo CD
- Argo CD surveille les manifests Git.
- Sync automatisee pour converger vers l'etat desire.
- Self-heal restaure l'etat attendu en cas de drift.
- Prune supprime les ressources obsoletees.

### 10.4 Tests E2E
- Approche 1: Job `testing/playwright-job.yaml`.
- Approche 2: Hook PostSync `app/playwright-hook.yaml`.
- Avantage hook: validation proche du deploiement reel.
- Avantage job dedie: execution ponctuelle hors sync.

### 10.5 Tests unitaires
- Vitest couvre les composants et comportements front.
- Role complementaire aux tests E2E.
- Detection precoce des regressions logiques.

## 11. Observabilite, exploitation et operations
### 11.1 Metriques applicatives
- Sidecar `nginx-prometheus-exporter` expose `:9113`.
- Service expose un port `metrics` dedie.
- ServiceMonitor collecte periodiquement.

### 11.2 Traces d'exploitation
- Logs pods accessibles via kubectl et outils cluster.
- Jobs E2E conserves temporairement pour post-mortem.
- HPA permet lecture de la dynamique de charge.

### 11.3 Monitoring securite
- Wazuh Agent collecte logs systeme et conteneurs.
- Wazuh Manager corrèle et centralise les evenements.
- Vision plus riche que le monitoring purement technique.

### 11.4 Operabilite
- Architecture decoupee par responsabilite.
- Manifestes lisibles et versionnes.
- Diagnostic facilite par la segmentation des domaines.

## 12. Gouvernance IAM et identites federes
### 12.1 Comptes de service
- GSA applicatif dedie au cluster.
- GSA GitHub Actions dedie au pipeline.
- Separation des privileges selon usage.

### 12.2 Roles IAM
- Lecture Artifact Registry pour runtime cluster.
- Ecriture Artifact Registry pour CI.
- Roles deploiement GKE et Cloud Run pour CI.
- IAM ServiceAccountUser configure selon besoin.

### 12.3 Workload Identity (GKE)
- Mapping KSA `app/gke-app-sa` vers GSA applicatif.
- Mapping KSA `testing/playwright-runner` vers GSA.
- Suppression du besoin de secrets docker persistants.

### 12.4 Workload Identity Federation (GitHub)
- Pool d'identite dedie GitHub.
- Provider OIDC `token.actions.githubusercontent.com`.
- Condition attribute.repository pour limiter le trust.
- Principe de moindre privilege applique a l'auth pipeline.

## 13. Details d'implementation Terraform
### 13.1 Structure des modules/fichiers
- `main.tf`: provider, backend, version Terraform.
- `apis.tf`: activation des APIs GCP requises.
- `network.tf`: VPC, subnet, ranges secondaires.
- `gke.tf`: cluster Autopilot.
- `iam.tf`: comptes service et bindings IAM.
- `wif.tf`: federation identite GitHub.
- `wazuh.tf`: VM et firewalls Wazuh.
- `outputs.tf`: sorties utiles exploitation.

### 13.2 Bonnes pratiques observees
- Version provider explicite.
- Dependances critiques explicitees via `depends_on`.
- Variables de base externalisees.
- Sorties utiles pour integration pipeline.

### 13.3 Points de vigilance Terraform
- Backend GCS doit etre protege et versionne.
- Acces IAM du state bucket a restreindre.
- Valeurs par defaut projet/region a parametrer selon env.
- Regles firewall dashboard Wazuh a durcir en production.

## 14. Details d'implementation Kubernetes
### 14.1 Ressources applicatives
- Deployment avec requests/limits definis.
- ReadinessProbe configuree sur `/`.
- Service expose HTTP + metrics.
- Ingress type GCE pour exposition externe.
- HPA CPU target 60% sur 2..8 replicas.

### 14.2 Ressources de test
- Job Playwright avec limites ressources explicites.
- Variable `BASE_URL` interne cluster.
- `ttlSecondsAfterFinished` pour retention resultat.

### 14.3 Ressources de securite
- Policies `default-deny` par namespace.
- Policies allow-list DNS, metrics, tests, kubelet.
- Policy egress Wazuh dediee.

### 14.4 Ressources observabilite
- ServiceMonitor namespace observability.
- Selection des services app par labels.
- Scraping periodique (intervalle defini).

### 14.5 Ressources GitOps
- Applications Argo CD versionnees.
- Mode sync auto + selfHeal + prune.
- Hook PostSync pour validation fonctionnelle.

## 15. Resultats obtenus et valeur metier
### 15.1 Resultats techniques
- Infrastructure decrite de maniere declarative.
- Deploiement applicatif conteneurise et scalable.
- Flux reseau controles finement.
- Identite cloud modernisee sans cles statiques.
- Tests E2E integrables au cycle de livraison.
- Metriques applicatives exposes pour supervision.
- Detection securite runtime activee via Wazuh.

### 15.2 Valeur metier
- Reduction du risque operationnel.
- Amelioration de la fiabilite de livraison.
- Acceleration de l'onboarding technique.
- Facilitation des audits et preuves de controle.
- Meilleure confiance dans les mises en production.

### 15.3 KPI suggeres
- Taux de succes des deploiements.
- Temps moyen de detection incident.
- Temps moyen de resolution incident.
- Nombre de regressions detectees pre-production.
- Couverture des politiques reseau critiques.
- Taux de derive GitOps corrigee automatiquement.

## 16. Risques, limites et points de vigilance
### 16.1 Risques techniques
- Regles reseau trop strictes pouvant bloquer des flux legitimes.
- Tag d'image non remplace dans certains jobs.
- Drift entre manifests et ressources runtime hors GitOps.
- Saturation ressources si limites mal calibrees.

### 16.2 Limites actuelles
- Dependance a des identifiants/projets exemples a personnaliser.
- Durcissement Wazuh dashboard a finaliser pour prod.
- Couverture de tests front a etendre selon roadmap.
- Gouvernance multi-environnements a formaliser davantage.

### 16.3 Mesures de mitigation
- Procedures de validation des policies avant rollout.
- Verification automatique des tags images en pipeline.
- Revues de configuration periodiques.
- Tableaux de bord SLO/alerting progressifs.

## 17. Plan d'amelioration continue
### 17.1 Court terme
- Ajouter scan vulnerabilites images avant deploiement.
- Ajouter linting policy-as-code sur manifests.
- Etendre tests E2E sur cas metier critiques.
- Renforcer doc d'exploitation (runbooks incidents).

### 17.2 Moyen terme
- Introduire environnements `staging` et `prod` distincts.
- Mettre en place promotion d'artefacts signee.
- Integrer gestion de secrets managés (Secret Manager/Vault).
- Ajouter alertes securite plus granulaires cote SIEM.

### 17.3 Long terme
- Adopter SLO/SLA formels avec error budgets.
- Ajouter analyse de conformite continue (CIS/K8s benchmarks).
- Etendre au multi-region pour resilience avancee.
- Structurer une gouvernance FinOps associee.

## 18. Conclusion generale
- Le projet repond a une problematique reelle de production cloud.
- La solution depasse le simple deploiement applicatif.
- L'approche DevSecOps est implementee de facon pragmatique.
- L'IaC assure la reproductibilite et la maitrise du socle.
- Le GitOps apporte auditabilite et convergence continue.
- Le Zero Trust reseau reduit la surface d'attaque interne.
- Le modele d'identite sans cle renforce la securite CI/CD.
- L'observabilite et Wazuh ameliorent la detection operationnelle.
- L'architecture est evolutive et transferable a d'autres projets.
- Les perspectives d'amelioration sont claires et priorisables.

## 19. Annexes techniques
### 19.1 Correspondance exigences -> fichiers Terraform
- APIs cloud: `terraform/apis.tf`.
- Reseau VPC/subnet: `terraform/network.tf`.
- Cluster GKE: `terraform/gke.tf`.
- IAM et bindings: `terraform/iam.tf`.
- Federation GitHub: `terraform/wif.tf`.
- SIEM VM + firewall: `terraform/wazuh.tf`.
- Variables: `terraform/variables.tf`.
- Sorties: `terraform/outputs.tf`.

### 19.2 Correspondance exigences -> fichiers Kubernetes
- Namespaces: `k8s/namespaces.yaml`.
- App deployment/service/ingress/hpa: `k8s/app/*.yaml`.
- Hook E2E PostSync: `k8s/app/playwright-hook.yaml`.
- Job testing dedie: `k8s/testing/playwright-job.yaml`.
- Policies securite: `k8s/security/*.yaml`.
- Observabilite metrics: `k8s/observability/servicemonitor-nginx.yaml`.
- GitOps Argo CD: `k8s/argocd/*.yaml`.

### 19.3 Glossaire
- IaC: Infrastructure as Code.
- GitOps: pilotage de l'etat infra via Git.
- KSA: Kubernetes Service Account.
- GSA: Google Service Account.
- WIF: Workload Identity Federation.
- HPA: Horizontal Pod Autoscaler.
- SIEM: Security Information and Event Management.
- SLO: Service Level Objective.

### 19.4 Checklist de soutenance (suggestion)
- Presenter la problematique metier en 2 minutes.
- Expliquer l'existant et ses limites en 3 minutes.
- Montrer la cible architecture physique en 4 minutes.
- Montrer la cible architecture logique en 4 minutes.
- Defendre les choix securite et IAM en 4 minutes.
- Expliquer CI/CD + tests + GitOps en 4 minutes.
- Conclure avec KPI, limites et roadmap en 3 minutes.

### 19.5 Messages cles a retenir
- Le code est la verite du systeme.
- La securite doit etre native, pas additionnelle.
- Tester dans le contexte reel diminue les surprises.
- Observer en continu permet d'agir plus vite.
- L'industrialisation est un levier de qualite durable.
