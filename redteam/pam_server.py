#!/bin/python3
import socket
from datetime import datetime

BIND_ADDR = "0.0.0.0" #change to appropriate listen IP for competition
BIND_PORT = 30059
LOG_FILE = 'passwd.log'

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((BIND_ADDR, BIND_PORT))
    s.listen()
    print('{:>20}|{:>20}|{:>20}|{:>20}'.format("Host", "User", "Password", "Action"))
    
    while True:
        try:
            conn, addr = s.accept()
            with conn:
                data = conn.recv(1024)
                data = data.decode().split()
                if len(data) < 3:
                    continue
                print('{:>20}|{:>20}|{:>20}|{:>20}|{:>20}'.format(addr[0], data[0], data[1], data[2],str(datetime.now())))
                with open(LOG_FILE, "at") as log:
                    log.write('{:>20}|{:>20}|{:>20}|{:>20}|{:>20}\n'.format(addr[0], data[0], data[1], data[2],str(datetime.now())))
        except KeyboardInterrupt:    
            s.shutdown(socket.SHUT_RDWR)
            s.close()
            exit()
