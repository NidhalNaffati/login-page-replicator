# Wazuh Security Monitoring Runbook — GKE Autopilot

> **Platform:** GKE Autopilot (`devops-cluster`, `europe-west1`)
> **Wazuh version:** 4.14.4 (manager + indexer + dashboard)
> **Last updated:** March 2026

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│  GKE Autopilot Cluster                              │
│                                                     │
│  ┌─────────────┐     1514/tcp     ┌──────────────┐ │
│  │ security ns │ ──────────────►  │  Wazuh VM    │ │
│  │ DaemonSet   │     1515/tcp     │  10.10.0.2   │ │
│  │ (4 agents)  │                  │  e2-medium   │ │
│  └─────────────┘                  └──────────────┘ │
│                                        │            │
│  /var/log/containers/*.log             │ HTTPS:443  │
│  /var/log/pods/*/*/*.log               ▼            │
│                                   Dashboard         │
│                                   34.77.160.226     │
└─────────────────────────────────────────────────────┘
```

### login
Wazuh dashboard login:

```
URL:      https://34.77.160.226
Username: admin
Password: Se*OxXktM?17?DQzvK7gfF2zdHvBsqMM
```


### Components

| Component | Location | Description |
|-----------|----------|-------------|
| Wazuh Manager | GCE VM `wazuh-manager` (`europe-west1-b`) | Receives agent events, runs analysis engine |
| Wazuh Indexer | Same VM | OpenSearch-based event storage |
| Wazuh Dashboard | Same VM, port 443 | Web UI for alerts, agents, compliance |
| Wazuh Agent | `security` namespace DaemonSet | Runs on each GKE node, ships logs to manager |

### Key IPs & Ports

| Resource | Value |
|----------|-------|
| Manager internal IP | `10.10.0.2` |
| Manager external IP | `34.77.160.226` |
| Agent → Manager (events) | TCP `1514` |
| Agent → Manager (enrollment) | TCP `1515` |
| Dashboard | HTTPS `443` |
| Node subnet | `10.10.0.0/20` |
| Pods CIDR | `10.20.0.0/16` |

---

## Autopilot Constraints

GKE Autopilot enforces a restricted security profile. The following capabilities are **blocked**:

| Blocked capability | Impact on Wazuh |
|-------------------|-----------------|
| `hostPID: true` | No process-level monitoring |
| `hostNetwork: true` | No host network visibility |
| Privileged containers | No kernel-level syscall auditing |
| hostPath `/proc`, `/sys` | No hardware inventory (CPU, memory, cores) |

**What works:**
- Container log collection from `/var/log/containers` and `/var/log/pods`
- Network port inventory via syscollector
- OS detection (Amazon Linux 2023)
- Compliance mapping (PCI DSS, GDPR, NIST)
- Security event correlation from container logs

> This is a deliberate architectural tradeoff: Autopilot provides managed, cost-efficient nodes at the expense of node-level observability. For full Wazuh agent capability, a GKE Standard cluster would be required.

---

## Infrastructure (Terraform)

| Resource | File |
|----------|------|
| Wazuh VM | `terraform/wazuh.tf` |
| Firewall rules | `terraform/wazuh.tf` |
| Bootstrap script | `terraform/scripts/wazuh-manager-init.sh` |

### Firewall Rules

| Rule name | Ports | Source | Purpose |
|-----------|-------|--------|---------|
| `allow-wazuh-agents` | 1514, 1515, 55000 | `10.10.0.0/20`, `10.20.0.0/16` | Agent enrollment + event shipping |
| `allow-wazuh-dashboard` | 443 | Your IP `/32` | Dashboard web access |
| `allow-ssh-wazuh` | 22 | `35.235.240.0/20` (IAP) | SSH via `gcloud compute ssh` |

> ⚠️ The pods CIDR (`10.20.0.0/16`) **must** be included in `allow-wazuh-agents` source ranges. Without it, agents running in pods cannot reach the manager on port 1515 for enrollment.

---

## Kubernetes Manifests

| File | Purpose |
|------|---------|
| `k8s/security/wazuh-agent-daemonset.yaml` | ConfigMap + DaemonSet for Wazuh agent |
| `k8s/security/allow-wazuh-egress.yaml` | NetworkPolicy: agent → manager egress |
| `k8s/security/default-deny.yaml` | Default deny-all for `security` namespace |
| `k8s/security/allow-dns-egress.yaml` | DNS resolution for all namespaces |

### Agent Configuration (ossec.conf)

```xml
<ossec_config>
  <client>
    <server>
      <address>10.10.0.2</address>
      <port>1514</port>
      <protocol>tcp</protocol>
    </server>
    <auto_restart>yes</auto_restart>
  </client>
  <wodle name="syscollector">
    <disabled>no</disabled>
    <interval>1h</interval>
    <os>yes</os>
    <network>yes</network>
    <packages>no</packages>   <!-- blocked by Autopilot -->
    <hardware>no</hardware>   <!-- blocked by Autopilot -->
    <ports>yes</ports>
  </wodle>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/containers/*.log</location>
  </localfile>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/pods/*/*/*.log</location>
  </localfile>
</ossec_config>
```

---

## Deployment

### Initial deploy

```bash
cd /home/ryuke/IdeaProjects/todo-app

kubectl apply -f k8s/security/default-deny.yaml
kubectl apply -f k8s/security/allow-dns-egress.yaml
kubectl apply -f k8s/security/allow-wazuh-egress.yaml
kubectl apply -f k8s/security/wazuh-agent-daemonset.yaml

kubectl rollout status daemonset/wazuh-agent -n security --timeout=180s
```

### Update agent config only

```bash
kubectl apply -f k8s/security/wazuh-agent-daemonset.yaml
kubectl rollout restart daemonset/wazuh-agent -n security
kubectl rollout status daemonset/wazuh-agent -n security --timeout=180s
```

---

## Validation

### 1. Manager services healthy

```bash
gcloud compute ssh wazuh-manager \
  --zone=europe-west1-b \
  --project=pfe-esprit-489411 \
  --command='sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard --no-pager'
```

All three should show `active (running)`.

### 2. Registered agents

```bash
gcloud compute ssh wazuh-manager \
  --zone=europe-west1-b \
  --project=pfe-esprit-489411 \
  --command='sudo /var/ossec/bin/agent_control -l'
```

Expected output:
```
ID: 000, Name: wazuh-manager (server), IP: 127.0.0.1, Active/Local
ID: 00x, Name: wazuh-agent-xxxxx,      IP: any,       Active
...
```

### 3. Agent pods running

```bash
kubectl get daemonset wazuh-agent -n security
kubectl get pods -n security -l app=wazuh-agent -o wide
```

### 4. Agent logs — confirm enrollment and log collection

```bash
kubectl logs -n security -l app=wazuh-agent --tail=50 | grep -E "INFO|ERROR"
```

Look for:
- ✅ `Requesting a key from server: 10.10.0.2`
- ✅ `wazuh-agentd: INFO: Started`
- ✅ `wazuh-logcollector: INFO: Started`
- ❌ `Unable to connect to enrollment service` → check firewall source ranges

### 5. Indexer health

```bash
gcloud compute ssh wazuh-manager \
  --zone=europe-west1-b \
  --project=pfe-esprit-489411 \
  --command='curl -k -u admin:<PASSWORD> https://localhost:9200/_cluster/health?pretty'
```

Expected: `"status": "green"`.

---

## Dashboard Access

Open `https://34.77.160.226` in your browser and accept the self-signed certificate warning.

```
Username: admin
Password: <from ~/wazuh-install-files.tar on the VM>
```

To retrieve the password:

```bash
gcloud compute ssh wazuh-manager \
  --zone=europe-west1-b \
  --project=pfe-esprit-489411 \
  --command='sudo tar -xOf ~/wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt | grep -A2 "username: '"'"'admin'"'"'"'
```

> ⚠️ Never commit the admin password to Git. Store it in a secret manager or retrieve it from the VM at access time.

---

## Troubleshooting

### Agents stuck as Disconnected

Caused by DaemonSet rollouts creating new pod names while old registrations persist on the manager.

```bash
# List all agents
gcloud compute ssh wazuh-manager \
  --zone=europe-west1-b \
  --project=pfe-esprit-489411 \
  --command='sudo /var/ossec/bin/agent_control -l'

# Remove stale disconnected agent by ID
gcloud compute ssh wazuh-manager \
  --zone=europe-west1-b \
  --project=pfe-esprit-489411 \
  --command='sudo /var/ossec/bin/manage_agents -r <AGENT_ID>'
```

### Agents cannot enroll (port 1515 refused)

Check that the GCP firewall includes the pods CIDR:

```bash
gcloud compute firewall-rules describe allow-wazuh-agents \
  --project=pfe-esprit-489411 \
  --format='value(sourceRanges)'
```

Must include both `10.10.0.0/20` and `10.20.0.0/16`.

### Dashboard 500 error after VM restart

The indexer takes ~2 minutes to fully start. Restart services in order:

```bash
sudo systemctl restart wazuh-indexer
sleep 45
sudo systemctl restart wazuh-manager filebeat
sudo systemctl restart wazuh-dashboard
```

### Version mismatch (agent > manager)

Wazuh requires agent version ≤ manager version. Always keep both in sync.
Current pinned version: **4.14.4**.

---

## Security Hardening Checklist

- [ ] Rotate `admin` dashboard password if it appeared in terminal output
- [ ] Lock `allow-wazuh-dashboard` firewall rule to your IP (`/32`) — not `0.0.0.0/0`
- [ ] Delete temporary `allow-ssh-wazuh` rule if using IAP instead
- [ ] Codify all manually created firewall rules in Terraform to prevent drift
- [ ] Use ArgoCD to manage `k8s/security/` — avoid ad-hoc `kubectl apply` in production

---

## GitOps

This directory is managed via ArgoCD. The source of truth is:

```
k8s/security/
├── allow-dns-egress.yaml
├── allow-wazuh-egress.yaml
├── default-deny.yaml
└── wazuh-agent-daemonset.yaml   ← ConfigMap + DaemonSet
```

Avoid direct in-cluster edits. All changes should go through Git → ArgoCD sync.