#!/bin/sh
set -e

CERT_DIR="/etc/nginx/certs"
CERT_FILE="${CERT_DIR}/fullchain.pem"
KEY_FILE="${CERT_DIR}/privkey.pem"

if [ ! -f "${CERT_FILE}" ] || [ ! -f "${KEY_FILE}" ]; then
  echo "[rootly-waf] TLS certificates not found. Generating self-signed certificate for development..."
  mkdir -p "${CERT_DIR}"
  openssl req -x509 -nodes -days 365 \
    -subj "/C=US/ST=Rootly/L=Rootly/O=Rootly/OU=WAF/CN=localhost" \
    -newkey rsa:2048 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" >/dev/null 2>&1
fi

exec "$@"

