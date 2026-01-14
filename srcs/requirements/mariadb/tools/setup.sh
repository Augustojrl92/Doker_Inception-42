#!/bin/sh
# =====================================
# Script de inicialización de MariaDB
# Proyecto Inception - 42
#
# Este script se ejecuta cuando el contenedor arranca.
# Su función es:
# 1) Arrancar MariaDB
# 2) Crear base de datos si no existe
# 3) Crear usuario si no existe
# 4) Dar permisos
# 5) Mantener MariaDB ejecutándose en primer plano
# =====================================

# set -e hace que el script se detenga si ocurre cualquier error.
# Esto evita que el contenedor siga corriendo en un estado incorrecto.
set -e

# Arrancamos el servicio MariaDB.
# Esto permite que el cliente mysql pueda conectarse
# y ejecutar comandos SQL.
service mariadb start

# Ejecutamos comandos SQL usando un heredoc.
# Las variables MYSQL_* vienen del archivo .env
# y serán inyectadas desde docker-compose.
mysql -u root <<EOF
-- Crear la base de datos si no existe
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Crear el usuario si no existe
-- '%' permite conexiones desde otros contenedores (WordPress)
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Asignar todos los permisos del usuario sobre la base de datos
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

-- Aplicar los cambios de permisos
FLUSH PRIVILEGES;
EOF

# Lanzamos MariaDB en primer plano.
# exec reemplaza el proceso del script (PID 1) por mysqld_safe.
# Esto es CRUCIAL en Docker para:
# - manejo correcto de señales
# - reinicios
# - evitar procesos zombie
exec mysqld_safe

