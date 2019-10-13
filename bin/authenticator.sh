#!/bin/ash

SERVER_IP="$(host ns0 | sed -n "s/^.*has address \(.*\)/\1/p")"
PORT="53"

echo "server ${SERVER_IP} ${PORT}
update add _acme-challenge.${CERTBOT_DOMAIN}. 5 IN TXT \"${CERTBOT_VALIDATION}\"
" | nsupdate -v -k /nginx/tsig.key

sleep 5
