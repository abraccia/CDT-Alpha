#!/usr/bin/env python3
"""
Linux Log Forwarder (Python)
--------------------------------
Reads recent lines from key system logs and sends them
to a remote syslog server every minute.
Requires root privileges to access /var/log files.
"""

import os
import socket
import time
from datetime import datetime

# --- Configuration ---
SYSLOG_SERVER = "syslog.example.com"
SYSLOG_PORT = 514  # UDP
LOG_FILES = ["/var/log/syslog", "/var/log/auth.log", "/var/log/kern.log"]
LINES = 100  # lines per file to send
TAG = "linux-log-forwarder"
INTERVAL = 60  # seconds between sends

def send_syslog(message):
    """Send a message to the syslog server via UDP."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(message.encode("utf-8"), (SYSLOG_SERVER, SYSLOG_PORT))
    sock.close()

def tail(file_path, lines=50):
    """Return the last n lines of a file safely."""
    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            return f.readlines()[-lines:]
    except Exception as e:
        return [f"Error reading {file_path}: {e}\n"]

def main():
    hostname = os.uname().nodename
    while True:
        for log_file in LOG_FILES:
            for line in tail(log_file, LINES):
                timestamp = datetime.utcnow().isoformat()
                msg = f"<134>{TAG} [{hostname}] [{log_file}] {timestamp} {line.strip()}"
                send_syslog(msg)
        time.sleep(INTERVAL)

if __name__ == "__main__":
    main()
