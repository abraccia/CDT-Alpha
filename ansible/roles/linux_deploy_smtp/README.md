Overview
This project contains a very basic Ansible configuration to deploy and manage an SMTP service (Postfix) on a Linux host.
It demonstrates three key Ansible features:

1. Package installation (apt) – installs Postfix.
2. File configuration (copy) – ensures /etc/mailname is present with a defined domain.
3. Service management (service) – makes sure Postfix is running and enabled on boot.

Files
- smtp.yml → The Ansible playbook with 3 features.
- hosts.ini → The inventory file containing the target host(s).

Requirements
- Ubuntu/Debian-based target system.
- Python installed on the target (default on most Linux distros).
- SSH access with key or password.
- Ansible installed on the control machine (sudo apt install ansible).
