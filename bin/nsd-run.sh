#!/bin/ash

rm -rf /etc/nsd/nsd_*
nsd-control-setup > /dev/null 2>&1
nsd -u ${UID}.${GID} -d -4
