#!/bin/bash
for i in blueteam john.hammond henry.wu robert.muldoon john.arnold
do
  PASS=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 10)
  echo "Changing password for $i"
  echo "$i,$PASS" >>  /root/userlist.txt
  echo -e "$PASS\n$PASS" | passwd $i
done

chmod 600 /root/userlist
echo "[+] User credentials saved to /root/userlist.txt"