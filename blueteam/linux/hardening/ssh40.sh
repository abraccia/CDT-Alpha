#!/bin/bash

if [[ -z "$SUDO_USER" ]]; then
  echo "This script must be run with sudo"
  exit
fi

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

# # Ask if the user wants to restart the SSH service
# read -p "Do you want to restart the SSH service? (y/n): " response

# # Verify the response
# if [[ $response == "y" ]]; then
#     # Restart the sshd service
#     sudo service ssh restart
# else
#     echo "Operation cancelled."
# fi

# Show the current configuration of sshd
# echo "sudo sshd -T"
# sudo sshd -T
