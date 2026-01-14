#!/bin/sh
# =====================================
# Script de inicialización de MariaDB
# Proyecto Inception - 42
#
# Problema del enfoque anterior:
# - `service mariadb start` inicia mysqld (en background)
# - luego `exec mysqld_safe` intenta iniciar OTRO mysqld
# - resultado: "A mysqld process already exists" + reinicios en bucle
#
# En Docker la forma correcta es:
# 1) Inicializar el datadir si está vacío (primer arranque)
# 2) Arrancar MariaDB UNA sola vez como PID 1 (foreground)
# =====================================

set -e

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"

# Aseguramos el directorio del socket (necesario en Debian)
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Aseguramos permisos del datadir (crítico si hay volumen montado)
chown -R mysql:mysql "$DATADIR"

# -------------------------------------
# Primer arranque: si no existen las tablas del sistema, inicializamos
# (esto evita re-crear usuarios/DB en cada reinicio)
# -------------------------------------
if [ ! -d "$DATADIR/mysql" ]; then
  echo "[setup] Datadir vacío. Inicializando MariaDB..."

  # Crea las tablas del sistema en el datadir
  mariadb-install-db --user=mysql --datadir="$DATADIR" >/dev/null

  # Arrancamos temporalmente sin red para configurar usuarios/DB
  mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$SOCKET" &
  pid="$!"

  # Esperamos a que MariaDB esté listo
  echo "[setup] Esperando a MariaDB..."
  until mariadb-admin --socket="$SOCKET" ping >/dev/null 2>&1; do
    sleep 1
  done

  # Creamos DB + usuario + permisos usando el socket local
  echo "[setup] Creando DB/usuario..."
  mariadb --protocol=socket --socket="$SOCKET" -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

  # Apagamos el servidor temporal
  echo "[setup] Cerrando servidor temporal..."
  mariadb-admin --socket="$SOCKET" shutdown

  # Esperamos a que termine
  wait "$pid"

  echo "[setup] Inicialización completada."
fi

# -------------------------------------
# Arranque normal: MariaDB en foreground (PID 1)
# -------------------------------------
echo "[setup] Arrancando MariaDB (normal)..."
exec mysqld --user=mysql --datadir="$DATADIR" --bind-address=0.0.0.0
