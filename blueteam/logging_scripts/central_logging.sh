#!/bin/bash
# Setup Central Logging Server (Run on 10.1.0.5 - Web Server)

set -euo pipefail

if [ "$(hostname -I | awk '{print $1}')" != "10.1.0.5" ]; then
    echo "This script should only run on the web server (10.1.0.5)"
    exit 1
fi

echo "[+] Setting up central logging server..."

# Install rsyslog
apt-get update
apt-get install -y rsyslog

# Configure rsyslog to receive remote logs
cat > /etc/rsyslog.d/99-blue-team.conf << 'EOF'
# Enable UDP reception
$ModLoad imudp
$UDPServerRun 514

# Enable TCP reception  
$ModLoad imtcp
$InputTCPServerRun 514

# Template for storing received messages
$template RemoteLogs,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs

# Also include original functionality
*.*;auth,authpriv.none -/var/log/syslog
auth,authpriv.* /var/log/auth.log
EOF

# Create remote logs directory
mkdir -p /var/log/remote
chown syslog:adm /var/log/remote

# Restart rsyslog
systemctl restart rsyslog

# Configure log rotation for remote logs
cat > /etc/logrotate.d/remote-logs << 'EOF'
/var/log/remote/*/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 syslog adm
}
EOF

echo "[+] Central logging server setup complete!"
echo "[+] Remote systems can now send logs to 10.1.0.5:514"