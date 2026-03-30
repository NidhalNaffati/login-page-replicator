# Grafana Dashboard (Local Port-Forward)

Use these commands locally to open Grafana from your cluster.

## 1) Start port-forward

```bash
kubectl port-forward svc/kube-prom-grafana -n observability 3000:80
```

Keep this terminal open.

## 2) Open dashboard

```bash
xdg-open http://localhost:3000
```

If `xdg-open` is unavailable, open this URL manually in your browser:

- `http://localhost:3000`

## 3) Login credentials

Username:

```bash
echo admin
```

Password (read from Kubernetes secret):

```bash
kubectl get secret kube-prom-grafana -n observability -o jsonpath='{.data.admin-password}' | base64 -d && echo
```

## 4) Stop port-forward

In the terminal running port-forward, press `Ctrl+C`.

Or stop it from another terminal:

```bash
pkill -f 'kubectl port-forward svc/kube-prom-grafana -n observability 3000:80' || true
```

