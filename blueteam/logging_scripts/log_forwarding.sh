#!/bin/bash
# Client Log Forwarding Setup (Run on all Linux clients)

set -euo pipefail

CENTRAL_SERVER="10.1.0.5"
HOST_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)

echo "[+] Setting up log forwarding to $CENTRAL_SERVER..."

# Install rsyslog if not present
if ! command -v rsyslogd &>/dev/null; then
    apt-get update
    apt-get install -y rsyslog
fi

# Configure rsyslog to forward logs
cat > /etc/rsyslog.d/99-forward-to-central.conf << EOF
# Forward all logs to central server
*.* @$CENTRAL_SERVER:514
EOF

# Restart rsyslog
systemctl restart rsyslog

# Create a script to monitor key files and forward changes
cat > /usr/local/bin/monitor_key_files.sh << 'EOF'
#!/bin/bash
# Monitor key files for changes and log to central server

FILES_TO_MONITOR=(
    "/etc/passwd"
    "/etc/shadow" 
    "/etc/group"
    "/etc/sudoers"
    "/etc/ssh/sshd_config"
)

for file in "${FILES_TO_MONITOR[@]}"; do
    if [ -f "$file" ]; then
        inotifywait -m -e modify,attrib,close_write,move,create,delete \
            --format "%w%f %e %T" --timefmt "%F %T" "$file" | \
        while read changed_file event timestamp; do
            logger -t "file-monitor" "File change detected: $changed_file $event at $timestamp"
        done &
    fi
done

wait
EOF

chmod +x /usr/local/bin/monitor_key_files.sh

# Start monitoring in background
nohup /usr/local/bin/monitor_key_files.sh > /dev/null 2>&1 &

echo "[+] Log forwarding setup complete for $HOSTNAME ($HOST_IP)"