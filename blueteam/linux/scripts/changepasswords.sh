#!/bin/bash
for i in blueteam john.hammond henry.wu robert.muldoon john.arnold
do
  PASS=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 31)
  echo "Changing password for $i"
  echo "$i,$PASS" >>  userlist.txt
  echo -e "$PASS\n$PASS" | passwd $i
done

# If a group called 'blueteam' exists, make userlist.txt owned by that group
# and readable only by owner and group (0640).
if getent group blueteam >/dev/null 2>&1; then
  chgrp blueteam userlist.txt
  chmod 0640 userlist.txt
  echo "userlist.txt: group set to 'blueteam' and permissions set to 0640"
else
  echo "Group 'blueteam' not found; leaving userlist.txt permissions unchanged"
fi
