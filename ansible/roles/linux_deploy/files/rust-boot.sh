#!/bin/bash

# Wait for network (optional)
sleep 15

rustdesk_pw=$(pwgen -1 -A -0 -B)
rustdesk_config="9JSP4MlQRJmNrgVd1hmM4M1c1JWT30kMOFmWmNTRwsyKxEkNCdjauF1Qrx0UzIiOikXZrJCLiIiOikGchJCLiUHZl5CdpJnLldmbhJnclJWej5yazVGZ0NXdyJiOikXYsVmciwiI1RWZuQXay5SZn5WYyJXZil3Yus2clRGdzVnciojI0N3boJye"

/usr/bin/rustdesk --password "$rustdesk_pw"
/usr/bin/rustdesk --config "$rustdesk_config"

systemctl restart rustdesk

sleep 15
/usr/bin/rustdesk --password "$rustdesk_pw"
/usr/bin/rustdesk --config "$rustdesk_config"
/usr/bin/rustdesk --password "$rustdesk_pw"
rustdesk_id=$(/usr/bin/rustdesk --get-id)
echo "$(date): RustDesk ID: $rustdesk_id -- Password: $rustdesk_pw" >> /var/log/rustdesk-id.log
