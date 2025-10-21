Installation & Setup

Linux:

    1. Save as /usr/local/bin/log_to_syslog_linux.py

    2. Make executable:
        chmod +x /usr/local/bin/log_to_syslog_linux.py

    3. Run manually to test:
        sudo /usr/local/bin/log_to_syslog_linux.py

    4. Schedule via cron or systemd:
        @reboot /usr/local/bin/log_to_syslog_linux.py &

Windows:

    1. Install Python 3 and pywin32:
        pip install pywin32


    2. Save as C:\Scripts\log_to_syslog_win.py

    3. Test manually:
        python C:\Scripts\log_to_syslog_win.py

    4. Add a Scheduled Task:
        Trigger: every 1 minute

        Action:
            python "C:\Scripts\log_to_syslog_win.py" or whatever the path is at the time

        Run with highest privileges

Rsyslog:

    1. On the web server:
        sudo apt install rsyslog
        sudo systemctl enable rsyslog
        sudo systemctl start rsyslog
    
    2. Then edit /etc/rsyslog.conf or /etc/rsyslog.d/remote.conf and add:
        # Listen for UDP syslog
        $ModLoad imudp
        $UDPServerRun 514
    
    3. Then restart rsyslog
        sudo systemctl restart rsyslog
    
    All logs will appear in /var/log/syslog and /var/log/messages
    Filter them easily with "grep crosslog-forwarder /var/log/syslog"