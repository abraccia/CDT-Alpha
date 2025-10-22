#!/bin/bash

set -euo pipefail

LOG_FILE="/var/log/blue_team/service_monitor.log"

# Create log directory if it doesn't exist
mkdir -p /var/log/blue_team

# Detect host IP
HOST_IP=$(hostname -I | awk '{print $1}')

# Determine services to monitor based on IP
declare -a SERVICES=()

case "$HOST_IP" in
  "10.1.0.2")
    echo "[+] Email Server detected (SMTP)"
    SERVICES=("postfix" "ssh")
    ;;
  "10.1.0.3")
    echo "[+] SSH Server detected"
    SERVICES=("ssh")
    ;;
  "10.1.0.4")
    echo "[+] MySQL Database Server detected"
    SERVICES=("mysql" "ssh")
    ;;
  "10.1.0.5")
    echo "[+] Web Server detected (nginx)"
    SERVICES=("nginx" "ssh")
    ;;
  "10.1.0.6")
    echo "[+] FTP Server detected"
    SERVICES=("vsftpd" "ssh")
    ;;
  "10.1.0.11")
    echo "[+] DNS Server detected"
    SERVICES=("bind9" "ssh")
    ;;
  *)
    echo "[!] Unknown host IP: $HOST_IP. Defaulting to SSH monitoring only."
    SERVICES=("ssh")
    ;;
esac

# Service monitor function
monitor_services() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "=== Service Status Check - $timestamp ===" >> "$LOG_FILE"

    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo "$service: RUNNING" >> "$LOG_FILE"
        else
            echo "$service: STOPPED" >> "$LOG_FILE"

            # Attempt restart for critical services
            case "$service" in
              ssh|mysql|postfix|bind9|nginx)
                systemctl start "$service" && echo "   [+] Restarted $service" >> "$LOG_FILE"
                ;;
            esac
        fi
    done

    # Optional: Log open network ports relevant to services
    echo "--- Network Connections ---" >> "$LOG_FILE"
    netstat -tunlp | grep -E ":(22|25|53|80|21|3306)" >> "$LOG_FILE" || echo "No matching ports open." >> "$LOG_FILE"

    echo "" >> "$LOG_FILE"
}

while true; do
    monitor_services
    sleep 180
done
