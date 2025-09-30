#!/usr/bin/env python3
# Scoring Server — per-check + per-round logging, silent totals

import os, time, socket, subprocess, requests, csv
from datetime import datetime
from prettytable import PrettyTable

# ---------- Targets (edit these) ----------
WINDOWS_IPS = [f"10.1.0.{i}" for i in range(17, 20)]  # example: 3 Windows
LINUX_IPS   = [f"10.1.0.{i}" for i in range(10, 17)]  # example: 7 Linux

# One IP is paired with one service (zip). Add/remove as needed.
WINDOWS_SERVICES = [
    ("RDP",              "tcp",   3389),
    ("Active Directory", "ldap",   389),
    ("Samba",            "smb",    445),
]

LINUX_SERVICES = [
    ("WordPress",        "http",    80),
    ("SQL Database",     "mysql",  3306),
    ("ICMP",             "icmp",   None),
    ("SSH",              "ssh",      22),
    ("SMTP",             "smtp",     25),
    ("FTP",              "tcp",      21),
    ("ICMP",             "icmp",   None),
]

REFRESH_SEC = 60
DETAIL_LOG  = "scoring_log.csv"      # per-check rows
ROUND_LOG   = "scoring_rounds.csv"   # per-round + cumulative totals

# ---------- Service checks ----------
def check_icmp(ip):
    try:
        subprocess.check_output(["ping", "-c", "1", "-W", "1", ip],
                                stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def check_port(ip, port):
    try:
        with socket.create_connection((ip, port), timeout=2):
            return True
    except Exception:
        return False

def check_http(ip, port=80):
    try:
        r = requests.get(f"http://{ip}:{port}", timeout=3)
        return r.status_code == 200
    except Exception:
        return False

def check_ssh(ip, port=22):
    try:
        s = socket.create_connection((ip, port), timeout=3)
        s.close()
        return True
    except Exception:
        return False

def check_mysql(ip, port=3306):
    try:
        s = socket.create_connection((ip, port), timeout=3)
        s.close()
        return True
    except Exception:
        return False

def check_ldap(ip, port=389):
    return check_port(ip, port)

def check_smtp(ip, port=25):
    try:
        s = socket.create_connection((ip, port), timeout=3)
        banner = s.recv(1024).decode(errors="ignore")
        s.close()
        return banner.startswith("220")  # SMTP banner usually starts with 220
    except Exception:
        return False

def check_smb(ip, port=445):
    """SMB reachability on 445 (Windows file sharing)."""
    return check_port(ip, port)

DISPATCH = {
    "icmp":  check_icmp,
    "tcp":   check_port,
    "http":  check_http,
    "ssh":   check_ssh,
    "mysql": check_mysql,
    "ldap":  check_ldap,
    "smtp":  check_smtp,
    "smb":   check_smb,
}

# ---------- Logging ----------
def ensure_logs():
    if not os.path.exists(DETAIL_LOG):
        with open(DETAIL_LOG, "w", newline="") as f:
            csv.writer(f).writerow(
                ["timestamp","host","service","status","red_score","blue_score"]
            )
    if not os.path.exists(ROUND_LOG):
        with open(ROUND_LOG, "w", newline="") as f:
            csv.writer(f).writerow(
                ["timestamp","red_round","blue_round","red_overall","blue_overall","checks"]
            )

def log_detail(ts, host, service, status, red_score, blue_score):
    with open(DETAIL_LOG, "a", newline="") as f:
        csv.writer(f).writerow([ts, host, service, status, red_score, blue_score])

def log_round(ts, red_round, blue_round, red_overall, blue_overall, checks):
    with open(ROUND_LOG, "a", newline="") as f:
        csv.writer(f).writerow([ts, red_round, blue_round, red_overall, blue_overall, checks])

# ---------- Scoring ----------
def score_from_status(ok: bool):
    # UP -> Blue +10; DOWN -> Red +10
    return (0, 10) if ok else (10, 0)

# Running totals (logged only, not printed)
RED_OVERALL  = 0
BLUE_OVERALL = 0

# ---------- Display/loop ----------
def draw_and_log():
    global RED_OVERALL, BLUE_OVERALL

    now = datetime.utcnow().isoformat(timespec="seconds") + "Z"
    table = PrettyTable(["Host", "Service", "Status"])

    red_round = 0
    blue_round = 0
    checks = 0

    def do_row(ip, name, stype, port):
        nonlocal red_round, blue_round, checks
        ok = DISPATCH[stype](ip, port) if stype != "icmp" else DISPATCH[stype](ip)
        status = "UP" if ok else "DOWN"
        red, blue = score_from_status(ok)
        red_round += red
        blue_round += blue
        checks += 1
        table.add_row([ip, name, status])
        log_detail(now, ip, name, status, red, blue)

    # Windows
    for ip, (name, stype, port) in zip(WINDOWS_IPS, WINDOWS_SERVICES):
        do_row(ip, name, stype, port)
    # Linux
    for ip, (name, stype, port) in zip(LINUX_IPS, LINUX_SERVICES):
        do_row(ip, name, stype, port)

    # backend totals only
    RED_OVERALL  += red_round
    BLUE_OVERALL += blue_round
    log_round(now, red_round, blue_round, RED_OVERALL, BLUE_OVERALL, checks)

    # terminal output (no totals)
    os.system("cls" if os.name == "nt" else "clear")
    print(f"Scoring Run: {now}\n")
    print(table)

def main():
    ensure_logs()
    while True:
        draw_and_log()
        time.sleep(REFRESH_SEC)

if __name__ == "__main__":
    main()
