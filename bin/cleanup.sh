#!/bin/ash

SERVER_IP="$(host ns0 | sed -n "s/^.*has address \(.*\)/\1/p")"
PORT="53"

echo "server ${SERVER_IP} ${PORT}
update del _acme-challenge.${CERTBOT_DOMAIN}.
" | nsupdate -v -k /nginx/tsig.key

