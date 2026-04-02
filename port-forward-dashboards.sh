#!/bin/bash

# Start Grafana port-forward in the background
echo "Starting Grafana port-forward on port 3000 (observability namespace)..."
kubectl port-forward svc/kube-prom-grafana -n observability 3000:80 > /dev/null 2>&1 &
GRAFANA_PID=$!

# Start Argo CD port-forward in the background
echo "Starting Argo CD port-forward on port 8081 (argocd namespace)..."
kubectl port-forward svc/argocd-server -n argocd 8081:443 > /dev/null 2>&1 &
ARGOCD_PID=$!

# Ensure background processes are killed when the script stops
trap "echo 'Stopping port-forwards...'; kill $GRAFANA_PID $ARGOCD_PID 2>/dev/null; exit 0" SIGINT SIGTERM EXIT

# Give them a few seconds to start up
echo "Waiting for connections to establish..."
sleep 3

echo -e "\n=========================================="
echo "📊 Grafana Dashboard"
echo "URL: http://localhost:3000"
echo "Username: admin"
echo -n "Password: "
kubectl get secret kube-prom-grafana -n observability -o jsonpath='{.data.admin-password}' | base64 -d 2>/dev/null || echo "<Unavailable>"
echo -e "\n=========================================="

echo -e "\n=========================================="
echo "🐙 Argo CD Dashboard"
echo "URL: https://localhost:8081"
echo "Username: admin"
echo -n "Password: "
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || echo "<Unavailable>"
echo -e "\n==========================================\n"

# Try to open the links in the default browser
echo "Opening browsers..."
if command -v xdg-open &> /dev/null; then
    xdg-open "http://localhost:3000"
    xdg-open "https://localhost:8081"
elif command -v open &> /dev/null; then
    open "http://localhost:3000"
    open "https://localhost:8081"
else
    echo "Could not detect web browser opener. Please open the URLs manually."
fi

echo -e "\nRunning... Press [Ctrl+C] to stop and clean up."
wait

