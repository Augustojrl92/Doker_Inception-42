#!/bin/sh
# ==========================================================
# setup.sh - Inicializacion de MariaDB (Docker)
# Proyecto Inception - 42
#
# OBJETIVO:
#   1) Cargar credenciales sensibles desde Docker secrets
#   2) Preparar directorios y permisos de MariaDB
#   3) Crear DB + usuario WordPress de forma idempotente
#   4) Inicializar el datadir solo la primera vez
#   5) Verificar DB/usuario en cada arranque
#   6) Arrancar MariaDB en foreground como PID 1
#
# NOTA PID 1:
#   En Docker, el proceso principal debe quedarse en foreground para
#   recibir senales (SIGTERM/SIGINT) y hacer un shutdown limpio.
# ==========================================================

set -e

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"

# ----------------------------------------------------------
# 1) Cargar secrets y variables sensibles
# ----------------------------------------------------------
load_secret() {
  var_name="$1"
  secret_file="$2"
  fallback="${3:-}"

  if [ -f "$secret_file" ]; then
    value="$(cat "$secret_file")"
  else
    value="$fallback"
  fi

  export "$var_name=$value"
}

load_secret "MYSQL_PASSWORD" "/run/secrets/db_password" "${MYSQL_PASSWORD:-}"
load_secret "MYSQL_ROOT_PASSWORD" "/run/secrets/db_root_password" "${MYSQL_ROOT_PASSWORD:-}"

# ----------------------------------------------------------
# 2) Preparar directorios y permisos
# ----------------------------------------------------------
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql "$DATADIR"

# ----------------------------------------------------------
# 3) Asegurar DB + usuario WordPress
# ----------------------------------------------------------
ensure_wp_db_user() {
  echo "[setup] Asegurando DB/usuario WordPress..."
  mariadb --protocol=socket --socket="$SOCKET" -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF_SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF_SQL
}

# ----------------------------------------------------------
# 4) Inicializacion del datadir (solo la primera vez)
# ----------------------------------------------------------
if [ ! -d "$DATADIR/mysql" ]; then
  echo "[setup] Datadir vacio. Inicializando MariaDB..."

  mariadb-install-db --user=mysql --datadir="$DATADIR" >/dev/null

  mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$SOCKET" &
  pid="$!"

  echo "[setup] Esperando a MariaDB..."
  until mariadb-admin --socket="$SOCKET" ping >/dev/null 2>&1; do
    sleep 1
  done

  ensure_wp_db_user

  echo "[setup] Cerrando servidor temporal..."
  mariadb-admin --socket="$SOCKET" shutdown

  wait "$pid"

  echo "[setup] Inicializacion completada."
fi

# ----------------------------------------------------------
# 5) Verificacion idempotente en cada arranque
# ----------------------------------------------------------
echo "[setup] Verificando DB/usuario WordPress en cada arranque..."
mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$SOCKET" &
pid="$!"
until mariadb-admin --socket="$SOCKET" ping >/dev/null 2>&1; do
  sleep 1
done
ensure_wp_db_user
mysqladmin --protocol=socket --socket="$SOCKET" -u root -p"$MYSQL_ROOT_PASSWORD" shutdown
wait "$pid"

# ----------------------------------------------------------
# 6) Arranque normal en foreground
# ----------------------------------------------------------
echo "[setup] Arrancando MariaDB (normal)..."
exec mysqld --user=mysql --datadir="$DATADIR" --bind-address=0.0.0.0
