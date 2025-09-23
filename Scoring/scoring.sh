#!/usr/bin/env bash

# Minimal probes for: ICMP, SSH, FTP, SMB, HTTP, HTTPS, WordPress, RDP, SMTP

T=3

icmp() { ping -c1 -W$T "$1" >/dev/null 2>&1; }
tcp()  { timeout $T bash -c ":</dev/tcp/$1/$2" >/dev/null 2>&1; }
http() { curl -sS --max-time $T -o /dev/null -w "%{http_code}" "http://$1/"    | grep -qE '^(2|3)'; }
https(){ curl -ksS --max-time $T -o /dev/null -w "%{http_code}" "https://$1/"  | grep -qE '^(2|3)'; }
wp()   { curl -sS -L --max-time $T "http://$1/wp-login.php" 2>/dev/null | grep -qiE 'wp-login|wordpress' \
      || curl -sS -L --max-time $T "http://$1/" 2>/dev/null | grep -qiE 'wp-|wordpress'; }

chk()  { if "$2" "$1" ${3:-}; then printf "%-16s %-10s %s\n" "$1" "$3$2" "UP"; else printf "%-16s %-10s %s\n" "$1" "$3$2" "DOWN"; fi; }

for h in "$@"; do
  echo "== $h =="
  chk "$h" icmp
  chk "$h" tcp    22     # SSH
  chk "$h" tcp    21     # FTP
  chk "$h" tcp    445    # SMB
  chk "$h" http           # HTTP
  chk "$h" https          # HTTPS
  if wp "$h"; then printf "%-16s %-10s %s\n" "$h" "wordpress" "UP"; else printf "%-16s %-10s %s\n" "$h" "wordpress" "DOWN"; fi
  chk "$h" tcp    3389   # RDP
  chk "$h" tcp    25     # SMTP
done
