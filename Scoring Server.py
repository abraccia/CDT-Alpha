# Scoring Server


# Windows services ----------------------------------------

# AD → LDAP check on port 389
# RDP → Check that the RDP service is responding (port 3389)
# ICMP → Ping

# Linux services -------------------------------------------

# SSH → Verify actual handshake with SSH (not just port open)
# WordPress → HTTP check on port 80
# ICMP → Ping
# FTP → Try connecting to FTP server (port 21)
# SMTP → Try connecting to SMTP server (port 25)
# SQL → Try connecting to MySQL (port 3306)

# Scoring --------------------------------------------------

# Each service = 1 if up, 0 if down.
# Console prints a nice table with all machines and services.
# Table refreshes every minute, “redrawn” like a scoreboard.
# Runs as a loop (daemon-like) inside one script.


import os
import time
import socket
import subprocess
import requests
import mysql.connector
from prettytable import PrettyTable

# Placeholder IPs (replace W/L with actual last octet values later)
WINDOWS_IPS = [f"10.1.0.{i}" for i in range(1, 4)]  # Example: 3 Windows
LINUX_IPS = [f"10.1.0.{i}" for i in range(10, 17)]  # Example: 7 Linux

# Define services per host type
WINDOWS_SERVICES = {
    "Active Directory (LDAP)": ("ldap", 389),
    "RDP": ("tcp", 3389),
    "ICMP": ("icmp", None),
}

LINUX_SERVICES = {
    "SSH": ("ssh", 22),
    "WordPress": ("http", 80),
    "ICMP": ("icmp", None),
    "FTP": ("tcp", 21),
    "SMTP": ("tcp", 25),
    "SQL Database": ("mysql", 3306),
}

def check_icmp(ip):
    try:
        subprocess.check_output(["ping", "-c", "1", "-W", "1", ip], stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def check_port(ip, port):
    try:
        with socket.create_connection((ip, port), timeout=2):
            return True
    except:
        return False

def check_http(ip, port=80):
    try:
        r = requests.get(f"http://{ip}:{port}", timeout=3)
        return r.status_code == 200
    except:
        return False

def check_ssh(ip, port=22):
    try:
        sock = socket.create_connection((ip, port), timeout=3)
        banner = sock.recv(50).decode(errors="ignore")
        sock.close()
        return banner.startswith("SSH")
    except:
        return False

def check_mysql(ip, port=3306):
    try:
        # Attempt socket connect (no login)
        sock = socket.create_connection((ip, port), timeout=3)
        sock.close()
        return True
    except:
        return False

def check_ldap(ip, port=389):
    return check_port(ip, port)

def check_service(ip, service_type, port):
    if service_type == "icmp":
        return check_icmp(ip)
    elif service_type == "tcp":
        return check_port(ip, port)
    elif service_type == "http":
        return check_http(ip, port)
    elif service_type == "ssh":
        return check_ssh(ip, port)
    elif service_type == "mysql":
        return check_mysql(ip, port)
    elif service_type == "ldap":
        return check_ldap(ip, port)
    return False

def draw_table():
    table = PrettyTable()
    table.field_names = ["Host", "Service", "Status"]

    # Windows checks
    for ip in WINDOWS_IPS:
        for service, (stype, port) in WINDOWS_SERVICES.items():
            status = "UP" if check_service(ip, stype, port) else "DOWN"
            table.add_row([ip, service, status])

    # Linux checks
    for ip in LINUX_IPS:
        for service, (stype, port) in LINUX_SERVICES.items():
            status = "UP" if check_service(ip, stype, port) else "DOWN"
            table.add_row([ip, service, status])

    os.system("cls" if os.name == "nt" else "clear")
    print(table)

def main():
    while True:
        draw_table()
        time.sleep(60)

if __name__ == "__main__":
    main()


