#!/bin/bash

set -euo pipefail

TARGET_DIR="./scripts"
FILE_URL="https://raw.githubusercontent.com/abraccia/CDT-Alpha/blueteam/blueteam"

FILES=(
    linux/hardening/40.sh
    linux/hardening/cron40.sh
    linux/hardening/ssh40.sh
    linux/monitoring/service_monitor.sh
    linux/user_management/backup_user.sh
    linux/user_management/lock.sh
    linux/user_management/changepasswords.sh
    linux/user_management/uclean.sh
    linux/README.md
    logging_scripts/central_logging.sh
    logging_scripts/log_forwarding.sh
    logging_scripts/log_to_syslog_linux.py
    logging_scripts/splunk_setup.sh
    logging_scripts/README.txt
)

mkdir -p "$TARGET_DIR"

# Loop through each file and download it
for FILE in "${FILES[@]}"; do
  echo "[+] Downloading $FILE..."
  DEST_PATH="$TARGET_DIR/$FILE"
  DEST_DIR=$(dirname "$DEST_PATH")
  mkdir -p "$DEST_DIR"
  wget -q -O "$DEST_PATH" "$FILE_URL/$FILE"

  # Optional: check success
  if [[ $? -eq 0 ]]; then
    echo "    -> $FILE downloaded successfully."
  else
    echo "    -> Failed to download $FILE."
  fi
done

# Detect system type from IP
IP=$(hostname -I | awk '{print $1}')
echo "[+] Detected IP: $IP"

case $IP in
    "10.1.0.2")
        echo "[+] Configuring Email Server (SMTP)"
        ;;
    "10.1.0.3")
        echo "[+] Configuring SSH Server"
        ;;
    "10.1.0.4")
        echo "[+] Configuring MySQL Database"
        ;;
    "10.1.0.5")
        echo "[+] Configuring Web Server + Central Logging"
        ;;
    "10.1.0.6")
        echo "[+] Configuring FTP Server"
        ;;
    "10.1.0.11")
        echo "[+] Configuring DNS Server"
        ;;
    *)
        echo "[!] Unknown system type"
        ;;
esac

cd "$TARGET_DIR"
chmod +x linux/hardening/*.sh || true
chmod +x linux/user_management/*.sh || true
chmod +x linux/monitoring/*.sh || true
chmod +x logging_scripts/*.sh || true

# Common setup for all Linux systems
echo "[+] Running common Linux hardening..."
cd linux/hardening
./40.sh

echo "[+] Setting up user management..."
cd ../user_management
./uclean.sh greyteam,greyteam2,ansible,blueteam,root
./backup_user.sh
./changepasswords.sh

echo "[+] Setting up monitoring..."
cd ../monitoring
./service_monitor.sh &

echo "[+] Setting up central logging..."
cd ../../logging_scripts
if [ "$IP" != "10.1.0.5" ]; then
    ./log_forwarding.sh
else
    ./central_logging.sh
fi

echo "[=== PREPARATION COMPLETE ==="]
echo "[+] System hardened"
echo "[+] Backup users created"
echo "[+] Firewall configured"
echo "[+] Logging enabled"
echo "[+] Services secured"