# Argo CD Dashboard (Local Port-Forward)

Use these commands locally to open Argo CD from your cluster.

## 1) Start port-forward

```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

Keep this terminal open.

## 2) Open dashboard

```bash
xdg-open https://localhost:8081
```

If `xdg-open` is unavailable, open this URL manually in your browser:

- `https://localhost:8081`

## 3) Login credentials

Username:

```bash
echo admin
```

Password (read from Kubernetes secret):

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d && echo
```

## 4) Stop port-forward

In the terminal running port-forward, press `Ctrl+C`.

Or stop it from another terminal:

```bash
pkill -f 'kubectl port-forward svc/argocd-server -n argocd 8081:443' || true
```

