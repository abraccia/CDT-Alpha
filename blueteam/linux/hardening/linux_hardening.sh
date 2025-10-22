#!/usr/bin/env bash
# bravo-firewall.sh — Allow only scored ports (plus RustDesk 21114–21119)
# No changes to users, banners, or services. IPv4 + IPv6 support.

set -euo pipefail

# Allowed ports (Blue Team packet + RustDesk)
TCP_PORTS=(21 22 25 53 80 389 445 3306 3390)
RUSTDESK_RANGE_START=21114
RUSTDESK_RANGE_END=21119
UDP_PORTS=(53)

# Ensure nftables exists
if ! command -v nft >/dev/null 2>&1; then
  apt-get update -y >/dev/null
  apt-get install -y nftables >/dev/null
fi

# Format port lists for nft
join_comma() { local IFS=,; echo "$*"; }
tcp_list=$(join_comma "${TCP_PORTS[@]}")
udp_list=$(join_comma "${UDP_PORTS[@]}")

cat > /etc/nftables.conf <<EOF
#!/usr/sbin/nft -f
flush ruleset

table inet bravo {
  set tcp_allowed {
    type inet_service;
    elements = { ${tcp_list} }
  }

  set udp_allowed {
    type inet_service;
    elements = { ${udp_list} }
  }

  chain input {
    type filter hook input priority 0; policy drop;

    # loopback
    iif "lo" accept

    # established connections
    ct state established,related accept

    # ICMP / ICMPv6 basics
    ip protocol icmp icmp type { echo-request, echo-reply, destination-unreachable, time-exceeded } accept
    ip6 nexthdr icmpv6 icmpv6 type { echo-request, echo-reply, nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit, nd-router-advert, pkt-too-big, time-exceeded, param-problem } accept

    # allowed TCP/UDP
    tcp dport @tcp_allowed accept
    tcp dport ${RUSTDESK_RANGE_START}-${RUSTDESK_RANGE_END} accept
    udp dport @udp_allowed accept
  }

  chain forward { type filter hook forward priority 0; policy drop; }
  chain output  { type filter hook output  priority 0; policy accept; }
}
EOF

# enable and load
systemctl enable --now nftables >/dev/null
nft -f /etc/nftables.conf

echo "[BRAVO] Firewall active — only scored ports and RustDesk 21114–21119 open inbound."
echo "Check with: nft list ruleset"
