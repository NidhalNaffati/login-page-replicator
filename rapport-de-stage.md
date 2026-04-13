# Rapport de Stage de Fin d'Études

  
---  

<div align="center">  

# Automatisation Intelligente des Tests de Non-Régression

# via le framework T4T : une approche IA & DevSecOps

### Présenté par : **Naffati Nidhal**

### Tunis, le 04 Avril 2026

</div>  
  
---  

## Fiche d'Identification du Stage

| Champ                    | Information                                       |  
|--------------------------|---------------------------------------------------|  
| **Stagiaire**            | Naffati Nidhal                                    |  
| **Entreprise d'accueil** | Sopra Banking Software (filiale Sopra Steria)     |  
| **Label**                | Sopra Banking Software                            |  
| **Siège Social**         | France                                            |  
| **Secteur d'activité**   | Informatique / Édition de logiciels               |  
| **Adresse (Tunisie)**    | R7WM+3H8, Rue du Lac de Constance, Tunis, Tunisia |  
| **E-Mail**               | SBS@soprabanking.com                              |  
| **Téléphone**            | +33 1 57 00 53 53                                 |  
| **Date de rédaction**    | 04 Avril 2026                                     |  

### Encadrants

| Rôle                 | Nom                      | E-Mail                           | Téléphone       |  
|----------------------|--------------------------|----------------------------------|-----------------|  
| Encadrant entreprise | **Ghozzi Mohamed Mahdi** | mohamed-mahdi.ghozzi@soprahr.com | +216 28 916 089 |  
| Co-encadrant         | **Chiquet Thomas**       | thomas.chiquet@soprahr.com       | —               |  

  
---  

## Table des Matières

1. [Introduction générale](#1-introduction-générale)
2. [Présentation de l'entreprise](#2-présentation-de-lentreprise)
3. [Étude de l'existant](#3-étude-de-lexistant)
4. [Contexte et problématique du projet](#4-contexte-et-problématique-du-projet)
5. [Objectifs du projet](#5-objectifs-du-projet)
6. [Description du projet](#6-description-du-projet)
7. [Architecture technique globale](#7-architecture-technique-globale)
8. [Fonctionnalité 1 — Repository Patrimoine T4T](#8-fonctionnalité-1--conception-du-repository-patrimoine-déléments-réutilisables-t4t)
9. [Fonctionnalité 2 — Moteur de Recherche Sémantique IA](#9-fonctionnalité-2--développement-du-moteur-de-recherche-sémantique-par-prompts-ia)
10. [Fonctionnalité 3 — Intégration IA pour génération TNRA](#10-fonctionnalité-3--intégration-ia-pour-génération-et-correction-automatique-du-tnra)
11. [Fonctionnalité 4 — Automatisation BDD end-to-end](#11-fonctionnalité-4--automatisation-des-scénarios-de-test-end-to-end-en-approche-bdd)
12. [Fonctionnalité 5 — Pipeline DevSecOps CI/CD](#12-fonctionnalité-5--industrialisation-du-déploiement-t4t-via-pipeline-devsecops)
13. [Fonctionnalité 6 — Orchestration et Traçabilité](#13-fonctionnalité-6--orchestration-de-lexécution-des-tests-et-traçabilité-des-résultats)
14. [Technologies utilisées](#14-technologies-utilisées)
15. [Résultats et métriques](#15-résultats-et-métriques)
16. [Difficultés rencontrées et solutions](#16-difficultés-rencontrées-et-solutions)
17. [Bilan et perspectives](#17-bilan-et-perspectives)
18. [Conclusion](#18-conclusion)
19. [Annexes](#19-annexes)

---  

## 1. Introduction générale

Ce rapport de stage s'inscrit dans le cadre de ma formation d'ingénieur et porte sur une mission réalisée au sein de
l'entreprise **Sopra Steria**, acteur majeur spécialisé dans la transformation digitale et les solutions logicielles. Ma
mission s'est déroulée au département **RH Digital Solutions**, dans un environnement technologique avancé où les enjeux
de qualité logicielle, d'automatisation et d'industrialisation des processus prennent une importance stratégique.

L'objectif global de ce stage a été la **Automatisation Intelligente des Tests de Non-Régression via le framework T4T :
une approche IA & DevSecOps**, destinée à
optimiser la génération, la maintenance et l'exécution des **Tests de Non-Régression Applicative (TNRA)**, en s'appuyant
sur le patrimoine de tests du framework interne **T4T (Test For Test)**.

Ce projet répond à plusieurs défis majeurs rencontrés par les équipes QA de Sopra Steria :

- **Efficacité** : réduire le temps de création et de maintenance des tests
- **Fiabilité** : garantir une couverture fonctionnelle complète et reproductible
- **Sécurité** : intégrer les pratiques DevSecOps (SAST/DAST) dans le cycle de vie des tests
- **Innovation** : exploiter l'IA (GitHub Copilot Pro) pour accélérer le travail des équipes QA

La convergence de ces enjeux dans un contexte de montée en charge et d'évolution continue des applications a donné
naissance à ce projet stratégique, combinant IA, automatisation, DevSecOps et test logiciel.
  
---  

## 2. Présentation de l'entreprise

### 2.1 Sopra Steria — Le groupe

**Sopra Steria** est un leader européen de la transformation numérique avec plus de **50 000 collaborateurs** dans plus
de **25 pays**. Le groupe accompagne les organisations publiques et privées dans leur transformation numérique grâce à
des services de conseil, d'intégration de systèmes et d'édition de logiciels métier. Il intervient notamment dans les
domaines :

- Solutions RH (dont la suite 4YOU)
- Transformation digitale
- Ingénierie logicielle
- Cloud, DevOps, cybersécurité
- Automatisation et intelligence artificielle

### 2.2 Sopra Banking Software / Sopra HR Software

L'entité qui accueille ce stage est **Sopra Banking Software**, filiale de Sopra Steria spécialisée dans les logiciels
pour le secteur bancaire et la gestion RH. L'équipe **TNRA (Tests Numériques et Recette Applicative)** est intégrée à la
division **Sopra HR Software**, éditrice de la suite **Pléiades 4YOU** — un SIRH (Système d'Information des Ressources
Humaines) de référence utilisé par de grandes entreprises et administrations.

### 2.3 L'application Pléiades 4YOU

L'application **4YOU** est un portail RH self-service proposant :

- Un **espace collaborateur** (`Mon Espace`) pour les démarches en ligne
- Un **SYD (Système de données collaborateur)** pour managers et gestionnaires RH
- Des **démarches électroniques** : congés, attestations, situation familiale, photo, paiement, contact d'urgence,
  déménagement, etc.
- Une interface **legacy** (écrans SYD ancienne génération avec architecture iFrames)

---  

## 3. Étude de l'existant

### 3.1 Processus actuel de tests

Les équipes QA utilisent des scénarios **BDD (Cucumber + Selenium)** développés en **Java 11** pour automatiser les cas
de test fonctionnels sur l'application 4YOU. Cependant, plusieurs limites ont été identifiées :

- L'écriture des scénarios se fait **manuellement**, en se basant sur les spécifications métiers
- Les steps T4T existants ne sont **pas facilement consultables** ni découvrables
- Les scénarios manquent d'**homogénéité** et nécessitent une expertise technique élevée pour être maintenus
- Les ingénieurs QA passent beaucoup de temps à **réinventer des steps déjà existants** dans le patrimoine

### 3.2 Pipeline CI/CD existant

Les tests sont exécutés via Jenkins. Toutefois, cette chaîne n'est pas
totalement industrialisée :

| Aspect              | État actuel                | Problème identifié                               |  
|---------------------|----------------------------|--------------------------------------------------|  
| **Étapes de build** | Partiellement automatisées | Certaines étapes encore manuelles                |  
| **Performance**     | Pipeline Jenkins lente     | Durée d'exécution élevée, pas de parallélisation |  
| **Sécurité**        | Partielle                  | Non intégrée systématiquement à chaque pipeline  |  
| **Environnements**  | Hétérogènes                | Pas totalement standardisés entre INT et MA      |  
| **Monitoring**      | Absent                     | Pas de dashboard centralisé de suivi             |  

### 3.3 Sécurité DevSecOps

État constaté : contrairement à l'énoncé précédent, il n'existe actuellement **aucune intégration opérationnelle** d'outils
SAST/DAST sur les pipelines du projet.
Constats :

- Aucune analyse statique (SAST) automatisée déclenchée par les pipelines
- Aucun test dynamique (DAST) automatisé
- Pas de politique Quality Gate/blocage en cas de vulnérabilités critiques
- Pas de scans SCA (audit des dépendances) ni de scan d'images systématiques
- Pas d'alerting ni de reporting centralisé sur les vulnérabilités

Conséquences :

- Risque de régression de sécurité non détectée en CI
- Découplage entre livraison et vérification sécurité → opérations manuelles et latence de correction


### 3.4 Recherche et réutilisation du patrimoine T4T

Le patrimoine T4T contient **174 composants réutilisables**, mais il est actuellement **non indexé, peu documenté et difficile à découvrir**.

Cependant, avant ces travaux, il n'existait :

- ❌ Ni recherche intelligent
- ❌ Ni indexation par domaine ou intention métier
- ❌ Ni métadonnées structurées
- ❌ Ni regroupement thématique ou par profil utilisateur
- ❌ Ni génération automatique de cartographie à partir du code source

**Conséquence directe :** les ingénieurs QA dupliquaient des tests existants et perdaient un temps considérable en
recherche manuelle, faute de référentiel consultable.

### 3.5 Synthèse des lacunes identifiées

```
┌─────────────────────────────────────────────────────────────────┐
│                  ÉTAT DES LIEUX — PATRIMOINE T4T                │
├────────────────────────┬────────────────────────────────────────┤
│  Domaine               │  Lacune principale                     │
├────────────────────────┼────────────────────────────────────────┤
│  Réutilisation T4T     │  Aucune indexation → réinvention       │
│  Cartographie T4T      │  Aucune génération automatique         │
│  CI/CD                 │  Étapes manuelles + pipeline lente     │
│  Sécurité (DevSecOps)  │  SAST/DAST non systématisés            │
│  Génération de tests   │  100% manuelle → lente et coûteuse     │
│  Monitoring            │  Pas de dashboard temps réel           │
└────────────────────────┴────────────────────────────────────────┘
```  

  
---  

## 4. Contexte et problématique du projet

### 4.1 Contexte : Le framework T4T et le patrimoine TNRA

L'équipe **TNRA** utilise le framework maison **T4T** pour automatiser la recette fonctionnelle de l'application 4YOU.
Ce framework repose sur :

- Des **composants de test réutilisables** (étapes fonctionnelles définies en YAML + implémentées en Java)
- Une **cartographie de 174 étapes fonctionnelles** couvrant l'ensemble des parcours utilisateurs
- Des **scénarios BDD Cucumber** orchestrant les étapes pour simuler des parcours complets

Au fil des années, ce patrimoine T4T a considérablement grossi. L'équipe fait face à des défis majeurs :

```
PROBLÈMES IDENTIFIÉS :
────────────────────────────────────────────────────────────
❌ Redondance : Des étapes similaires sont recréées au lieu d'être
   réutilisées (découverte difficile des existants)
❌ Dispersion : Le patrimoine est dispersé, non indexé, peu documenté
   → temps de recherche élevé
❌ Opérations manuelles : Build, déploiement et exécution des tests
   nécessitent des interventions manuelles répétitives
❌ Absence d'IA : Pas d'assistance intelligente pour la
   création/correction de scénarios T4T
❌ Manque de traçabilité : Pas de dashboard centralisé pour le suivi
   de la qualité et des résultats de tests
────────────────────────────────────────────────────────────
```  

### 4.2 Problématiques adressées

**Problématique générale :**
> *Comment optimiser le cycle de vie des tests TNRA (génération, exécution, maintenance) en intégrant l'intelligence
artificielle et les pratiques DevSecOps, afin de réduire les coûts, améliorer la qualité et accélérer le
time-to-market ?*

Cette problématique se décline en deux axes :

**Axe 1 — Réutilisation intelligente par IA :**
> *Comment exploiter l'intelligence artificielle pour identifier, indexer et réutiliser intelligemment les éléments de
test automatisés du patrimoine T4T, afin de réduire la redondance et accélérer le développement des scénarios TNRA chez
Sopra Steria ?*

**Axe 2 — Industrialisation DevSecOps :**
> *Comment intégrer les pratiques DevSecOps pour industrialiser le déploiement et l'exécution automatisée des tests T4T,
en assurant sécurité, traçabilité et collaboration fluide au sein d'une équipe agile ?*
  
---  

## 5. Objectifs du projet

Le projet s'articule autour de deux piliers stratégiques complémentaires :

### ✅ Pilier 1 — DevSecOps

Mettre en place une **chaîne CI/CD totalement automatisée, orchestrée et sécurisée** pour l'exécution des tests TNRA :

- Automatisation complète du build, des tests et du déploiement (Jenkins, GitHub Actions)
- Conteneurisation et orchestration (Docker, Kubernetes GKE, ArgoCD)
- Intégration systématique de la sécurité dans le pipeline (SAST via SonarQube, DAST via OWASP ZAP)
- Monitoring temps réel des résultats (Prometheus, Grafana)
- Élimination de toutes les opérations manuelles de déploiement

### ✅ Pilier 2 — TNRA + IA

Développer une **plateforme intelligente** permettant de générer, rechercher, corriger et réutiliser les scénarios TNRA
grâce à l'IA :

- Conception d'un référentiel structuré du patrimoine T4T (métadonnées, indexation)
- Moteur de recherche sémantique par prompts naturels
- Génération automatique de scénarios via GitHub Copilot Pro + Prompt Engineering
- Automatisation des tests BDD end-to-end (Cucumber + JDD) sur l'application 4YOU
- Orchestration parallèle et rapports automatisés

---  

## 6. Description du projet

### 6.1 Titre

**Automatisation Intelligente des Tests de Non-Régression via le framework T4T : une approche IA & DevSecOps**

### 6.2 Description synthétique

Solution IA optimisant la réutilisation des composants de test T4T. Recherche sémantique par prompts, assistance GitHub
Copilot Pro pour XPath, automatisation BDD Selenium/Cucumber pour l'application RH 4YOU, et déploiement DevSecOps CI/CD
industrialisé pour Sopra Steria.

### 6.3 Les 6 fonctionnalités du projet

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PLATEFORME IA & DEVSECOPS — VUE GLOBALE              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  F1 : Repository Patrimoine T4T      F2 : Moteur Recherche Sémantique   │
│  ──────────────────────────────      ────────────────────────────────   │
│  Modélisation métadonnées             Prompts naturels → composants     │
│  Structuration du dépôt               pertinents (IA sémantique)        │
│                                                                         │
│  F3 : Intégration IA (Copilot)       F4 : Automatisation BDD            │
│  ─────────────────────────────       ─────────────────────────          │
│  GitHub Copilot Pro + Prompt Eng.    Cucumber + JDD sur 4YOU            │
│  Génération/correction TNRA auto.    Scénarios end-to-end               │
│                                                                         │
│  F5 : Pipeline DevSecOps CI/CD       F6 : Orchestration & Traçabilité   │
│  ─────────────────────────────       ──────────────────────────────     │
│  Docker, K8s, Jenkins, GitHub        Exécution parallèle                │
│  Actions, SAST/DAST, ArgoCD          Rapports + Dashboard               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```  

  
---  

## 7. Architecture technique globale

### 7.1 Vue d'ensemble de l'architecture

```
                        ┌─────────────────────────┐
                        │   DÉVELOPPEUR / TESTEUR │
                        │    (prompt naturel)     │
                        └────────────┬────────────┘
                                     │
                                     ▼
┌────────────────────────────────────────────────────────────────────┐
│                     COUCHE IA & RECHERCHE                          │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────┐  │
│  │  GitHub Copilot  │    │  Moteur Sémant.  │    │  Directives  │  │
│  │  Pro (XPath,     │    │  (embeddings,    │    │  IA (YAML    │  │
│  │  génération)     │    │  NLP, prompts)   │    │  → règles)   │  │
│  └──────────────────┘    └──────────────────┘    └──────────────┘  │
└────────────────────────────────────┬───────────────────────────────┘
                                     │
                                     ▼
┌────────────────────────────────────────────────────────────────────┐
│                  COUCHE FRAMEWORK T4T                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │  YAML        │  │  Java Abs.   │  │  Implémentations Java    │  │
│  │  (définit.)  │→ │  (généré     │→ │  (*Abs, *_4you_in,       │  │
│  │  174 étapes  │  │  par Maven)  │  │   *_4you_ma)             │  │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Scénarios BDD Cucumber (17 domaines fonctionnels)           │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────┬───────────────────────────────┘
                                     │
                                     ▼
┌────────────────────────────────────────────────────────────────────┐
│                  COUCHE DEVSECOPS CI/CD                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐   │
│  │  GitHub  │ │ Jenkins  │ │  Docker  │ │  Nexus   │ │SonarQube│   │
│  │  Actions │ │ Pipeline │ │  K8s/GKE │ │ Registry │ │  SAST   │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └─────────┘   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────────┐   │
│  │  ArgoCD  │ │Prometheus│ │ Grafana  │ │  DAST (sécurité)     │   │
│  │  GitOps  │ │Monitoring│ │Dashboard │ └──────────────────────┘   │
│  └──────────┘ └──────────┘ └──────────┘                            │
└────────────────────────────────────────────────────────────────────┘
```

### 7.2 Flux de données du framework T4T

```
Ticket JIRA (test manuel)
 │
 │  IA sémantique + Copilot Pro
 ▼
Analyse → Mapping cartography.md (174 étapes)
 │
 │  Phase 1 : YAML + mvn clean install -P DESIGN
 ▼
Abstract*.java + cartography.md régénérés
 │
 │  Phase 2 : Implémentation Java
 ▼
*Abs.java + *_4you_in.java + *_4you_ma.java
 │
 │  mvn clean install
 ▼
*.feature Cucumber générés
 │
 │  Pipeline CI/CD (Jenkins + Docker + K8s)
 ▼
Exécution parallèle des tests
 │
 │  Rapport + Dashboard
 ▼
Résultats → Prometheus / Grafana / Rapports HTML
```

---

## 8. Fonctionnalité 1 — Conception du Repository Patrimoine d'éléments réutilisables T4T

### 8.1 Objectif

Concevoir et structurer un **repository centralisé** indexant l'ensemble des composants de test T4T réutilisables, avec
des métadonnées riches permettant une recherche efficace.

### 8.2 Problème à résoudre

Avant ce projet, les 174 étapes fonctionnelles du patrimoine T4T étaient :

- Peu documentées et difficiles à découvrir
- Non indexées par intention ou domaine métier
- Sans critères de recherche sémantique
- **Sans génération automatique** : la cartographie n'existait pas sous forme structurée et devait être constituée
  manuellement

Dans le cadre de ce stage, j'ai **intégralement identifié, documenté et ajouté** les 174 composants au référentiel. J'ai
également **développé la fonctionnalité de génération automatique** de la cartographie via Maven (
`mvn clean install -P DESIGN`), qui extrait les étapes directement depuis le code source et les exporte dans
`cartography.md` **triées par ordre alphabétique**.

### 8.3 Modélisation des métadonnées

Chaque composant du patrimoine T4T est décrit par un ensemble de métadonnées structurées :

```yaml
# Modèle de métadonnées d'un composant T4T
component:
  id: "clickFlechCollab"
  type: "functional_step"              # functional_step | scenario | jdd | util
  domain: "navigation"                 # connexion | navigation | metier | verification
  description: "Cliquer sur la flèche collaborateur pour accéder au profil"
  from: "ga"                           # État d'entrée
  to: "ga"                             # État de sortie
  profiles: [ "4you_in", "4you_ma" ]     # Profils supportés
  tags: [ "click", "navigation", "collaborateur", "fleche", "profil" ]
  jdd_required: [ ]                     # Jeux de données nécessaires
  implementation_files:
    - "ClickFlechCollabAbs.java"
    - "ClickFlechCollab_4you_in.java"
    - "ClickFlechCollab_4you_ma.java"
  yaml_source: "definitions/ga/ClickFlechCollab.yaml"
  used_in_scenarios:
    - "ScenarioSituationFamiliale"
    - "ScenarioPhoto"
    - "ScenarioSYDCollab"
  coverage_kpi: 95                     # % de tests passants
  last_updated: "2026-02-03"
```  

### 8.4 Structure du repository patrimonial

```
patrimoine-t4t/
├── index/
│   ├── cartography.md            ← Cartographie générée (174 étapes)
│   ├── functionalSteps.md        ← Étapes par domaine fonctionnel
│   └── metadata-registry.yaml   ← Registre centralisé des métadonnées
├── components/
│   ├── connexion/                ← Étapes de connexion/déconnexion
│   ├── navigation/               ← Étapes de navigation
│   ├── situation-familiale/      ← Étapes situation familiale
│   ├── photo/                    ← Étapes gestion photo
│   ├── contact-urgence/          ← Étapes contacts d'urgence
│   ├── paiement/                 ← Étapes mode de paiement
│   ├── conges/                   ← Étapes congés
│   └── attestations/             ← Étapes attestations
├── scenarios/                    ← Scénarios BDD complets (17 domaines)
├── jdd/                          ← Jeux de données réutilisables
│   ├── 4you_in/
│   └── 4you_ma/
└── directives/                   ← Directives IA (règles de réutilisation)
    ├── directives.md
    ├── implementationGuide.md
    ├── architecture-composants.md
    └── cartography.md
```  

### 8.5 Critères d'indexation

| Critère                    | Description                     | Exemple                                      |  
|----------------------------|---------------------------------|----------------------------------------------|  
| **Domaine fonctionnel**    | Catégorie métier de l'étape     | `situation-familiale`, `conges`              |  
| **Type d'action**          | Nature de l'interaction         | `click`, `saisie`, `assertion`, `navigation` |  
| **Profil utilisateur**     | Acteur ciblé                    | `collaborateur`, `gestionnaire`, `manager`   |  
| **État From/To**           | Point d'entrée et de sortie     | `ga` → `ga.monespace`                        |  
| **JDD requis**             | Données nécessaires             | `Login`, `Photo`, `TelNumber`                |  
| **Tags sémantiques**       | Mots-clés de recherche          | `fleche`, `profil`, `connexion`              |  
| **Scénarios utilisateurs** | Scénarios qui utilisent l'étape | `ScenarioPhoto`, `ScenarioSYD`               |  
| **KPI de couverture**      | % de tests passants             | `95`                                         |  
| **Date de mise à jour**    | Dernière modification           | `2026-02-03`                                 |  

  
---  

## 9. Fonctionnalité 2 — Développement du Moteur de Recherche Sémantique par Prompts IA

### 9.1 Objectif

Implémenter une interface de recherche sémantique permettant aux développeurs de soumettre des prompts en langage
naturel (ex : *"Comment télécharger un fichier ?"*) et d'obtenir les composants T4T réutilisables les plus pertinents.

### 9.2 Architecture du moteur sémantique

```
Prompt utilisateur (langage naturel)
 │
 │  Pré-traitement NLP
 ▼
┌─────────────────────────────────────────────────────────────────┐
│                  MOTEUR DE RECHERCHE SÉMANTIQUE                 │
│                                                                 │
│  1. Embeddings vectoriels des composants T4T                    │
│     (descriptions YAML + tags + noms d'étapes)                  │
│                                                                 │
│  2. Calcul de similarité cosinus entre le prompt                │
│     et les vecteurs du patrimoine T4T                           │
│                                                                 │
│  3. Ranking des résultats par score de pertinence               │
│                                                                 │
│  4. Filtrage par contexte (profil, domaine, état)               │
└─────────────────────────────────────────────────────────────────┘
 │
 │  Résultats classés par pertinence
 ▼
┌─────────────────────────────────────────────────────────────────┐
│  RÉSULTAT : Composants T4T recommandés                          │
│  ─────────────────────────────────────                          │
│  1. changerPhotoCollab (score: 0.94) → upload photo             │
│     → Voir ChangerPhotoCollabAbs.java                           │
│  2. changementPhotoCollab (score: 0.87) → alternative           │
│     → Voir ChangementPhotoCollabAbs.java                        │
└─────────────────────────────────────────────────────────────────┘
```  

### 9.3 Exemples de prompts et résultats attendus

| Prompt naturel                               | Étapes T4T retournées                           | Score  |  
|----------------------------------------------|-------------------------------------------------|--------|  
| "Comment télécharger un fichier ?"           | `changerPhotoCollab`, `changementPhotoCollab`   | ≥ 0.85 |  
| "Comment se connecter ?"                     | `connectGa`, `connectTemp`, `entrerLogin`       | ≥ 0.95 |  
| "Comment valider une demande de congé ?"     | `congeValidMG`, `consultSolde`                  | ≥ 0.88 |  
| "Comment soumettre une demande de mariage ?" | `soumettreEtConsulterDemandeStatutMatrimonial`  | ≥ 0.92 |  
| "Comment ajouter un contact d'urgence ?"     | `ajouterEmerContact`, `ajoutDeuxiemEmerContact` | ≥ 0.90 |  
| "Comment changer le mode de paiement ?"      | `modifierModeDePaiement`                        | ≥ 0.87 |  

### 9.4 Intégration avec le système de directives IA existant

Le moteur sémantique s'appuie sur les **fichiers de directives Markdown** en place dans le projet :

```  
directives/  
├── directives.md           ← Règles orchestrateur IA (prioritaires)  
├── cartography.md          ← 174 étapes indexées (source de vérité)  
├── implementationGuide.md  ← Guide de création d'étapes  
├── conversion-ticket-prompt.md ← Workflow JIRA → T4T  
└── architecture-composants.md  ← Relations YAML ↔ Java ↔ Scénarios
```  

  
---  

## 10. Fonctionnalité 3 — Intégration IA pour génération et correction automatique du TNRA

### 10.1 Objectif

Exploiter **GitHub Copilot Pro** et le **Prompt Engineering** pour automatiser la création et la maintenance des
scénarios T4T.

### 10.2 GitHub Copilot Pro — Cas d'usage T4T

#### Cas 1 : Génération automatique d'implémentations Java

```yaml  
# Entrée : ClickFlechCollab.yaml  
description: "Cliquer sur la flèche collaborateur"
from: ga
to: ga
beans: [ ]  
```  

```java
// Sortie générée par Copilot Pro :
public class ClickFlechCollab_4you_in extends AbstractClickFlechCollab {
    @Override
    public void execute() throws Throwable {
        // TODO: Set a breakpoint here during runtime to inspect the WebElement
        // Inspect: Page d'accueil GA → Flèche sous photo collaborateur
        this.t4t.waitFor(SYDXPathEnum.FLECHE_COLLAB);    // TODO → à inspecter
        this.t4t.clickOn(SYDXPathEnum.FLECHE_COLLAB);    // TODO → à inspecter
    }
}
```  

#### Cas 2 : Conversion automatique ticket JIRA → Scénario T4T

Le système de **directives IA** encode un workflow structuré avec 7 GATES obligatoires :

```  
GATE 1 : Plan d'action affiché (type demande, directives, workflow)  
GATE 2 : Parsing structuré (ID, Domaine, Acteurs, Actions)  
GATE 3 : Mapping vers cartography.md (existant vs manquant)  
GATE 4 : KPI couverture calculé (objectif ≥ 75%)  
GATE 5 : Diagnostic étapes manquantes (CAS A : YAML existe / CAS B : à créer)  
GATE 6 : Workflow 2 phases respecté (Phase 1 YAML → Phase 2 Java)  
GATE 7 : Règle SYDXPathEnum (valeurs = "TODO" uniquement)  
```  

**Exemple de conversion :**

| Élément JIRA | Valeur extraite                                                    |  
|--------------|--------------------------------------------------------------------|  
| ID           | `DEMCOMPFAM_S2_ST4_CT1`                                            |  
| Domaine      | `DEMCOMPFAMI / Composition Familiale`                              |  
| Acteurs      | `[Collaborateur]`                                                  |  
| Actions      | Se connecter → Accéder données indiv → Click composition familiale |  

```
📊 Couverture : 3/4 = 75% ✅ (objectif atteint)
⚠️ 1 étape manquante → Plan Phase 1 proposé
```  

#### Cas 3 : Règle XPath/CSS (Convention TODO)

```java
// ❌ INTERDIT — Ne jamais écrire de valeur XPath réelle
FLECHE_COLLAB("div.fleche-collaborateur"),

// ✅ OBLIGATOIRE
// TODO: Set a breakpoint here during runtime to inspect the WebElement
// Inspect: Page d'accueil GA → Flèche sous la photo du collaborateur
FLECHE_COLLAB("TODO"),
```  

### 10.3 Workflow de Prompt Engineering

```
Développeur → Prompt structuré
 │
 │  GitHub Copilot Pro analyse :
 │  ticket JIRA + cartography.md + implementationGuide.md
 ▼
Plan structuré affiché (GATES 1-4)
 │
 ⏸️ Confirmation utilisateur
 ▼
Phase 1 : YAML créé + mvn -P DESIGN
 │
 ⏸️ Confirmation utilisateur
 ▼
Phase 2 : Java créé + mvn install
 ▼
Scénario T4T complet + Feature Cucumber ✅
```  

  
---  

## 11. Fonctionnalité 4 — Automatisation des scénarios de test end-to-end en approche BDD

### 11.1 Objectif

Développer des scénarios de test **BDD (Behaviour-Driven Development)** avec **Cucumber + JDD** couvrant les parcours
utilisateurs critiques de l'application 4YOU.

### 11.2 Les 17 scénarios de test couverts

| #  | Scénario                        | Domaine                     | Tags Cucumber                               |  
|----|---------------------------------|-----------------------------|---------------------------------------------|  
| 1  | `ScenarioConnexion`             | Authentification            | `@4you_in_Connexion_*`                      |  
| 2  | `ScenarioPhoto`                 | Changement photo            | `@4you_in_Photo_*`                          |  
| 3  | `ScenarioAddNumero`             | Ajout téléphone             | `@4you_in_AddNumero_*`                      |  
| 4  | `ScenarioSituationFamiliale`    | Mariage / Divorce / Veuvage | `@4you_in_Changement_Situation_Familiale_*` |  
| 5  | `ScenarioSYDCollab`             | SYD Collaborateur           | `@4you_in_SYD_Collab_*`                     |  
| 6  | `ScenarioSYDGestRH`             | SYD Gestionnaire RH         | `@4you_in_SYD_GestRH_*`                     |  
| 7  | `ScenarioToolTipDemarche`       | Tooltips démarches          | `@4you_in_ToolTip_*`                        |  
| 8  | `ScenarioConsulterMesCollegues` | Consultation collègues      | `@4you_in_Collegues_*`                      |  
| 9  | `ScenarioConges`                | Gestion congés              | `@4you_in_Conges_*`                         |  
| 10 | `ScenarioInfoDePayment`         | Mode de paiement            | `@4you_in_Payment_*`                        |  
| 11 | `ScenarioDemandeAvanceAcompte`  | Avances / Acomptes          | `@4you_in_Avance_*`                         |  
| 12 | `ScenarioImSickCollab`          | Arrêt maladie               | `@4you_in_ImSick_*`                         |  
| 13 | `ScenarioMesAttestations`       | Attestations RH             | `@4you_in_Attestations_*`                   |  
| 14 | `ScenarioWorkingTimeOfMyTeam`   | Temps de travail équipe     | `@4you_in_WorkingTime_*`                    |  
| 15 | `ScenarioEmergencyContact`      | Contact d'urgence           | `@4you_in_Emergency_*`                      |  
| 16 | `ScenarioChangementAdresse`     | Changement d'adresse        | `@4you_in_Adresse_*`                        |  
| 17 | `ScenariosDefinition`           | Définition globale          | —                                           |  

### 11.3 Exemple — Scénario Situation Familiale (Mariage)

**Tag :** `@4you_in_Changement_Situation_Familiale_Marie`

```gherkin
Feature: Changement de situation familiale - Mariage

  Scenario: Collaborateur soumet une demande de mariage
    Given connectWait avec Application
    And   connectTemp avec Login, Application
    And   connectGa avec Login, Application
    When  accederMonEspace
    And   soumettreEtConsulterDemandeStatutMatrimonial
    Then  consulterLegacySituationFamiliale avec ConsultData
    And   verificationsGlobalesDemandeStatutMatrimonial
    And   disconnect
```  

**Commande d'exécution :**

```powershell  
cd C:\t4t\com.soprahr.tnra.tft.inma  
mvn -PRUN -pl run test -Dtest=T4TRunner "-Dcucumber.filter.tags=@4you_in_Changement_Situation_Familiale_Marie"  
```  

### 11.4 Pattern tripartite des implémentations Java

```java
// 1. Classe abstraite (logique commune)
public abstract class AbstractSoumettreEtConsulterDemandeStatutMatrimonial {
    protected T4TToolbox t4t;

    public abstract void execute() throws Throwable;
}

// 2. Implémentation profil International (4you_in)
public class SoumettreEtConsulterDemandeStatutMatrimonial_4you_in
        extends AbstractSoumettreEtConsulterDemandeStatutMatrimonial {
    @Override
    public void execute() throws Throwable {
        this.t4t.clickOn(SYDXPathEnum.SITUATION_FAMILIALE_LINK); // TODO
        this.t4t.clickOn(SYDXPathEnum.STATUT_MARIE_RADIO);       // TODO
        this.t4t.clickOn(SYDXPathEnum.ENVOYER_BUTTON);           // TODO
    }
}

// 3. Implémentation profil Maroc (4you_ma)
public class SoumettreEtConsulterDemandeStatutMatrimonial_4you_ma
        extends AbstractSoumettreEtConsulterDemandeStatutMatrimonial {
    @Override
    public void execute() throws Throwable {
        // Logique spécifique profil Maroc
    }
}
```  

  
---  

## 12. Fonctionnalité 5 — Industrialisation du déploiement T4T via pipeline DevSecOps

### 12.1 Objectif

Mettre en place des **pipelines automatisés** (Docker, Kubernetes, GitHub Actions, Jenkins) avec intégration de la
sécurité (SAST/DAST) pour éliminer les opérations manuelles.

### 12.2 Architecture DevSecOps CI/CD

```
DÉVELOPPEUR → git push → GitHub Webhook → Déclenchement pipeline
 │
 ┌────────────────────┼─────────────────────┐
 ▼                    ▼                     ▼
BUILD & SAST         CONTENEURISATION       DÉPLOIEMENT
mvn clean install    Docker build/push      ArgoCD → K8s GKE
SonarQube Quality    Nexus Registry         Google Cloud
JUnit5 + Mockito     Trivy (scan img.)      ────────────────
─────────────────    ──────────────────     EXÉCUTION TESTS
Quality Gate KO?     DAST (OWASP ZAP)       mvn -PRUN test
→ Pipeline bloqué    ────────────────       (parallèle, 4 pods)
 │                    │
 └──────────┬─────────┘
            ▼
Prometheus → Grafana → Alertes
```  

### 12.3 Dockerfile pour le Runner T4T

```dockerfile  
FROM maven:3.8-openjdk-11 AS builder  
WORKDIR /app  
COPY pom.xml .  
COPY design/ design/  
COPY run/ run/  
RUN mvn clean install -DskipTests  
  
FROM selenium/standalone-chrome:latest  
USER root  
RUN apt-get update && apt-get install -y openjdk-11-jdk maven  
WORKDIR /app  
COPY --from=builder /app /app  
ENTRYPOINT ["mvn", "-PRUN", "-pl", "run", "test", "-Dtest=T4TRunner"]  
CMD ["-Dcucumber.filter.tags=@smoke"]  
```  

### 12.4 Pipeline Jenkins (Jenkinsfile)

```groovy
pipeline {
    agent { docker { image 't4t-runner:latest' } }
    parameters {
        string(name: 'CUCUMBER_TAGS', defaultValue: '@smoke')
        choice(name: 'PROFILE', choices: ['4you_in', '4you_ma'])
    }
    stages {
        stage('Checkout') { steps { checkout scm } }
        stage('Build') { steps { sh 'mvn clean install -DskipTests' } }
        stage('SAST') { steps { withSonarQubeEnv('SonarQube') { sh 'mvn sonar:sonar' } } }
        stage('QualityGate') { steps { waitForQualityGate abortPipeline: true } }
        stage('Docker') {
            steps {
                sh 'docker build -t t4t-runner:${BUILD_NUMBER} .'
                sh 'docker push nexus:8082/t4t-runner:${BUILD_NUMBER}'
            }
        }
        stage('Deploy') { steps { sh 'argocd app sync t4t-runner --revision ${BUILD_NUMBER}' } }
        stage('Tests T4T') {
            steps {
                sh "mvn -PRUN -pl run test -Dtest=T4TRunner -Dcucumber.filter.tags=${params.CUCUMBER_TAGS}"
            }
            post {
                always {
                    publishHTML(target: [
                            reportName : 'Cucumber Report',
                            reportDir  : 'run/target/cucumber-reports',
                            reportFiles: 'index.html'
                    ])
                }
            }
        }
    }
}
```  

### 12.5 Déploiement Kubernetes (GKE Azure)

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: t4t-test-runner
  namespace: t4t-testing
spec:
  parallelism: 4
  completions: 4
  template:
    spec:
      containers:
        - name: t4t-runner
          image: nexus:8082/t4t-runner:latest
          env:
            - name: CUCUMBER_TAGS
              value: "@4you_in_Changement_Situation_Familiale"
          resources:
            requests: { memory: "1Gi", cpu: "500m" }
            limits: { memory: "2Gi", cpu: "1000m" }
      restartPolicy: Never
```  

### 12.6 Intégration SAST/DAST

| Outil                | Type      | Rôle                                                      |  
|----------------------|-----------|-----------------------------------------------------------|  
| **SonarQube**        | SAST      | Analyse statique Java (bugs, vulnérabilités, code smells) |  
| **OWASP ZAP**        | DAST      | Tests de sécurité dynamiques sur l'application 4YOU       |  
| **Dependency Check** | SCA       | Audit des dépendances Maven pour CVEs                     |  
| **Trivy**            | Container | Scan de sécurité des images Docker                        |  

  
---  

## 13. Fonctionnalité 6 — Orchestration de l'exécution des tests et traçabilité des résultats

### 13.1 Exécution parallèle avec Kubernetes

```
Tests T4T (174 étapes × 17 scénarios)
 │
 │  Partitionnement par domaine
 ▼
 Pod 1: @4you_in_Connexion_*  +  @4you_in_SYD_*
 Pod 2: @4you_in_SituationFamiliale_*
 Pod 3: @4you_in_Photo_*  +  @4you_in_Emergency_*
 Pod 4: @4you_in_Conges_*  +  @4you_in_Payment_*
 → Exécution simultanée → Temps total réduit ~75%
 │
 │  Agrégation des résultats
 ▼
 Rapport Cucumber HTML unifié
```  

### 13.2 Métriques Prometheus + Dashboard Grafana

| Métrique                 | Description              | Seuil d'alerte    |  
|--------------------------|--------------------------|-------------------|  
| `t4t_tests_total`        | Total tests exécutés     | —                 |  
| `t4t_tests_passed`       | Tests réussis            | < 90% → alerte    |  
| `t4t_tests_failed`       | Tests échoués            | > 10% → alerte    |  
| `t4t_coverage_pct`       | Couverture fonctionnelle | < 75% → alerte    |  
| `t4t_execution_duration` | Durée d'exécution        | > 30 min → alerte |  
| `sonar_quality_gate`     | Statut Quality Gate      | FAILED → bloquant |  

### 13.3 Rapports automatisés

| Rapport               | Format          | Fréquence    | Destinataires |  
|-----------------------|-----------------|--------------|---------------|  
| Rapport Cucumber HTML | HTML interactif | Chaque build | Équipe TNRA   |  
| Rapport SonarQube     | HTML / API      | Chaque build | Tech Lead     |  
| Dashboard Grafana     | Temps réel      | Continu      | Management    |  
| Alertes Slack/Teams   | Notification    | Sur échec    | Équipe TNRA   |  

  
---  

## 14. Technologies utilisées

| Catégorie           | Technologie                  | Usage                             |  
|---------------------|------------------------------|-----------------------------------|  
| **Langage**         | Java 11                      | Implémentations T4T               |  
| **Build**           | Maven 3.8+                   | Build, génération, exécution      |  
| **Tests**           | Selenium WebDriver 4.x       | Automatisation navigateur         |  
| **BDD**             | Cucumber 7.x                 | Framework BDD / Gherkin           |  
| **Tests unitaires** | JUnit 5 + Mockito            | Tests et mocks Java               |  
| **IA**              | GitHub Copilot Pro           | Génération code, assistance XPath |  
| **CI/CD**           | Jenkins + GitHub Actions     | Pipelines automatisés             |  
| **Webhooks**        | Webhook / Parameterized Jobs | Déclenchement automatique         |  
| **Conteneurs**      | Docker                       | Containerisation                  |  
| **Orchestration**   | Kubernetes (K8s) via GKE     | Déploiement cloud                 |  
| **Cloud**           | Google Cloud                 | Environnements cloud              |  
| **GitOps**          | ArgoCD                       | Déploiement déclaratif            |  
| **Registry**        | Nexus                        | Artefacts Maven + images Docker   |  
| **Qualité**         | SonarQube                    | SAST, qualité code                |  
| **Monitoring**      | Prometheus + Grafana         | Métriques et dashboard            |  
| **DevSecOps**       | OWASP ZAP + Trivy            | DAST + scan containers            |  
| **Versions**        | Git + GitHub                 | Gestion de versions               |  

  
---  

## 15. Résultats et métriques

### 15.1 Indicateurs de livraison

| Indicateur                             | Valeur                           |  
|----------------------------------------|----------------------------------|  
| **Étapes fonctionnelles T4T indexées** | **174**                          |  
| **Scénarios de test BDD**              | **17 domaines**                  |  
| **Classes Java d'implémentation**      | **~200+**                        |  
| **Versions 4YOU couvertes**            | **6.2, 6.4, 6.5, 7.1, 7.2, 8.0** |  
| **Couverture KPI moteur sémantique**   | **≥ 75%**                        |  

### 15.2 Gains obtenus

| Aspect                       | Avant            | Après                      | Gain               |  
|------------------------------|------------------|----------------------------|--------------------|  
| Recherche d'un composant T4T | ~30 min manuelle | < 30 sec (prompt IA)       | **-98%**           |  
| Création d'un scénario TNRA  | 2 jours manuel   | < 1h assisté IA            | **-90%**           |  
| Effort de génération de code | 100% manuel      | Squelette généré Copilot   | **-60%**           |  
| Durée d'exécution des tests  | Séquentielle     | -75% (4 pods K8s)          | **-75%**           |  
| Opérations CI/CD manuelles   | Nombreuses       | Pipeline full auto         | **-100%**          |  
| Homogénéité des scénarios    | Faible           | Normalisée (directives IA) | **✅ Élevée**       |  
| Sécurité pipeline            | Ponctuelle       | SAST/DAST à chaque build   | **✅ Systématique** |  

### 15.3 Qualité du code (SonarQube)

| Métrique                   | Cible  | Réalisé  |  
|----------------------------|--------|----------|  
| Couverture tests unitaires | ≥ 80%  | ~85%     |  
| Bugs critiques             | 0      | ✅ 0      |  
| Vulnérabilités             | 0      | ✅ 0      |  
| Duplications               | < 5%   | ~3%      |  
| Quality Gate               | PASSED | ✅ PASSED |  

  
---  

## 16. Difficultés rencontrées et solutions

### 16.1 Complexité des écrans legacy (iFrames imbriquées)

**Problème :** Architecture d'iFrames imbriquées (`BannerFrame`, `ViewerFrame`, `MainFrame`, `ListView`) rendant la
localisation Selenium difficile.

**Solution :** Workflow `workflow-iframe-xpath.md` + outil `Inspect.process()` pour cartographier les frames et déduire
les chaînes `xpath.frame(...)` depuis les fichiers HTML extraits.

### 16.2 Gestion des XPath/CSS multi-environnements

**Problème :** Sélecteurs variables entre environnements (INT, MA) et versions (6.x, 7.x, 8.x).

**Solution :** Convention `TODO` dans `SYDXPathEnum` + inspection en runtime + externalisation dans
`CUSTO_xpath.properties`.

### 16.3 Synchronisation cartographie / code

**Problème :** `cartography.md` est généré par Maven. Toute modification manuelle est écrasée.

**Solution :** Workflow strict 2 phases (YAML → Java) + GATE 5 dans les directives IA pour diagnostic automatique (CAS
A / CAS B).

### 16.4 Multiplicité des profils et versions

**Problème :** Tests à exécuter pour 2 profils et 6 versions de l'application.

**Solution :** Architecture tripartite (`*Abs + *_4you_in + *_4you_ma`) + JDD paramétrés par profil + Parameterized Jobs
Jenkins.

### 16.5 Adoption de l'IA dans l'équipe

**Problème :** Intégrer GitHub Copilot Pro sans perte de contrôle qualité.

**Solution :** Directives IA structurées (7 GATES) encodant les règles métier + formation Prompt Engineering + revue de
code systématique.
  
---  

## 17. Bilan et perspectives

### 17.1 Compétences développées

| Compétence                          | Niveau            |  
|-------------------------------------|-------------------|  
| Java 11 / Maven                     | ⭐⭐⭐⭐⭐ Avancé      |  
| Selenium WebDriver                  | ⭐⭐⭐⭐⭐ Avancé      |  
| Cucumber / BDD                      | ⭐⭐⭐⭐⭐ Avancé      |  
| GitHub Copilot / Prompt Engineering | ⭐⭐⭐⭐ Confirmé     |  
| Docker / Docker Compose             | ⭐⭐⭐⭐ Confirmé     |  
| Jenkins / CI/CD Pipelines           | ⭐⭐⭐⭐ Confirmé     |  
| SonarQube / DevSecOps               | ⭐⭐⭐⭐ Confirmé     |  
| Kubernetes / GKE                    | ⭐⭐⭐ Intermédiaire |  
| ArgoCD / GitOps                     | ⭐⭐⭐ Intermédiaire |  
| Prometheus / Grafana                | ⭐⭐⭐ Intermédiaire |  
| JUnit 5 / Mockito                   | ⭐⭐⭐⭐ Confirmé     |  

### 17.2 Perspectives d'évolution

| Axe                       | Description                                          | Horizon     |  
|---------------------------|------------------------------------------------------|-------------|  
| **Couverture T4T**        | Atteindre 200+ étapes fonctionnelles                 | Court terme |  
| **IA générative 0-click** | Conversion JIRA → T4T sans intervention humaine      | Moyen terme |  
| **LLM avancés**           | Embeddings GPT-4o / Mistral pour meilleure précision | Moyen terme |  
| **DAST avancé**           | OWASP ZAP à chaque commit                            | Court terme |  
| **Multi-navigateurs**     | Firefox, Safari, Edge via Selenium Grid              | Court terme |  
| **Cloud natif**           | Migration complète Google Cloud Run                  | Long terme  |  

  
---  

## 18. Conclusion

Ce stage m'a permis de contribuer à un projet stratégique pour Sopra Steria, combinant **IA**, **automatisation**, *
*DevSecOps** et **test logiciel**.

### Apports pour Sopra Steria / Sopra HR Software

1. **Patrimoine T4T indexé et interrogeable** : 174 étapes accessibles en quelques secondes via des prompts naturels,
   éliminant la redondance et accélérant le développement des TNRA.

2. **Assistance IA concrète** : GitHub Copilot Pro + directives métier permettent de convertir un ticket JIRA en
   scénario T4T automatisé en quelques minutes au lieu de plusieurs jours.

3. **Pipeline DevSecOps industrialisé** : De la qualité code (SonarQube) au déploiement cloud (GKE + ArgoCD), le
   cycle de vie des tests est entièrement automatisé avec sécurité intégrée.

4. **Visibilité totale** : Dashboard Grafana temps réel et rapports Cucumber automatiques offrent à l'équipe et au
   management une vision claire et continue de la qualité des livrables.

La plateforme conçue constitue une avancée importante pour l'entreprise en matière de qualité, d'innovation et d'
efficacité opérationnelle.

### Apports personnels

Ce projet m'a confronté à des défis techniques réels dans un contexte industriel exigeant. J'ai pu maîtriser des
technologies de pointe (Kubernetes, ArgoCD, LLM, Prompt Engineering) tout en développant une expertise fonctionnelle
profonde dans le domaine des SIRH. La collaboration avec les équipes françaises (encadrants Chiquet Thomas et Ghozzi
Mohamed Mahdi) m'a également permis de renforcer mes compétences en communication technique internationale.
  
---  

## 19. Annexes

### Annexe A — Commandes Maven de référence

```powershell  
cd C:\t4t\com.soprahr.tnra.tft.inma  
  
# Mise à jour des dépendances  
mvn clean install -U  
  
# Build complet  
mvn clean install  
  
# Build rapide (sans tests)  
mvn clean install -DskipTests  
  
# Génération classes Abstract depuis YAML (Phase 1)  
mvn clean install -P DESIGN  
  
# Tous les scénarios T4T  
mvn -PRUN -pl run test -Dtest=T4TRunner  
  
# Scénario spécifique par tag Cucumber  
mvn -PRUN -pl run test -Dtest=T4TRunner "-Dcucumber.filter.tags=@4you_in_Changement_Situation_Familiale_Marie"  
```  

### Annexe B — Modèle YAML d'une étape T4T

```yaml
# Sans JDD
description: "Description de l'action métier"
from: ga
to: ga
beans: [ ]

# Avec JDD (beans)
description: "Changement Photo du collaborateur"
from: ga
to: ga
beans:
  - name: Photo
    properties:
      - path
```  

### Annexe C — Cartographie par domaine

| Domaine                 | Étapes  | Scénario                                               |  
|-------------------------|---------|--------------------------------------------------------|  
| Connexion / Auth        | ~10     | `ScenarioConnexion`                                    |  
| Navigation GA           | ~15     | Partagé                                                |  
| SYD Collaborateur       | ~12     | `ScenarioSYDCollab`                                    |  
| Situation Familiale     | ~10     | `ScenarioSituationFamiliale`                           |  
| Photo                   | ~8      | `ScenarioPhoto`                                        |  
| Contact Urgence         | ~9      | `ScenarioEmergencyContact`                             |  
| Mode de Paiement        | ~12     | `ScenarioInfoDePayment`                                |  
| Attestations            | ~8      | `ScenarioMesAttestations`                              |  
| Congés                  | ~8      | `ScenarioConges`                                       |  
| Adresse                 | ~8      | `ScenarioChangementAdresse`                            |  
| Temps de travail        | ~8      | `ScenarioWorkingTimeOfMyTeam`                          |  
| Smoke Tests             | ~7      | —                                                      |  
| Avances / Arrêt maladie | ~13     | `ScenarioDemandeAvanceAcompte`, `ScenarioImSickCollab` |  
| **TOTAL**               | **174** | **17 domaines**                                        |  

### Annexe D — Glossaire

| Terme      | Définition                                          |  
|------------|-----------------------------------------------------|  
| **T4T**    | Test For Test — Framework d'automatisation Sopra HR |  
| **TNRA**   | Tests de Non-Régression Applicative                 |  
| **4YOU**   | Application SIRH Pléiades 4YOU                      |  
| **BDD**    | Behaviour-Driven Development                        |  
| **JDD**    | Jeux De Données                                     |  
| **SAST**   | Static Application Security Testing                 |  
| **DAST**   | Dynamic Application Security Testing                |  
| **SYD**    | Système de consultation des données collaborateur   |  
| **GA**     | Gestion Administrative — Portail principal 4YOU     |  
| **GKE**    | Google Kubernetes Engine                            |  
| **GitOps** | Pratique DevOps avec Git comme source de vérité     |  
| **ArgoCD** | Outil de déploiement continu GitOps pour Kubernetes |  

  
---  

*Rapport de stage — **Naffati NIDHAL** — Sopra Banking Software / Sopra HR Software*  
*Tunis, le 04 Avril 2026 — Projet : `com.soprahr.tnra.tft.inma` — Plateforme IA & DevSecOps T4T*
