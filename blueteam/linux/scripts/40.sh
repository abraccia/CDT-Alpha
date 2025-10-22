#!/bin/bash
# Automated Linux Hardening Script for Competition
# Run this on all Linux systems during prep day

set -euo pipefail

echo "[+] Starting automated Linux hardening..."

# Update system
echo "[+] Updating system packages..."
apt-get update && apt-get upgrade -y

# Secure SSH configuration
echo "[+] Configuring SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# Define the lines to search for and insert in the file
lines_to_insert=(
    "PermitRootLogin no"
    "PermitEmptyPasswords no"
    "KerberosAuthentication no"
    "GSSAPIAuthentication no"
    "X11Forwarding no"
    "MaxAuthTries 2"
    "ClientAliveInterval 300"
    "ClientAliveCountMax 2"
    "LoginGraceTime 20"
    "PermitUserEnvironment no"
    "AllowAgentForwarding no"
    "AllowTcpForwarding no"
    "PermitTunnel no"
    "MaxSessions 3"
    "Compression no"
    "TCPKeepAlive no"
    "UseDNS no"
    "LogLevel VERBOSE"
    "MaxSessions 1"
    "PubkeyAuthentication yes"
    "PasswordAuthentication yes"
    "AllowUsers blueteam john.hammond henry.wu robert.muldoon john.arnold"
)

# Replace or add the specified lines in the sshd_config file
for line in "${lines_to_insert[@]}"; do
    key=$(echo "$line" | awk '{print $1}')
    if grep -q "^$key" /etc/ssh/sshd_config; then
        sed -i "s|^$key.*|$line|" /etc/ssh/sshd_config
    else
        echo "$line" >> /etc/ssh/sshd_config
    fi
done

systemctl restart ssh

# Configure firewall
echo "[+] Configuring UFW firewall..."

if ! command -v ufw &>/dev/null; then
    echo "[+] UFW not found. Installing..."
    apt-get install ufw -y
else
    echo "[+] UFW is already installed."
fi

ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow only scored services based on IP
ufw allow from 10.1.0.0/24 to any port 22   # SSH
ufw allow from 10.1.0.0/24 to any port 25   # SMTP
ufw allow from 10.1.0.0/24 to any port 53   # DNS
ufw allow from 10.1.0.0/24 to any port 80   # HTTP
ufw allow from 10.1.0.0/24 to any port 21   # FTP
ufw allow from 10.1.0.0/24 to any port 3306 # MySQL

ufw --force enable

# Set up basic logging
echo "[+] Configuring logging..."
mkdir -p /var/log/blue_team
chmod 700 /var/log/blue_team

# Create monitoring script
cat > /usr/local/bin/monitor_system.sh << 'EOF'
#!/bin/bash
while true; do
    echo "$(date): Current connections:" >> /var/log/blue_team/network_monitor.log
    netstat -tunap >> /var/log/blue_team/network_monitor.log
    echo "$(date): Current processes:" >> /var/log/blue_team/process_monitor.log
    ps aux >> /var/log/blue_team/process_monitor.log
    sleep 60
done
EOF

chmod +x /usr/local/bin/monitor_system.sh

# Start monitoring in background
nohup /usr/local/bin/monitor_system.sh > /dev/null 2>&1 &

echo "[+] Hardening complete!"