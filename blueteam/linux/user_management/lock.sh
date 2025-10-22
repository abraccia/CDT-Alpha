#!/bin/bash

# Allowed usernames CHECK WHAT USERS EXIST FIRST!!
allowed_users=("blueteam" "root" "greyteam" "ansible" "greyteam2")

# Get all local users with UID ≥ 1000 (typically real people, not system users)
users_to_check=$(awk -F: '$3 >= 1000 { print $1 }' /etc/passwd)

for user in $users_to_check; do
    if [[ ! " ${allowed_users[@]} " =~ " ${user} " ]]; then
        echo "[!] Disabling user: $user"
        usermod --lock "$user"
        usermod --expiredate 1 "$user"
        usermod -s /usr/sbin/nologin "$user"
    else
        echo "[+] Keeping user: $user"
    fi
done
