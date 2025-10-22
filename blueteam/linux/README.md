# Directory for Linux scripts and tools

## Hardening
[40.sh](hardening/40.sh) is the five-minute plan script basically.

[cron40.sh](hardening/cron40.sh) displays **ALL** cronjobs for each user, so be sure to only run at your own risk

[ssh40.sh](hardening/ssh40.sh) is the ssh hardening to reduce backdoors and whatnot. Be sure to edit the allowed users!

## Monitoring

[service_monitor.sh](monitoring/service_monitor.sh) is a script that, after run, logs the pertinent service info to "/var/log/blue_team/service_monitor.log". refreshes every 3 mins. Note that the 40.sh script also creates log files.

## User Management

[backup_user.sh](user_management/backup_user.sh) creates five users that have randomly generated passwords. These are saved at "/root/backup_users_credentials.txt". Be sure to delete, move, or edit this file after running!

[changepasswords.sh](user_management/changepasswords.sh) changes all the passwords randomly. The creds are saved in whatever file the `setup.sh` file was ran probably.

[lock.sh](user_management/lock.sh) locks the accounts that arent whitelisted. Be sure you know what you are doing and who you are locking out! if you accidentally lock out a service account or a scoring account, know why it happened!

## Steps for Each

### SMTP (10.1.0.2)
a little over the top but
```bash
# Create systemd drop-in to be strict about restart
sudo mkdir -p /etc/systemd/system/postfix.service.d
cat <<'EOF' | sudo tee /etc/systemd/system/postfix.service.d/override.conf
[Service]
Restart=always
RestartSec=5
StartLimitBurst=0

# Restrict file system except the queue dir (won't stop reads)
ProtectSystem=full
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
ReadWritePaths=/var/spool/postfix /var/log/mail
EOF

sudo systemctl daemon-reload
sudo systemctl restart postfix

# use apt-mark to hold the postfix package so it cannot be trivially upgraded/removed by apt scripts
sudo apt-mark hold postfix

# Backup then lock
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.bak
sudo cp /etc/postfix/master.cf /etc/postfix/master.cf.bak

# Set proper ownership & perms
sudo chown root:root /etc/postfix/main.cf /etc/postfix/master.cf
sudo chmod 644 /etc/postfix/main.cf /etc/postfix/master.cf

# Set immutable bit
sudo chattr +i /etc/postfix/main.cf /etc/postfix/master.cf

# Verify
lsattr /etc/postfix/main.cf /etc/postfix/master.cf
# look for 'i' attribute

# Undo
sudo chattr -i /etc/postfix/main.cf /etc/postfix/master.cf
# edit files, then re-apply chattr +i
```

maybe a rsyslog rule in `/etc/rsyslog.d/90-remote.conf`
```conf
*.* @@logs.example.com:10514;RSYSLOG_SyslogProtocol23Format
```

### SSH (10.1.0.3) but also any server

Make sure people can authenticate with a password, so `PasswordAuthentication yes` has to always be in the ssh config, and whatever user they are sshing in with should be in the `AllowedUsers` list. If you want to ensure that only that specific command runs,
```bash
# Global hardening
PermitRootLogin no
PasswordAuthentication yes   # required for scoring if you must use password
ChallengeResponseAuthentication no
UsePAM yes
AllowTcpForwarding no
X11Forwarding no

# Lock scoring user to single command
Match User scoreuser
    PasswordAuthentication yes
    PermitTTY yes
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
    PermitTunnel no
    ForceCommand /usr/local/bin/ssh-score-wrapper
```
but that might be too much work idk.
You can also create a systemd thing again
`/etc/systemd/system/ssh.service.d/override.conf`
```conf
[Service]
Restart=always
RestartSec=5
ProtectSystem=full
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ReadWritePaths=/var/log/blue_team
```
Then
```bash
sudo systemctl daemon-reload
sudo systemctl restart ssh
```
Once again:
```bash
sudo cp /etc/ssh/sshd_config /root/sshd_config.bak
# Might break, maybe keep it under the ssh user and group
sudo chown root:root /etc/ssh/sshd_config
sudo chmod 600 /etc/ssh/sshd_config
sudo chattr +i /etc/ssh/sshd_config
```

rsyslog `/etc/rsyslog.d/90-remote.conf`
```conf
*.* @@logs.example.com:10514
```

### MySQL (10.1.0.4)
Just protect the configs again i guess
```bash
# Set correct permissions
sudo chown root:root /etc/mysql/my.cnf
sudo chmod 644 /etc/mysql/my.cnf
sudo chattr +i /etc/mysql/my.cnf
```
and enable logging in `/etc/mysql/my.cnf` or `/etc/mysql/mysql.conf.d/mysqld.cnf`
```conf
[mysqld]
general_log = 1
general_log_file = /var/log/mysql/mysql.log
log_error = /var/log/mysql/error.log
```
Disable root login remotely
```sql
DELETE FROM mysql.user WHERE User='root' AND Host!='localhost';
FLUSH PRIVILEGES;
```
Restart
```bash
sudo systemctl restart mysql
```

### HTTP (10.1.0.5)
`/etc/nginx/nginx.conf`
```conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```
Depending on the file
```bash
# checked page
sudo chown root:root /var/www/html/index.html
sudo chmod 444 /var/www/html/index.html
sudo chattr +i /var/www/html/index.html
# config
sudo chown -R root:root /etc/nginx/
sudo chmod -R go-w /etc/nginx/
sudo chattr -R +i /etc/nginx/nginx.conf /etc/nginx/sites-enabled/
# lock binary
sudo apt-mark hold nginx
sudo chattr +i /usr/sbin/nginx
# logs append only
sudo chattr +a /var/log/nginx/access.log
sudo chattr +a /var/log/nginx/error.log
# look for webshell
find /var/www/html -name '*.php' -not -name 'index.php' -exec ls -l {} \;

```
rsyslog `/etc/rsyslog.d/90-remote.conf`
```conf
:programname, isequal, "nginx" @@10.1.0.5:10514
```



### DNS
```bash
sudo cp /etc/bind/db.example.com /etc/bind/db.example.com.bak   # backup
sudo nano /etc/bind/db.example.com
sudo named-checkzone example.com /etc/bind/db.example.com
sudo systemctl reload bind9
# ensure ownership/permissions are sensible
sudo chown root:bind /etc/bind/db.example.com
sudo chmod 644 /etc/bind/db.example.com

# make file immutable
sudo chattr +i /etc/bind/db.example.com

# verify
lsattr /etc/bind/db.example.com
# you'll see an 'i' attribute, e.g.: ----i--------e- /etc/bind/db.example.com
```