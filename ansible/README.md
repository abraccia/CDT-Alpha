# Test connectivity
ansible all -m ping

# Run competition
ansible-playbook setup_competition.yml

# Run specific components (examples)
ansible-playbook playbook.yml --tags linux
ansible-playbook playbook.yml --tags windows
ansible-playbook playbook.yml --tags mysql,wordpress