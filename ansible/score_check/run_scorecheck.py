import ansible_runner
import json
from prettytable import PrettyTable
import time

SERVICE_STATUSES = {
    "icmp": "pending",   # ICMP check (ping)
    "icmp2": "pending",   # ICMP check (ping)
    "rdp": "pending",    # RDP for Windows
    "ssh": "pending",    # SSH for Linux
    "database": "pending",  # MySQL for Linux
    "blog": "pending",  # HTTP (WordPress) for Linux
    "ftp": "pending",    # FTP for Linux (even though it's commented out)
    "smtp": "pending",   # SMTP for Linux
    "smb": "pending",  # LDAP for Windows (Samba)
    "dc": "pending",
}

RED_TEAM_SCORE = 0
BLUE_TEAM_SCORE = 0
SCORE_INC = 10

def loop_one():
    global BLUE_TEAM_SCORE, RED_TEAM_SCORE

    runner = ansible_runner.run(
        private_data_dir='/home/greyteam/repos/CDT-Alpha/ansible', 
        playbook='/home/greyteam/repos/CDT-Alpha/ansible/score_check/score_check.yml',
        inventory='/home/greyteam/repos/CDT-Alpha/ansible/inventory.yml',
        json_mode=False, 
        quiet=False # disable/enable output
    )

    output = runner.stdout

    # grab last event as json
    for event in output:
        recap = event
    recap_json = json.loads(recap)

    ## debug
    #pretty_json = json.dumps(recap_json, indent=4)
    #print(pretty_json)

    failures = recap_json.get("event_data", {}).get("failures", {})
    ok = recap_json.get("event_data", {}).get("ok", {})
    for service in failures:
        if service in ok:
            del ok[service]

    # update service statuses
    for service in failures:
        SERVICE_STATUSES[service] = "DOWN"
    for service in ok:
        SERVICE_STATUSES[service] = "UP"

    # increment red/blue team scores based on service statuses
    for service, status, in SERVICE_STATUSES.items():
        if status == "UP":
            BLUE_TEAM_SCORE += SCORE_INC
        elif status == "DOWN":
            RED_TEAM_SCORE += SCORE_INC

def draw_table():
    table = PrettyTable()
    table.field_names = ["Service", "Status"]

    for service, status in SERVICE_STATUSES.items():
        table.add_row([service, status])

    table.add_row(["-", "-"])
    table.add_row(["BLUE_TEAM_SCORE", BLUE_TEAM_SCORE])
    table.add_row(["RED_TEAM_SCORE", RED_TEAM_SCORE])

    print(table)

def main():
    while True:
        loop_one()
        draw_table()
        #time.sleep(10)

if __name__ == '__main__':
    main()