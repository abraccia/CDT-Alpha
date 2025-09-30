import subprocess
import paramiko
import mysql.connector
import ftplib
import smtplib
import socket
import requests
from smbprotocol import *
from ldap3 import *
from collections import UserDict

class ImmutableKeysDict(UserDict):
    def __init__(self, initial_data=None):
        # Initialize the dictionary without triggering the __setitem__
        super().__init__()
        if initial_data:
            self.data.update(initial_data)  # Use update without triggering __setitem__

    def __setitem__(self, key, value):
        # Only allow setting a value if the key already exists
        if key not in self.data:
            raise KeyError(f"Cannot add new key: '{key}'")
        super().__setitem__(key, value)

    def __delitem__(self, key):
        # Optionally, prevent deletion of items
        raise KeyError("Cannot delete items from this dictionary")

# Initialize the dictionary with predefined keys
SERVICE_STATUSES = ImmutableKeysDict({
    "icmp": "pending",
    "icmp2": "pending",
    "rdp": "pending",
    "ssh": "pending",
    "database": "pending",
    "blog": "pending",
    "ftp": "pending",
    "smtp": "pending",
    "smb": "pending",
    "dc": "pending",
})

HOSTS = {
    "rdp": {"ansible_host": "10.1.0.17", "service_type": "rdp"},
    "dc": {"ansible_host": "10.1.0.18", "service_type": "dc"},
    "smb": {"ansible_host": "10.1.0.19", "service_type": "samba"},
    "wordpress": {"ansible_host": "10.1.0.10", "service_type": "wordpress"},
    "database": {"ansible_host": "10.1.0.11", "service_type": "mysql"},
    "icmp": {"ansible_host": "10.1.0.12", "service_type": "icmp"},
    "ssh": {"ansible_host": "10.1.0.13", "service_type": "ssh"},
    "smtp": {"ansible_host": "10.1.0.14", "service_type": "smtp"},
    "ftp": {"ansible_host": "10.1.0.15", "service_type": "ftp"},
    "icmp2": {"ansible_host": "10.1.0.16", "service_type": "icmp2"},
}

def check_icmp(host, key):
    """ Check ICMP (ping) functionality """
    response = subprocess.run(["ping", "-c", "1", host], stdout=subprocess.PIPE)
    if response.returncode == 0:
        SERVICE_STATUSES[key]= "UP"
    else:
        SERVICE_STATUSES[key] = "DOWN"

def check_rdp(host):
    """ Check RDP functionality """
    try:
        socket.create_connection((host, 3389), timeout=5)
        SERVICE_STATUSES["rdp"] = "UP"
    except socket.error:
        SERVICE_STATUSES["rdp"] = "DOWN"

def check_ssh(host, username, password):
    """ Check SSH login functionality """
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host, username=username, password=password, timeout=5)
        ssh.close()
        SERVICE_STATUSES["ssh"] = "UP"
    except paramiko.AuthenticationException:
        SERVICE_STATUSES["ssh"] = "authentication failed"
    except Exception:
        SERVICE_STATUSES["ssh"] = "DOWN"

def check_database(host, user, password, db_name):
    """ Check MySQL database connection and query """
    try:
        connection = mysql.connector.connect(host=host, user=user, password=password, database=db_name)
        cursor = connection.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        connection.close()
        SERVICE_STATUSES["database"] = "UP"
    except mysql.connector.Error:
        SERVICE_STATUSES["database"] = "DOWN"

def check_blog(host):
    """ Check HTTP/HTTPS (WordPress or any blog) functionality """
    try:
        response = requests.get(f"http://{host}", timeout=5)
        if response.status_code == 200:
            SERVICE_STATUSES["blog"] = "UP"
        else:
            SERVICE_STATUSES["blog"] = "DOWN"
    except requests.exceptions.RequestException:
        SERVICE_STATUSES["blog"] = "DOWN"

def check_ftp(host):
    """ Check FTP functionality by retrieving a file """
    try:
        ftp = ftplib.FTP(host, timeout=5)
        ftp.login()
        ftp.quit()
        SERVICE_STATUSES["ftp"] = "UP"
    except ftplib.all_errors:
        SERVICE_STATUSES["ftp"] = "DOWN"

def check_smtp(host):
    """ Check SMTP functionality """
    try:
        server = smtplib.SMTP(host, 25, timeout=5)
        server.quit()
        SERVICE_STATUSES["smtp"] = "UP"
    except (smtplib.SMTPException, socket.error):
        SERVICE_STATUSES["smtp"] = "DOWN"

def check_smb(host):
    """ Check SMB functionality """
    try:
        smb_conn = SMBConnection('', '', '', host)
        smb_conn.connect(host, 139)
        SERVICE_STATUSES["smb"] = "UP"
    except SMBAuthenticationError:
        SERVICE_STATUSES["smb"] = "authentication failed"
    except Exception:
        SERVICE_STATUSES["smb"] = "DOWN"

def check_dc(host, username, password):
    """ Check Domain Controller (LDAP) functionality """
    try:
        server = Server(host, get_info=ALL)
        conn = Connection(server, user=username, password=password, auto_bind=True)
        if conn.bound:
            SERVICE_STATUSES["dc"] = "UP"
        else:
            SERVICE_STATUSES["dc"] = "DOWN"
    except Exception:
        SERVICE_STATUSES["dc"] = "DOWN"

def main():
    # Replace these with actual credentials and hostnames
    ssh_username = "virgil"
    ssh_password = "ArmaVirumqueCano"
    db_user = "wordpress"
    db_password = "ChangeMe123!"
    db_name = "wpdb"
    ldap_username = "cn=Administrator,dc=troy.cdtalpha.com"
    ldap_password = "Password123!"

    for service_name, service_info in HOSTS.items():
        ip = service_info["ansible_host"]
        service_type = service_info["service_type"]

        if service_type == "icmp" or service_type == "icmp2":
            check_icmp(ip, service_type)
        elif service_type == "rdp":
            check_rdp(ip)
        elif service_type == "ssh":
            check_ssh(ip, ssh_username, ssh_password)
        elif service_type == "mysql":
            check_database(ip, db_user, db_password, db_name)
        elif service_type == "wordpress":
            check_blog(ip)
        elif service_type == "ftp":
            check_ftp(ip)
        elif service_type == "smtp":
            check_smtp(ip)
        elif service_type == "samba":
            #check_smb(ip)
            pass
        elif service_type == "dc":
            check_dc(ip, ldap_username, ldap_password)
        
    # Print the service statuses
    print("Service Statuses:")
    for service, status in SERVICE_STATUSES.items():
        print(f"{service}: {status}") 

if __name__ == "__main__":
    main()
