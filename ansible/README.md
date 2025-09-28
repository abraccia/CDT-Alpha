# Test connectivity
ansible all -m ping

# Run competition
ansible-playbook comp_up.yml

# Run specific components (examples)
ansible-playbook playbook.yml --tags linux
ansible-playbook playbook.yml --tags windows
ansible-playbook playbook.yml --tags mysql,wordpress


# TROUBLESHOOTING

## Runtime errors

### Windows

#### couldn't resolve module/action 'ansible.windows.win_firewall_rule'. This often indicates a misspelling, missing collection, or incorrect module path.
```bash
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install ansible.posix
```
answer found [here](https://github.com/ansible-collections/ansible.windows/issues/282) and [here](https://stackoverflow.com/questions/66335800/error-couldnt-resolve-module-action-this-often-indicates-a-misspelling-miss)

NVM just look at [ansible documentation](https://docs.ansible.com/ansible/latest/collections/community/windows/win_firewall_rule_module.html)