#!/bin/bash

set -euo pipefail
trap 'echo "[!] ERROR: Script failed at line $LINENO with exit code $?." >&2' ERR

echo "[+] Creating backup users for competition..."

# backup users, give less or more idrc
BACKUP_USERS=("bob" "alice")

# Create backup users
for user in "${BACKUP_USERS[@]}"; do
    if id "$user" &>/dev/null; then
        echo "[!] User $user already exists, skipping..."
    else
        password=$(head -c 256 /dev/urandom | tr -dc A-Za-z0-9 | head -c 10)
        useradd -m -s /bin/bash -G sudo "$user"
        echo "$user:$password" | chpasswd
        echo "[+] Created user: $user with password: $password"
        echo "$user,$password" >> /root/backup_userlist.txt
    fi
done

# Secure the credentials file
chmod 600 /root/backup_userlist.txt
echo "[+] Backup user credentials saved to /root/backup_userlist.txt"

# Add to allowed SSH users if SSH is configured
SSHD_CONFIG="/etc/ssh/sshd_config"
if grep -q "AllowUsers" "$SSHD_CONFIG"; then
    current_users=$(grep "AllowUsers" "$SSHD_CONFIG" | cut -d' ' -f2-)
    for user in "${BACKUP_USERS[@]}"; do
        if [[ ! " $current_users " =~ " $user " ]]; then
            sed -i "s/AllowUsers.*/& $user/" "$SSHD_CONFIG"
        fi
    done
    systemctl reload ssh
fi

echo "[+] Backup user creation complete!"