#!/bin/sh
# ==========================================================
# setup.sh - NGINX (TLS)
# Proyecto Inception - 42
#
# OBJETIVO:
#   1) Generar un certificado TLS autofirmado si no existe
#   2) Esperar a que WordPress (PHP-FPM) este disponible
#   3) Arrancar NGINX en foreground como PID 1
# ==========================================================

set -e

CERT="/etc/nginx/ssl/inception.crt"
KEY="/etc/nginx/ssl/inception.key"

# ----------------------------------------------------------
# 1) Generar certificado TLS autofirmado
# ----------------------------------------------------------
if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  echo "[nginx] Generando certificado TLS autofirmado..."

  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "$KEY" \
    -out "$CERT" \
    -days 365 \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=Inception/CN=${DOMAIN_NAME}"
fi

# ----------------------------------------------------------
# 2) Esperar a que WordPress escuche en 9000
# ----------------------------------------------------------
echo "[nginx] Esperando a wordpress:9000..."
while ! nc -z wordpress 9000 >/dev/null 2>&1; do
  sleep 1
done

# ----------------------------------------------------------
# 3) Arrancar NGINX en foreground
# ----------------------------------------------------------
echo "[nginx] Arrancando NGINX..."
exec nginx -g "daemon off;"
