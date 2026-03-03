#!/bin/sh
# ==========================================================
# setup.sh - Runtime de WordPress + PHP-FPM (Inception 42)
# ==========================================================
#
# QUE HACE ESTE SCRIPT
# --------------------
# Este archivo es el ENTRYPOINT del contenedor WordPress.
# Se ejecuta en cada arranque y deja la aplicacion en estado listo.
#
# OBJETIVO OPERATIVO
# ------------------
# 1) Esperar base de datos disponible.
# 2) Garantizar WP-CLI instalado.
# 3) Descargar core y generar wp-config.php si faltan.
# 4) Instalar WordPress solo la primera vez.
# 5) Crear usuario no admin solo si no existe.
# 6) Configurar bonus Redis de forma idempotente.
# 7) Arrancar PHP-FPM en foreground como PID 1.
#
# NOTAS CLAVE
# -----------
# - Este contenedor NO trae NGINX; solo PHP-FPM + WordPress.
# - NGINX (otro servicio) reenvia peticiones .php por FastCGI.
# - El script debe ser idempotente: reiniciar contenedor no debe reinstalar.
# ==========================================================

# Modo estricto: corta ejecucion al primer error no controlado.
set -e

# Carpeta donde vive WordPress dentro del contenedor.
# Esta ruta esta montada como volumen persistente.
WP_PATH="/var/www/html"

# Host de MariaDB en red docker.
# Si MYSQL_HOST no esta definido, usa "mariadb" por defecto.
DB_HOST="${MYSQL_HOST:-mariadb}"

# ----------------------------------------------------------
# 1) Esperar a que MariaDB este lista
# ----------------------------------------------------------
# Mensaje de espera en logs.
echo "[wp] Esperando a MariaDB en ${DB_HOST}..."
# Bucle de readiness:
# `mariadb-admin ping` con credenciales de aplicacion hasta que responda OK.
until mariadb-admin ping -h"$DB_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent >/dev/null 2>&1; do
  # Reintento cada 2 segundos para no saturar CPU.
  sleep 2
done
# Confirmacion de disponibilidad.
echo "[wp] MariaDB lista."

# ----------------------------------------------------------
# 2) Preparar carpeta y entrar
# ----------------------------------------------------------
# Crea directorio de WordPress si no existe (`-p` evita error si ya existe).
mkdir -p "$WP_PATH"
# Cambia al directorio raiz del sitio.
cd "$WP_PATH"

# ----------------------------------------------------------
# 3) Asegurar WP-CLI disponible
# ----------------------------------------------------------
# Si `wp` no existe en PATH, lo descargamos una sola vez.
if ! command -v wp >/dev/null 2>&1; then
  echo "[wp] WP-CLI no encontrado. Descargando..."
  # Descarga binario Phar oficial de WP-CLI.
  curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  # Da permiso de ejecucion.
  chmod +x /usr/local/bin/wp
fi

# ----------------------------------------------------------
# 4) Descargar WordPress si aun no existe
# ----------------------------------------------------------
# `wp-settings.php` es indicador fiable de core descargado.
if [ ! -f wp-settings.php ]; then
  echo "[wp] Descargando WordPress core..."
  # Descarga archivos core en el directorio actual.
  wp core download --allow-root
else
  # Si ya existe, no se vuelve a descargar.
  echo "[wp] WordPress core ya existe."
fi

# ----------------------------------------------------------
# 5) Crear wp-config.php si no existe
# ----------------------------------------------------------
# Solo se crea en primer arranque (o si se borro el archivo).
if [ ! -f wp-config.php ]; then
  echo "[wp] Creando wp-config.php..."
  # Genera wp-config.php con credenciales provenientes de .env.
  # `--skip-check` evita validar conexion en este paso.
  wp config create --allow-root \
    --dbname="$MYSQL_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$MYSQL_PASSWORD" \
    --dbhost="$DB_HOST" \
    --skip-check
else
  # Si ya existe, se respeta (idempotencia + persistencia).
  echo "[wp] wp-config.php ya existe."
fi

# ----------------------------------------------------------
# 6) Instalacion automatica (solo la primera vez)
# ----------------------------------------------------------
# Comprueba si WordPress ya esta instalado en la DB.
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "[wp] WordPress NO esta instalado. Instalando..."
  # Instalacion inicial del sitio (admin, titulo, url, email).
  wp core install --allow-root \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL"

  # Confirmacion de instalacion inicial.
  echo "[wp] WordPress instalado."

  # Crear usuario normal (no admin), solo si todavia no existe.
  if ! wp user get "$WP_USER" --allow-root >/dev/null 2>&1; then
    echo "[wp] Creando usuario normal: $WP_USER"
    # Crea usuario suscriptor con datos del entorno.
    wp user create --allow-root \
      "$WP_USER" "$WP_USER_EMAIL" \
      --user_pass="$WP_USER_PASSWORD" \
      --role=subscriber
  fi
else
  # En reinicios normales llegara aqui.
  echo "[wp] WordPress ya estaba instalado."
fi

# ----------------------------------------------------------
# 7) Bonus: Redis cache (idempotente)
# ----------------------------------------------------------
# Solo se configura Redis si WP ya esta instalado.
if wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "[wp] Configurando Redis cache..."

  # Define host/puerto de Redis en wp-config.php.
  # `|| true` evita que falle todo si la constante ya existe.
  wp config set WP_REDIS_HOST 'redis' --type=constant --allow-root >/dev/null 2>&1 || true
  # `--raw` guarda 6379 como entero.
  wp config set WP_REDIS_PORT 6379 --raw --type=constant --allow-root >/dev/null 2>&1 || true

  # Instala y activa plugin redis-cache si aun no existe.
  if ! wp plugin is-installed redis-cache --allow-root >/dev/null 2>&1; then
    wp plugin install redis-cache --activate --allow-root || true
  else
    # Si ya esta instalado, intenta activarlo.
    wp plugin activate redis-cache --allow-root >/dev/null 2>&1 || true
  fi

  # Intenta habilitar object cache.
  # Si Redis aun no responde, no se cae el contenedor.
  wp redis enable --allow-root >/dev/null 2>&1 || true
fi

# ----------------------------------------------------------
# 8) Arrancar PHP-FPM en foreground (PID 1)
# ----------------------------------------------------------
# PHP-FPM necesita /run/php para PID/socket runtime.
mkdir -p /run/php
# Ownership para proceso web.
chown -R www-data:www-data /run/php

# Mensaje final de arranque.
echo "[wp] Arrancando PHP-FPM..."
# `-F` mantiene php-fpm en foreground (requisito para contenedor).
exec php-fpm7.4 -F

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este script combina provisionado y runtime con enfoque idempotente.
# - Usa chequeos previos para no reinstalar ni duplicar recursos.
# - Si algo falla en defensa, revisar primero:
#   1) Variables .env (DB/WP)
#   2) Conectividad a MariaDB
#   3) Estado del volumen /var/www/html
#   4) Salida de logs WP-CLI/PHP-FPM
# ==========================================================
