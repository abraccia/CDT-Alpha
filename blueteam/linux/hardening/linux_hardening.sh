#!/usr/bin/env bash
# Blue Team Bravo Linux Prep Script
# Purpose: basic hardening and setup for competition use
# Run as root

set -euo pipefail

LOG_FILE="/var/log/bravo_setup.log"
log() {
    echo "[BRAVO] $*" | tee -a "$LOG_FILE"
}

PORTS_TCP=(21 22 25 53 80 389 445 3306 3390 21114:21119)
PORTS_UDP=(53)

log "Starting Blue Team Bravo setup."

# Disable unnecessary services
log "Disabling unnecessary services..."
systemctl disable --now ufw firewalld apparmor 2>/dev/null || true
systemctl disable --now cups avahi-daemon 2>/dev/null || true

# Install essentials
log "Installing required packages..."
apt-get update -y >/dev/null
apt-get install -y net-tools iptables-persistent >/dev/null

# Configure firewall
log "Applying firewall rules..."
iptables -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

for p in "${PORTS_TCP[@]}"; do
    iptables -A INPUT -p tcp --dport $p -j ACCEPT
done
for p in "${PORTS_UDP[@]}"; do
    iptables -A INPUT -p udp --dport $p -j ACCEPT
done
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables-save > /etc/iptables/rules.v4

log "Firewall configured for scored services and RustDesk."

# Login banner and credentials
log "Setting login banner and default password..."
echo "Authorized Blue Team Bravo Use Only" > /etc/issue
echo "blueteam:DefaultPassword123!" | chpasswd || true

# Verify listening services
log "Verifying active scored service ports..."
ss -tuln | grep -E '(:21|:22|:25|:53|:80|:389|:445|:3306|:3390)' || \
    log "Some scored services are not listening. Check service status."

log "Setup complete. Firewall and configuration saved to $LOG_FILE."
