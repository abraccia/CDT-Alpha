#!/usr/bin/env bash
# Minimal concurrent scoring (ICMP + TCP) in Bash.

set -euo pipefail

# ---- CONFIG -------------------------------------------------
HOSTS=(10.1.0.1 10.1.0.2 10.1.0.3 10.1.0.10 10.1.0.11 10.1.0.12)

# SERVICES items: "Label:Type:Port" where Type is icmp|tcp; Port is ignored for icmp
SERVICES=(
  "ICMP:icmp:-"
  "SSH:tcp:22"
  "HTTP:tcp:80"
  "FTP:tcp:21"
  "SMTP:tcp:25"
  "LDAP:tcp:389"
  "RDP:tcp:3389"
  "MySQL:tcp:3306"
)

INTERVAL=60          # seconds between refreshes
TCP_TIMEOUT=2        # seconds for TCP connect
MAX_JOBS=32          # throttle concurrency

# ---- FUNCS --------------------------------------------------
check_icmp() {
  local ip="$1"
  # Linux/macOS: -c 1 one echo; -W 1 one-second deadline (ms on macOS BSD ping uses -W timeout in ms; this still works as short)
  ping -c 1 -W 1 "$ip" >/dev/null 2>&1
}

check_tcp() {
  local ip="$1" port="$2"
  # Use bash /dev/tcp with a timeout wrapper
  timeout "${TCP_TIMEOUT}" bash -c "exec 3<>/dev/tcp/${ip}/${port}" >/dev/null 2>&1
}

# Throttle background jobs
wait_for_slot() {
  local current
  while :; do
    current=$(jobs -r | wc -l | tr -d ' ')
    [[ "$current" -lt "$MAX_JOBS" ]] && break
    sleep 0.05
  done
}

draw_table() {
  local file="$1"
  # Sort by IP then Service for stable display
  sort -t$'\t' -k1,1V -k2,2 "$file" | awk -F'\t' '
    BEGIN{
      hostW=15; svcW=10; stW=6;
      sep=sprintf("%" (hostW+svcW+stW+4) "s",""); gsub(/ /,"-",sep);
      printf "%s\n%-"hostW"s  %- "svcW"s  %- "stW "s\n%s\n", sep, "Host", "Service", "Status", sep;
    }
    { printf "%-"hostW"s  %- "svcW "s  %- "stW "s\n", $1, $2, $3 }
    END{ print sep }
  '
}

# ---- MAIN LOOP ----------------------------------------------
while true; do
  tmp="$(mktemp)"
  # launch checks
  for ip in "${HOSTS[@]}"; do
    for item in "${SERVICES[@]}"; do
      IFS=':' read -r label type port <<<"$item"
      wait_for_slot
      {
        if [[ "$type" == "icmp" ]]; then
          if check_icmp "$ip"; then status="UP"; else status="DOWN"; fi
        else
          if check_tcp "$ip" "$port"; then status="UP"; else status="DOWN"; fi
        fi
        printf "%s\t%s\t%s\n" "$ip" "$label" "$status"
      } &
    done
  done
  wait

  # Clear and render
  printf "\033[2J\033[H"
  draw_table "$tmp"
  rm -f "$tmp"

  sleep "$INTERVAL"
done
