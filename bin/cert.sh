#!/bin/ash
#
# Copyright (C) 2019 teletypewriter dorayaki @ttyjp
# MIT License
#

## Set E-Mail address
E_MAIL=""

DOMAIN_NAME="${1}"
DIR="/nginx/ssl/${DOMAIN_NAME}"
DOMAIN_NAMES="${DOMAIN_NAME},*.${DOMAIN_NAME}"
CSR="${DIR}/${DOMAIN_NAME}.csr"
CHAIN_CERT="${DIR}/$(date -I)-chain.pem"
FULLCHAIN_CERT="${DIR}/$(date -I)-fullchain.pem"
CERT_LINK="${DIR}/${DOMAIN_NAME}.pem"


if [ -n "${2}" ]; then E_MAIL="${2}"; fi

if [ -z "${1}" ] || [ -z "${E_MAIL}" ]; then
  echo "Usage  : $(basename ${0}) [Domain name] {E-Mail address}
        Example: $(basename ${0}) example.com user@example.com
        Example: $(basename ${0}) example.com
  " | sed "s/^ *//g" \
  && exit 0
fi

if [ ! -e ${CSR} ]; then
  mkdir -p ${DIR}

  if [ -e "${DIR}/${DOMAIN_NAME}.key" ]; then
    mv ${DIR}/${DOMAIN_NAME}.key ${DIR}/backup-$(date -I).${DOMAIN_NAME}.key
  fi

  openssl ecparam -out ${DIR}/${DOMAIN_NAME}.key -name prime256v1 -genkey \
  && echo "Generated Private KEY: ${DIR}/${DOMAIN_NAME}.key"

  echo "[req]
        distinguished_name=req_distinguished_name
        req_extensions=v3_req
        [v3_req]
        subjectAltName=@alt_names
        [req_distinguished_name]
        [alt_names]
        DNS.1=${DOMAIN_NAME}
        DNS.2=*.${DOMAIN_NAME}" \
  | openssl req -new -sha256 \
      -key ${DIR}/${DOMAIN_NAME}.key \
      -subj "/CN=${DOMAIN_NAME}" \
      -out ${DIR}/${DOMAIN_NAME}.csr \
      -config /dev/stdin \
  && echo "Generated CSR: ${DIR}/${DOMAIN_NAME}.csr"
fi

if [ -e "${CERT_LINK}" ]; then
  NOT_BEFORE="$(openssl x509 -text -fingerprint -noout -in ${CERT_LINK} | grep "Not Before" | awk '{print $3,$4,$5,$6}')"
  ELAPSED_SECONDS="$(expr $(date +%s) - $(date +%s -d "${NOT_BEFORE}"))"

  if [ 5184000 -gt ${ELAPSED_SECONDS} ]; then
    EXPIRE_DATE="$(openssl x509 -text -fingerprint -noout -in ${CERT_LINK} | sed -n "s/^ \{12\}Not After : \(.*\)/\1/p")"

    echo "SKIPPED: ${DOMAIN_NAME} EXPIRE: ${EXPIRE_DATE}" \
    && exit 0
  fi
fi

certbot certonly \
  --agree-tos \
  --cert-path ${CHAIN_CERT} \
  --csr ${CSR} \
  --domain ${DOMAIN_NAMES} \
  --email ${E_MAIL} \
  --fullchain-path ${FULLCHAIN_CERT} \
  --manual \
  --manual-auth-hook /usr/local/bin/authenticator.sh \
  --manual-cleanup-hook /usr/local/bin/cleanup.sh \
  --manual-public-ip-logging-ok \
  --no-eff-email \
  --preferred-challenges=dns \
  --quiet 
  # --test-cert
  # --dry-run

if [ -e ${FULLCHAIN_CERT} ]; then
  if [ -e "${CERT_LINK}" ]; then
    rm -f ${CERT_LINK}
  fi

  cd ${DIR} \
  && ln -s $(basename ${FULLCHAIN_CERT}) $(basename ${CERT_LINK})

  ## NGINX reload.
  nginx -t && nginx -s reload
fi
