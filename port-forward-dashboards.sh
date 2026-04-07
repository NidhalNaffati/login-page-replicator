#!/bin/bash

WAZUH_URL="${WAZUH_URL:-https://34.77.160.226}"
WAZUH_USERNAME="${WAZUH_USERNAME:-admin}"
WAZUH_PASSWORD="${WAZUH_PASSWORD:-<retrieve from wazuh-manager VM>}"

APP_USERNAME="${APP_USERNAME:-TNEEIN01}"
APP_PASSWORD="${APP_PASSWORD:-4YOU}"
APP_ALT_USERNAME="${APP_ALT_USERNAME:-TNEEMA01}"

# Portable base64 decode function
decode_base64() {
  if echo "" | base64 -d &>/dev/null 2>&1; then
    base64 -d
  else
    base64 --decode
  fi
}

# Start Grafana port-forward in the background
echo "Starting Grafana port-forward on port 3000 (observability namespace)..."
kubectl port-forward svc/kube-prom-grafana -n observability 3000:80 > /dev/null 2>&1 &
GRAFANA_PID=$!

# Start Argo CD port-forward in the background
echo "Starting Argo CD port-forward on port 8081 (argocd namespace)..."
kubectl port-forward svc/argocd-server -n argocd 8081:443 > /dev/null 2>&1 &
ARGOCD_PID=$!

# Start app port-forward in the background
echo "Starting app port-forward on port 8080 (app namespace)..."
kubectl port-forward svc/login-page-replicator -n app 8080:80 > /dev/null 2>&1 &
APP_PID=$!

# Ensure background processes are killed when the script stops
trap "echo 'Stopping port-forwards...'; kill $GRAFANA_PID $ARGOCD_PID $APP_PID 2>/dev/null; exit 0" SIGINT SIGTERM EXIT

# Give them a few seconds to start up
echo "Waiting for connections to establish..."
sleep 3

GRAFANA_PASS=$(kubectl get secret kube-prom-grafana -n observability -o jsonpath='{.data.admin-password}' 2>/dev/null | decode_base64 2>/dev/null || echo "<Unavailable>")
ARGO_PASS=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' 2>/dev/null | decode_base64 2>/dev/null || echo "<Unavailable>")

echo -e "\n=========================================="
echo "📊 Grafana Dashboard"
echo "URL:      http://localhost:3000"
echo "Username: admin"
echo "Password: $GRAFANA_PASS"
echo -e "==========================================\n"

echo -e "\n=========================================="
echo "🐙 Argo CD Dashboard"
echo "URL:      https://localhost:8081"
echo "Username: admin"
echo "Password: $ARGO_PASS"
echo -e "==========================================\n"

echo -e "\n=========================================="
echo "🛡️  Wazuh Dashboard"
echo "URL:      $WAZUH_URL"
echo "Username: $WAZUH_USERNAME"
echo "Password: $WAZUH_PASSWORD"
echo "Note: Accept the self-signed certificate warning if prompted."
echo -e "==========================================\n"

echo -e "\n=========================================="
echo "🚀 App (app namespace)"
echo "URL:      http://localhost:8080"
echo "Username: $APP_USERNAME (alt: $APP_ALT_USERNAME)"
echo "Password: $APP_PASSWORD"
echo -e "==========================================\n"

# Try to open the links in the default browser
echo "Opening browsers..."
if command -v xdg-open &> /dev/null; then
    xdg-open "http://localhost:3000"
    xdg-open "https://localhost:8081"
    xdg-open "$WAZUH_URL"
    xdg-open "http://localhost:8080"
elif command -v open &> /dev/null; then
    open "http://localhost:3000"
    open "https://localhost:8081"
    open "$WAZUH_URL"
    open "http://localhost:8080"
elif command -v cmd.exe &> /dev/null; then
    # Git Bash on Windows fallback
    cmd.exe /c start "http://localhost:3000"
    cmd.exe /c start "https://localhost:8081"
    cmd.exe /c start "$WAZUH_URL"
    cmd.exe /c start "http://localhost:8080"
else
    echo "Could not detect web browser opener. Please open the URLs manually."
fi

echo -e "\nRunning... Press [Ctrl+C] to stop and clean up."
wait

