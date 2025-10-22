#!/bin/bash

set -euo pipefail

echo "[+] Creating backup users for competition..."

# backup users, give less or more idrc
BACKUP_USERS=("maria" "jason" "olivia" "alex" "sophia")

# password generator
generate_password() {
    tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 16
}

# Create backup users
for user in "${BACKUP_USERS[@]}"; do
    if id "$user" &>/dev/null; then
        echo "[!] User $user already exists, skipping..."
    else
        password=$(generate_password)
        useradd -m -s /bin/bash -G sudo "$user"
        echo "$user:$password" | chpasswd
        echo "[+] Created user: $user with password: $password"
        echo "$user,$password" >> /root/backup_users_credentials.txt
    fi
done

# Secure the credentials file
chmod 600 /root/backup_users_credentials.txt
echo "[+] Backup user credentials saved to /root/backup_users_credentials.txt"

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