#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for the Wazuh manager VM.
# Automatically installs Wazuh 4.14.x (manager + indexer + dashboard).

apt-get update -y
apt-get install -y curl ca-certificates

# Download and run the official Wazuh installer
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
bash wazuh-install.sh -a 2>&1 | tee /var/log/wazuh-install.log

# Print credentials to MOTD for easy retrieval after SSH
PASS=$(grep "Password:" /var/log/wazuh-install.log | tail -1 | awk '{print $NF}')

cat >/etc/motd <<EOF
Wazuh 4.14 installed successfully.
Dashboard: https://$(curl -s ifconfig.me)
User:       admin
Password:   ${PASS}

Full install log: /var/log/wazuh-install.log
Credentials:      ~/wazuh-install-files.tar
EOF