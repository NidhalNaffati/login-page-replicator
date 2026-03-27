#!/usr/bin/env bash
set -euo pipefail

# Minimal startup bootstrap for the Wazuh manager VM.
# Full Wazuh install is done in Phase 6 using the official installer.
apt-get update -y
apt-get install -y curl ca-certificates

cat >/etc/motd <<'EOF'
Wazuh manager VM ready.
Run the Phase 6 installer:
  curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
  bash wazuh-install.sh -a
EOF

