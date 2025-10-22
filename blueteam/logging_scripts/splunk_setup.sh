#!/bin/bash
# Setup Splunk Universal Forwarder on Linux systems

set -euo pipefail

SPLUNK_INDEXER="10.1.0.5:9997"  # Web server as central log collector
SPLUNK_FORWARDER_URL="https://download.splunk.com/products/universalforwarder/releases/9.1.1/linux/splunkforwarder-9.1.1-64e843ea36b2-linux-2.6-amd64.deb"

echo "[+] Setting up Splunk Universal Forwarder..."

# Download and install Splunk forwarder
wget -O /tmp/splunkforwarder.deb "$SPLUNK_FORWARDER_URL"
dpkg -i /tmp/splunkforwarder.deb

# Configure forwarder
cat > /opt/splunkforwarder/etc/system/local/outputs.conf << EOF
[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = $SPLUNK_INDEXER

[indexer_discovery:default-autolb-group]
pass4SymmKey = competition2024
master_uri = https://$SPLUNK_INDEXER
EOF

cat > /opt/splunkforwarder/etc/system/local/inputs.conf << EOF
[monitor:///var/log/]
disabled = false
sourcetype = linux:syslog

[monitor:///var/log/blue_team/]
disabled = false
sourcetype = blue_team:logs

[monitor:///var/log/auth.log]
disabled = false
sourcetype = linux:auth

[monitor:///var/log/syslog]
disabled = false
sourcetype = linux:syslog
EOF

# Start Splunk forwarder
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt
/opt/splunkforwarder/bin/splunk enable boot-start

echo "[+] Splunk forwarder setup complete!"