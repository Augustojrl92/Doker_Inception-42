#!/bin/sh
# =====================================
# setup.sh - NGINX (TLS)
# Proyecto Inception - 42
#
# Objetivo:
# - Generar certificado TLS autofirmado si no existe
# - Arrancar NGINX en foreground (daemon off)
# =====================================

set -e

CERT="/etc/nginx/ssl/inception.crt"
KEY="/etc/nginx/ssl/inception.key"

# Si no existe el cert/key, los generamos una sola vez
if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  echo "[nginx] Generando certificado TLS autofirmado..."

  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "$KEY" \
    -out "$CERT" \
    -days 365 \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=Inception/CN=${DOMAIN_NAME}"
fi

echo "[nginx] Arrancando NGINX..."
exec nginx -g "daemon off;"
