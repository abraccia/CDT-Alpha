import os
import time
import socket
import subprocess
import requests
#import mysql.connector
from prettytable import PrettyTable
from datetime import datetime
# Placeholder IPs (replace W/L with actual last octet values later)
WINDOWS_IPS = [f"10.1.0.{i}" for i in range(17, 20)]  # Example: 3 Windows
LINUX_IPS = [f"10.1.0.{i}" for i in range(10, 17)]  # Example: 7 Linux
# Define services per host type
WINDOWS_SERVICES = [
    ("RDP", "tcp", 3389),
    ("Active Directory", "ldap", 389),
    ("Samba", "smb", 445),
]
LINUX_SERVICES = [
    ("WordPress", "http",  80),
    ("SQL Database", "mysql", 3306),
    ("ICMP", "icmp", None),
    ("SSH", "ssh", 22),
    ("SMTP", "smtp", 25),
    ("FTP", "tcp", 21),
    ("ICMP", "icmp", None),
]
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
        sock.close()
        return True
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
import socket
def check_smtp(ip, port=25):
    try:
        sock = socket.create_connection((ip, port), timeout=3)
        banner = sock.recv(1024).decode(errors="ignore")
        sock.close()
        # SMTP servers normally start with "220"
        return banner.startswith("220")
    except:
        return False
def check_smb(ip, port=445):
    """Check if SMB (Windows file sharing) is reachable on port 445."""
    try:
        with socket.create_connection((ip, port), timeout=3):
            return True
    except:
        return False
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
    elif service_type == "smtp":
        return check_smtp(ip, port)
    elif service_type == "smb":
        return check_smb(ip, port)  # <--- added SMB
    return False
def draw_table():
    table = PrettyTable()
    table.field_names = ["Host", "Service", "Status"]
    for ip, (service_name, stype, port) in zip(WINDOWS_IPS, WINDOWS_SERVICES):
        status = "UP" if check_service(ip, stype, port) else "DOWN"
        table.add_row([ip, service_name, status])
    for ip, (service_name, stype, port) in zip(LINUX_IPS, LINUX_SERVICES):
        status = "UP" if check_service(ip, stype, port) else "DOWN"
        table.add_row([ip, service_name, status])
    os.system("cls" if os.name == "nt" else "clear")
    print(table)
    print(datetime.now())
def main():
    while True:
        draw_table()
        time.sleep(60)
if __name__ == "__main__":
    main()
