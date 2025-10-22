# Directory for Linux scripts and tools

## Hardening
[40.sh](hardening/40.sh) is the five-minute plan script basically.

[cron40.sh](hardening/cron40.sh) displays **ALL** cronjobs for each user, so be sure to only run at your own risk

[ssh40.sh](hardening/ssh40.sh) is the ssh hardening to reduce backdoors and whatnot. Be sure to edit the allowed users!

## Monitoring

[service_monitor.sh](monitoring/service_monitor.sh) is a script that, after run, logs the pertinent service info to "/var/log/blue_team/service_monitor.log". refreshes every 3 mins. Note that the 40.sh script also creates log files.

## User Management

[backup_user.sh](user_management/backup_user.sh) creates five users that have randomly generated passwords. These are saved at "/root/backup_users_credentials.txt". Be sure to delete, move, or edit this file after running!

[changepasswords.sh](user_management/changepasswords.sh) changes all the passwords randomly. The creds are saved in whatever file the `setup.sh` file was ran probably.

[lock.sh](user_management/lock.sh) locks the accounts that arent whitelisted. Be sure you know what you are doing and who you are locking out! if you accidentally lock out a service account or a scoring account, know why it happened!