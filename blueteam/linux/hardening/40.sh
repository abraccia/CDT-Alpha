#!/bin/bash
# Automated Linux Hardening Script for Competition
# Run this on all Linux systems during prep day

set -euo pipefail

echo "[+] Starting automated Linux hardening..."

# Update system
echo "[+] Updating system packages..."
apt-get update && apt-get upgrade -y

echo "[+] Removing unnecessary packages..."
apt-get purge -y telnet rsh-client rsh-redone-client

# Secure SSH script
echo "[+] Configuring SSH..."
if ! systemctl list-unit-files | grep -q '^ssh\.service'; then
    echo "[!] SSH service not found. Installing..."
    apt-get install ssh -y
fi
./ssh40.sh

# Configure firewall
echo "[+] Configuring UFW firewall..."

if ! command -v ufw &>/dev/null; then
    echo "[+] UFW not found. Installing..."
    apt-get install ufw -y
else
    echo "[+] UFW is already installed."
fi

ufw --force reset
ufw default allow incoming #Rustdesk https://github.com/rustdesk/rustdesk/issues/3951#issuecomment-1562998236
ufw default allow outgoing

echo "[+] Allowing RustDesk ports..."
ufw allow 21114:21119/tcp comment "RustDesk TCP ports"
ufw allow 21116/udp comment "RustDesk UDP port"

# Allow only scored services based on IP
# forgot we arent allowed to set up network range blocks
# ufw allow from 10.1.0.0/24 to any port 22   # SSH
# ufw allow from 10.1.0.0/24 to any port 25   # SMTP
# ufw allow from 10.1.0.0/24 to any port 53   # DNS
# ufw allow from 10.1.0.0/24 to any port 80   # HTTP
# ufw allow from 10.1.0.0/24 to any port 21   # FTP
# ufw allow from 10.1.0.0/24 to any port 3306 # MySQL

HOST_IP=$(hostname -I | awk '{print $1}')
case "$HOST_IP" in
  "10.1.0.2")  # Email Server
    ufw allow 25/tcp comment "SMTP"
    ufw allow 22/tcp comment "SSH"
    ;;
  "10.1.0.3")  # SSH Server
    ufw allow 22/tcp comment "SSH"
    ;;
  "10.1.0.4")  # MySQL Database
    ufw allow 3306/tcp comment "MySQL"
    ufw allow 22/tcp comment "SSH"
    ;;
  "10.1.0.5")  # Web Server
    ufw allow 80/tcp comment "HTTP"
    ufw allow 22/tcp comment "SSH"
    ;;
  "10.1.0.6")  # FTP Server
    ufw allow 21/tcp comment "FTP"
    ufw allow 20/tcp comment "FTP Data"
    ufw allow 22/tcp comment "SSH"
    ;;
  "10.1.0.11") # DNS Server
    ufw allow 53/tcp comment "DNS TCP"
    ufw allow 53/udp comment "DNS UDP"
    ufw allow 22/tcp comment "SSH"
    ;;
  *)
    echo "[!] Unknown IP, applying minimal rules"
    ufw allow 22/tcp comment "SSH"
    ;;
esac

ufw --force enable

# Set up auditing
echo "[+] Configuring auditd..."
apt-get install -y auditd
cat > /etc/audit/rules.d/competition.rules << 'EOF'
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/ssh/sshd_config -p wa -k sshd
-w /var/log/auth.log -p wa -k authentication
-w /var/log/syslog -p wa -k system
-w /usr/bin/ -p x -k executables
-w /usr/sbin/ -p x -k executables
-w /bin/ -p x -k executables
-w /sbin/ -p x -k executables
EOF

systemctl enable auditd
systemctl restart auditd

if ! command -v fail2ban &>/dev/null; then
    echo "[+] fail2ban not found. Installing..."
    apt-get install fail2ban -y
else
    echo "[+] fail2ban is already installed."
fi

# Configure fail2ban
echo "[+] Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
EOF

systemctl enable fail2ban
systemctl restart fail2ban

# Set up basic logging
echo "[+] Configuring logging..."
mkdir -p /var/log/blue_team
chmod 700 /var/log/blue_team

# Configure log rotation for blue team logs
cat > /etc/logrotate.d/blue_team << 'EOF'
/var/log/blue_team/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 root adm
}
EOF

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