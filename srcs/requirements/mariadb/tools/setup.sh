#!/bin/sh
# ==========================================================
# setup.sh - Runtime de MariaDB (Inception 42)
# ==========================================================
#
# QUE HACE ESTE SCRIPT
# --------------------
# Este archivo es el entrypoint real del contenedor MariaDB.
# Su responsabilidad no es "instalar paquetes" (eso ocurre en Dockerfile),
# sino preparar y arrancar la base de datos de forma segura e idempotente.
#
# OBJETIVOS PRINCIPALES
# ---------------------
# 1) Inicializar datadir solo cuando esta vacio (primer arranque real).
# 2) Garantizar en cada arranque que existen DB y usuario de WordPress.
# 3) Mantener password de root y permisos en estado esperado.
# 4) Finalizar ejecutando `mysqld` en foreground como proceso PID 1.
#
# POR QUE IMPORTA PID 1 EN DOCKER
# -------------------------------
# Docker considera "vivo" al contenedor mientras su proceso principal siga
# activo. Por eso al final usamos `exec mysqld ...`:
# - `mysqld` recibe senales directamente (SIGTERM/SIGINT).
# - Se facilita apagado limpio y comportamiento predecible.
# ==========================================================

# `set -e` corta ejecucion ante errores.
# Esto evita que el contenedor continue en un estado incompleto/inseguro.
set -e

# Rutas clave del servicio.
# - DATADIR: ficheros fisicos de MariaDB (tablas, logs, metadatos).
# - SOCKET: canal local para conexiones internas sin abrir red.
DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"

# Preparacion de directorio de runtime para socket/PID.
# `mkdir -p` no falla si ya existe; solo garantiza la ruta.
mkdir -p /run/mysqld
# Ownership para que el proceso `mysqld` (usuario mysql) pueda escribir ahi.
chown -R mysql:mysql /run/mysqld

# Permisos sobre datadir persistente.
# Sin ownership correcto, MariaDB puede fallar al arrancar/escribir.
chown -R mysql:mysql "$DATADIR"

# Funcion de "aseguramiento" (idempotente):
# se puede llamar muchas veces y deja DB/usuarios en estado correcto.
ensure_wp_db_user() {
  # Bloque SQL idempotente: puede ejecutarse multiples veces sin romper nada.
  # Requiere root local via socket y password definida en entorno.
  echo "[setup] Asegurando DB/usuario WordPress..."
  # Ejecuta cliente MariaDB por socket UNIX (sin TCP), autenticando como root.
  # `--protocol=socket`: fuerza canal local (mas seguro para bootstrap).
  # `--socket="$SOCKET"`: ruta exacta del socket creado por mysqld.
  # `-u root -p"...":` credenciales administrativas para crear DB/usuarios.
  # `<<EOF_SQL ... EOF_SQL`: heredoc; todo el bloque siguiente se envia como SQL.
  mariadb --protocol=socket --socket="$SOCKET" -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF_SQL
-- Base de datos para WordPress (idempotente)
-- Si no existe, se crea; si ya existe, no falla.
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Usuario WordPress: '%' permite conexion desde otros contenedores
-- Crea el usuario aplicacion con password tomada del .env.
-- Host '%' habilita login remoto desde la red Docker (ej: contenedor wordpress).
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Permisos del usuario WordPress sobre su base
-- Concede permisos completos solo sobre su propia base (no sobre todas).
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Root con password local (evita root sin password)
-- Asegura que root@localhost siempre tenga password definida.
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Root remoto dentro de la red Docker (util para debug)
-- Crea root remoto por comodidad de depuracion entre contenedores.
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
-- Permisos globales + capacidad de delegar permisos (`WITH GRANT OPTION`).
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

-- Aplica cambios de privilegios
-- Fuerza recarga inmediata de tablas de privilegios en memoria.
FLUSH PRIVILEGES;
-- Fin del bloque SQL enviado al cliente `mariadb`.
EOF_SQL
}

# Primer arranque: el subdirectorio `mysql/` aun no existe.
# Eso significa que MariaDB no tiene tablas del sistema inicializadas.
if [ ! -d "$DATADIR/mysql" ]; then
  # Mensaje de diagnostico para identificar primer bootstrap en logs.
  echo "[setup] Datadir vacio. Inicializando MariaDB..."

  # Crea estructura base (mysql.*, ibdata, etc.) en datadir.
  # Se hace como usuario mysql para no dejar ficheros de root.
  mariadb-install-db --user=mysql --datadir="$DATADIR" >/dev/null

  # Arranque temporal local (sin red) para aplicar SQL inicial.
  # `&` lo manda a background para poder seguir con el script.
  mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$SOCKET" &
  # Guardamos PID del proceso temporal para gestionarlo despues.
  pid="$!"

  # Log de espera activa hasta que MariaDB acepte pings por socket.
  echo "[setup] Esperando a MariaDB..."
  # Bucle de readiness:
  # mientras `mariadb-admin ping` falle, esperamos y reintentamos.
  until mariadb-admin --socket="$SOCKET" ping >/dev/null 2>&1; do
    # Pausa de 1 segundo para no saturar CPU con reintentos continuos.
    sleep 1
  done

  # Crea/asegura DB, usuarios y grants.
  ensure_wp_db_user

  # Cierre limpio del servidor temporal tras configurar.
  echo "[setup] Cerrando servidor temporal..."
  # Shutdown via socket para evitar kills bruscos.
  mariadb-admin --socket="$SOCKET" shutdown

  # Espera explicita a que el proceso temporal termine por completo.
  wait "$pid"

  # Marca visual de fin de bootstrap inicial.
  echo "[setup] Inicializacion completada."
fi

# Arranques posteriores:
# Aunque el volumen ya exista, volvemos a asegurar DB/usuario para evitar
# estados incompletos (ej. volumen restaurado parcialmente o cambios manuales).
echo "[setup] Verificando DB/usuario WordPress en cada arranque..."
# Arranque temporal otra vez (modo local) para revalidar SQL idempotente.
mysqld --user=mysql --datadir="$DATADIR" --skip-networking --socket="$SOCKET" &
# Guardamos PID para poder hacer wait al terminar.
pid="$!"
# Espera de disponibilidad antes de lanzar SQL.
until mariadb-admin --socket="$SOCKET" ping >/dev/null 2>&1; do
  # Reintento cada 1s.
  sleep 1
done
# Reasegura DB/usuario/password/grants.
ensure_wp_db_user
# Apagado limpio usando cliente mysqladmin y credenciales root.
mysqladmin --protocol=socket --socket="$SOCKET" -u root -p"$MYSQL_ROOT_PASSWORD" shutdown
# Espera fin completo del arranque temporal.
wait "$pid"

# Arranque final "normal" del servicio:
# - sin --skip-networking (acepta conexiones de la red interna)
# - bind en 0.0.0.0 para que WordPress pueda conectar por nombre de servicio.
echo "[setup] Arrancando MariaDB (normal)..."
# `exec` reemplaza el shell por mysqld:
# MariaDB pasa a ser PID 1 real del contenedor.
exec mysqld --user=mysql --datadir="$DATADIR" --bind-address=0.0.0.0

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este script aplica un patron muy comun en Inception:
#   iniciar temporalmente, configurar, apagar, y arrancar normal.
# - El bloque SQL usa IF NOT EXISTS para ser idempotente y estable.
# - La mayor parte de errores reales de MariaDB en evaluacion suelen venir de:
#   1) credenciales inconsistentes (.env vs setup scripts)
#   2) permisos/ownership del datadir
#   3) volumen con estado previo inesperado
#   4) servicio arrancado sin esperar readiness
# ==========================================================
