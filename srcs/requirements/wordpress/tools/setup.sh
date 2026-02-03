#!/bin/sh
# ==========================================================
# setup.sh - Inicializacion de WordPress (PHP-FPM)
# Proyecto Inception - 42
#
# OBJETIVO:
#   1) Esperar a que MariaDB este lista
#   2) Descargar WordPress si no existe
#   3) Crear wp-config.php si no existe (credenciales DB)
#   4) Instalar WordPress automaticamente (SOLO 1 vez)
#   5) Crear un usuario normal (SOLO 1 vez)
#   6) Arrancar PHP-FPM en foreground (PID 1)
#
# NOTA:
#   - Este contenedor NO incluye NGINX.
#   - NGINX (otro contenedor) hace proxy a PHP-FPM por FastCGI.
#   - Todo debe ser IDEMPOTENTE: reinicios no reinstalan WP.
# ==========================================================

set -e # Corta el script si un comando falla.

# Carpeta donde vive WordPress dentro del contenedor.
# Esta ruta esta montada como volumen desde el host.
WP_PATH="/var/www/html"

# Host de MariaDB en la red docker (por defecto: mariadb).
DB_HOST="${MYSQL_HOST:-mariadb}"

# ----------------------------------------------------------
# 1) Esperar a que MariaDB este lista
# ----------------------------------------------------------
echo "[wp] Esperando a MariaDB en ${DB_HOST}..."
until mariadb-admin ping -h"$DB_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent >/dev/null 2>&1; do
  sleep 2 # Reintenta cada 2s hasta que la DB responda.
done
echo "[wp] MariaDB lista."

# ----------------------------------------------------------
# 2) Preparar carpeta y entrar
# ----------------------------------------------------------
mkdir -p "$WP_PATH" # Asegura el directorio.
cd "$WP_PATH"       # Nos movemos al root de WordPress.

# ----------------------------------------------------------
# 3) Asegurar WP-CLI disponible
# ----------------------------------------------------------
if ! command -v wp >/dev/null 2>&1; then
  echo "[wp] WP-CLI no encontrado. Descargando..."
  curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp
fi

# ----------------------------------------------------------
# 4) Descargar WordPress si aun no existe
# ----------------------------------------------------------
if [ ! -f wp-settings.php ]; then
  echo "[wp] Descargando WordPress core..."
  wp core download --allow-root
else
  echo "[wp] WordPress core ya existe."
fi

# ----------------------------------------------------------
# 5) Crear wp-config.php si no existe
# ----------------------------------------------------------
if [ ! -f wp-config.php ]; then
  echo "[wp] Creando wp-config.php..."
  wp config create --allow-root \
    --dbname="$MYSQL_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$MYSQL_PASSWORD" \
    --dbhost="$DB_HOST" \
    --skip-check
else
  echo "[wp] wp-config.php ya existe."
fi

# ----------------------------------------------------------
# 6) Instalacion automatica (solo la primera vez)
# ----------------------------------------------------------
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "[wp] WordPress NO esta instalado. Instalando..."
  wp core install --allow-root \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL"

  echo "[wp] WordPress instalado."

  # Crear usuario normal (no admin)
  if ! wp user get "$WP_USER" --allow-root >/dev/null 2>&1; then
    echo "[wp] Creando usuario normal: $WP_USER"
    wp user create --allow-root \
      "$WP_USER" "$WP_USER_EMAIL" \
      --user_pass="$WP_USER_PASSWORD" \
      --role=subscriber
  fi
else
  echo "[wp] WordPress ya estaba instalado."
fi

# ----------------------------------------------------------
# 7) Arrancar PHP-FPM en foreground (PID 1)
# ----------------------------------------------------------
# PHP-FPM necesita /run/php para crear su PID file.
mkdir -p /run/php
chown -R www-data:www-data /run/php

echo "[wp] Arrancando PHP-FPM..."
exec php-fpm7.4 -F
