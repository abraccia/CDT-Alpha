#!/bin/bash
# Setup Splunk Universal Forwarder on Linux systems with service-specific log monitoring

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo 'Must be run as root, exiting!'
  exit 1
fi

SPLUNK_INDEXER="10.1.0.5:9997"
SPLUNK_FORWARDER_URL="https://download.splunk.com/products/universalforwarder/releases/10.0.1/linux/splunkforwarder-10.0.1-c486717c322b-linux-amd64.deb"

echo "[+] Setting up Splunk Universal Forwarder..."


if ! id -u splunk &>/dev/null; then
    echo "Creating splunk user and group..."
    sudo groupadd splunk
    sudo useradd -r -g splunk splunk
else
    echo "Splunk user already exists."
fi


# Download and install Splunk forwarder
wget -O /tmp/splunkforwarder.deb "$SPLUNK_FORWARDER_URL"
dpkg -i /tmp/splunkforwarder.deb

# Configure outputs.conf
cat > /opt/splunkforwarder/etc/system/local/outputs.conf << EOF
[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = $SPLUNK_INDEXER

[indexer_discovery:default-autolb-group]
pass4SymmKey = password
master_uri = https://$SPLUNK_INDEXER
EOF

# Detect IP address of the host
HOST_IP=$(hostname -I | awk '{print $1}')
echo "[+] Detected host IP: $HOST_IP"

# Configure inputs.conf based on host IP (service role)
INPUTS_PATH="/opt/splunkforwarder/etc/system/local/inputs.conf"

case "$HOST_IP" in
  "10.1.0.2")  # Email Server (SMTP)
    cat > "$INPUTS_PATH" << EOF
[monitor:///var/log/mail.log]
disabled = false
sourcetype = mail:log

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
    ;;

  "10.1.0.3")  # SSH Server
    cat > "$INPUTS_PATH" << EOF
[monitor:///var/log/auth.log]
disabled = false
sourcetype = linux:auth

[monitor:///var/log/secure]
disabled = false
sourcetype = linux:auth

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
    ;;

  "10.1.0.4")  # MySQL Database
    cat > "$INPUTS_PATH" << EOF
[monitor:///var/log/mysql/error.log]
disabled = false
sourcetype = mysql:error

[monitor:///var/log/mysql/mysql.log]
disabled = false
sourcetype = mysql:general

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
    ;;

  "10.1.0.5")  # Web Server (nginx)
    cat > "$INPUTS_PATH" << EOF
[monitor:///var/log/nginx/access.log]
disabled = false
sourcetype = nginx:access

[monitor:///var/log/nginx/error.log]
disabled = false
sourcetype = nginx:error

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
    ;;

  "10.1.0.6")  # FTP Server
    cat > "$INPUTS_PATH" << EOF
[monitor:///var/log/vsftpd.log]
disabled = false
sourcetype = ftp:vsftpd

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
    ;;

  "10.1.0.11")  # DNS Server
    cat > "$INPUTS_PATH" << EOF
[monitor:///var/log/syslog]
disabled = false
sourcetype = dns:bind

[monitor:///var/log/named/named.log]
disabled = false
sourcetype = dns:named

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
    ;;

  *)  # Default case
    echo "[!] Unknown IP address. Setting up basic monitoring."
    cat > "$INPUTS_PATH" << EOF
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
    ;;
esac

# Start Splunk forwarder
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt
/opt/splunkforwarder/bin/splunk enable boot-start

echo "[+] Splunk forwarder setup complete!"