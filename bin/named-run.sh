#!/bin/ash

mkdir -p \
  /var/log/named \
  /var/log/nsd \
  /var/log/dnstap \
  /var/log/nginx

chown -R ${UID}.${GID} \
  /var/db/nsd \
  /var/run/nsd \
  /var/log \
  /etc/nsd/secondary \
  /var/named

rm -f /etc/bind/rndc.key \
  && rndc-confgen -a -A hmac-sha256 > /dev/null 2>&1 \
  && chmod 640 /etc/bind/rndc.key \
  && chown root:named /etc/bind/rndc.key

named -u named -f -4
