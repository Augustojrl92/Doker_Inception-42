#!/bin/sh
# ==========================================================
# setup.sh - Inicializacion de MariaDB (Docker)
# Proyecto Inception - 42
#
# OBJETIVO:
#   - Inicializar el datadir SOLO la primera vez (si esta vacio)
#   - Crear DB + usuario WordPress + aplicar password de root
#   - Arrancar MariaDB UNA SOLA VEZ en foreground como PID 1
#
# NOTA PID 1:
#   En Docker, el proceso principal debe quedarse en foreground para
#   recibir senales (SIGTERM/SIGINT) y hacer un shutdown limpio.
# ==========================================================

set -e # Corta el script si un comando falla, evitando estados incoherentes.

DATADIR="/var/lib/mysql" # Ruta del datadir donde MariaDB guarda los datos.
SOCKET="/run/mysqld/mysqld.sock" # Socket local para conexiones sin red.

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

mkdir -p /run/mysqld # Crea el directorio del socket si no existe.
chown -R mysql:mysql /run/mysqld # Asegura permisos del usuario mysql.

chown -R mysql:mysql "$DATADIR" # Permisos correctos sobre el datadir.

ensure_wp_db_user() {
  echo "[setup] Asegurando DB/usuario WordPress..." # Idempotente; se puede ejecutar en cada arranque.
  mariadb --protocol=socket --socket="$SOCKET" -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF_SQL
-- Base de datos para WordPress (idempotente)
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Usuario WordPress: '%' permite conexion desde otros contenedores
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Permisos del usuario WordPress sobre su base
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Root con password local (evita root sin password)
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Aplica cambios de privilegios
FLUSH PRIVILEGES;
EOF_SQL
}

# Si no existe la base del sistema, es primer arranque.
if [ ! -d "$DATADIR/mysql" ]; then # Detecta si el datadir esta vacio.
  echo "[setup] Datadir vacio. Inicializando MariaDB..." # Log informativo.

  mariadb-install-db --user=mysql --datadir="$DATADIR" >/dev/null # Inicializa tablas.

  mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$SOCKET" & # Arranque temporal.
  pid="$!" # Guarda el PID para cerrar el proceso temporal luego.

  echo "[setup] Esperando a MariaDB..." # Log de espera.
  until mariadb-admin --socket="$SOCKET" ping >/dev/null 2>&1; do # Espera disponibilidad.
    sleep 1 # Pausa corta entre reintentos.
  done

  ensure_wp_db_user

  echo "[setup] Cerrando servidor temporal..." # Log de cierre.
  mariadb-admin --socket="$SOCKET" shutdown # Apaga el mysqld temporal.

  wait "$pid" # Espera a que el proceso temporal termine.

  echo "[setup] Inicializacion completada." # Log final del primer arranque.
fi

# En stacks con volmen persistente ya inicializado, igualmente necesitamos
# asegurar que existen la DB/usuario de WordPress (subject: idempotencia).
echo "[setup] Verificando DB/usuario WordPress en cada arranque..."
mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$SOCKET" &
pid="$!"
until mariadb-admin --socket="$SOCKET" ping >/dev/null 2>&1; do
  sleep 1
done
ensure_wp_db_user
mysqladmin --protocol=socket --socket="$SOCKET" -u root -p"$MYSQL_ROOT_PASSWORD" shutdown
wait "$pid"

# Arranque normal: mysqld en foreground como PID 1.
echo "[setup] Arrancando MariaDB (normal)..." # Log de arranque final.
exec mysqld --user=mysql --datadir="$DATADIR" --bind-address=0.0.0.0 # PID 1 real.
