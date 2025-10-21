"""
Windows Log Forwarder (Python)
--------------------------------
Reads recent Windows Event Logs and sends entries to a remote syslog server.
Requires Administrator privileges.
"""

import socket
import time
from datetime import datetime
import win32evtlog  # from pywin32
import platform

# --- Configuration ---
SYSLOG_SERVER = "syslog.example.com"
SYSLOG_PORT = 514  # UDP
LOGS = ["System", "Application", "Security"]
EVENTS_PER_LOG = 50
TAG = "win-log-forwarder"
INTERVAL = 60  # seconds

def send_syslog(message):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(message.encode("utf-8"), (SYSLOG_SERVER, SYSLOG_PORT))
    sock.close()

def read_event_logs(log_name, count=50):
    """Retrieve the most recent events from a Windows log."""
    try:
        server = "localhost"
        handle = win32evtlog.OpenEventLog(server, log_name)
        flags = win32evtlog.EVENTLOG_BACKWARDS_READ | win32evtlog.EVENTLOG_SEQUENTIAL_READ
        events = win32evtlog.ReadEventLog(handle, flags, 0)
        results = []
        for event in (events or [])[:count]:
            time_str = event.TimeGenerated.Format()
            msg = f"EventID={event.EventID}, Source={event.SourceName}, Time={time_str}"
            results.append(msg)
        win32evtlog.CloseEventLog(handle)
        return results
    except Exception as e:
        return [f"Error reading {log_name}: {e}"]

def main():
    hostname = platform.node()
    while True:
        for log_name in LOGS:
            for entry in read_event_logs(log_name, EVENTS_PER_LOG):
                timestamp = datetime.utcnow().isoformat()
                msg = f"<134>{TAG} [{hostname}] [{log_name}] {timestamp} {entry}"
                send_syslog(msg)
        time.sleep(INTERVAL)

if __name__ == "__main__":
    main()