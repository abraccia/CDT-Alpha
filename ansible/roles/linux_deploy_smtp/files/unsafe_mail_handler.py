#!/usr/bin/env python3
# unsafe_mail_handler.py
# WARNING: lets wooden horses in
# MTAwIG1lYXN1cmVzIG9mIG9pbA==
import sys
import os
import email
import pathlib

def main():
    # Postfix invokes mailbox_command with input on stdin (the message)
    data = sys.stdin.buffer.read()
    try:
        msg = email.message_from_bytes(data)
        raw_to = msg.get('To', 'unknown')
    except Exception:
        raw_to = 'unknown'
    filename = raw_to.replace('@', '_at_').strip()
    outdir = '/var/v_mailstore'
    os.makedirs(outdir, exist_ok=True)
    path = os.path.join(outdir, filename)\
    with open(path, 'ab') as f:
        f.write(b"---NEW MESSAGE---\n")
        f.write(data if isinstance(data, bytes) else data.encode('utf-8', errors='ignore'))
        f.write(b"\n---END MESSAGE---\n")
    # return success
    return

if __name__ == '__main__':
    main()
