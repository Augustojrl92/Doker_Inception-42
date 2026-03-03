#!/bin/sh
# ==========================================================
# setup.sh - Runtime de NGINX (TLS) para Inception 42
# ==========================================================
#
# QUE HACE ESTE SCRIPT
# --------------------
# Este script es el ENTRYPOINT del contenedor NGINX.
# Su trabajo es preparar lo minimo en runtime y luego arrancar NGINX como
# proceso principal del contenedor.
#
# FLUJO RESUMIDO
# --------------
# 1) Verifica si existen certificado y clave TLS.
# 2) Si faltan, los genera con OpenSSL (self-signed).
# 3) Espera a que WordPress (php-fpm) escuche en 9000.
# 4) Lanza NGINX en foreground (`daemon off`) como PID 1.
# ==========================================================

# Modo estricto: aborta ante primer error.
set -e

# Rutas de salida del certificado y clave privada usados por nginx.conf.
CERT="/etc/nginx/ssl/inception.crt"
KEY="/etc/nginx/ssl/inception.key"

# Condicion de generacion:
# si falta certificado o clave, se crean ambos.
if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  # Log visible para saber que el contenedor esta bootstrap-eando TLS.
  echo "[nginx] Generando certificado TLS autofirmado..."

  # Comando OpenSSL para cert autofirmado:
  # - req -x509: genera certificado X.509 autofirmado
  # - -nodes: sin passphrase en clave privada (arranque no interactivo)
  # - -newkey rsa:2048: crea nueva clave RSA de 2048 bits
  # - -keyout/-out: rutas de clave y cert
  # - -days 365: validez de 1 ano
  # - -subj: DN no interactivo (evita prompts en contenedor)
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "$KEY" \
    -out "$CERT" \
    -days 365 \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=Inception/CN=${DOMAIN_NAME}"
fi

# Espera a que PHP-FPM (contenedor wordpress) este escuchando antes de levantar nginx.
# Evita 502 temporales justo despues de un down/up.
echo "[nginx] Esperando a wordpress:9000..."
# Bucle de readiness:
# `nc -z` comprueba si el puerto remoto esta abierto sin enviar datos.
while ! nc -z wordpress 9000 >/dev/null 2>&1; do
  # Reintento cada segundo para no consumir CPU de forma agresiva.
  sleep 1
done

# Mensaje de arranque final.
echo "[nginx] Arrancando NGINX..."
# `exec` reemplaza el shell por nginx para que nginx sea PID 1 real.
# `daemon off;` obliga a quedar en foreground dentro del contenedor.
exec nginx -g "daemon off;"

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este script evita dos fallos comunes:
#   1) NGINX sin certificado al iniciar
#   2) NGINX levantado antes de php-fpm (502 al principio)
# - En Docker, `exec nginx -g "daemon off;"` es obligatorio en practica para:
#   buena gestion de senales y ciclo de vida limpio del contenedor.
# ==========================================================
