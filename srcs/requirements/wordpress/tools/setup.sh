#!/bin/sh
# =====================================
# setup.sh - WordPress (php-fpm)
# Proyecto Inception - 42
#
# Objetivo:
# - Preparar WordPress en /var/www/html (que será un volumen)
# - Configurar wp-config.php con las variables de entorno
# - Esperar a que MariaDB esté accesible
# - Arrancar PHP-FPM en foreground (PID 1)
#
# NOTA:
# - Este contenedor NO incluye NGINX.
# - Solo ejecuta PHP-FPM.
# =====================================

set -e

WP_PATH="/var/www/html"

# Esperar a que MariaDB responda por red
# (mariadb es el nombre del servicio/host en la red docker)
echo "[wp] Esperando a MariaDB en ${MYSQL_HOST:-mariadb}..."
until mariadb-admin ping -h"${MYSQL_HOST:-mariadb}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
  sleep 2
done
echo "[wp] MariaDB lista."

# Si WordPress aún no está descargado (primer arranque), lo instalamos
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
  echo "[wp] Instalando WordPress en ${WP_PATH}..."

  # Descargar WP-CLI
  curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp

  # Descargar WordPress core
  wp core download --allow-root --path="${WP_PATH}"

  # Crear wp-config.php con datos de DB
  wp config create --allow-root \
    --path="${WP_PATH}" \
    --dbname="${MYSQL_DATABASE}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="${MYSQL_PASSWORD}" \
    --dbhost="${MYSQL_HOST:-mariadb}"

  echo "[wp] WordPress configurado (wp-config.php creado)."
fi

# Asegurar permisos básicos (no es perfecto, pero suficiente para el arranque)
chown -R www-data:www-data "${WP_PATH}"

# -------------------------------------
# PHP-FPM necesita /run/php para:
# - el PID file (php7.4-fpm.pid)
# - y a veces sockets/locks internos
# En contenedores, /run es tmpfs y no trae /run/php creado.
# -------------------------------------
mkdir -p /run/php
chown -R www-data:www-data /run/php

# Arrancar PHP-FPM en foreground (PID 1)
# -F: no daemoniza, se queda en primer plano (requisito Docker)
echo "[wp] Arrancando PHP-FPM..."
exec php-fpm7.4 -F
