# ================================
# Dockerfile para el servicio MariaDB
# Proyecto Inception - 42
#
# Este Dockerfile define la IMAGEN del contenedor de MariaDB.
# Una imagen es una plantilla inmutable que Docker usa para crear contenedores.
# ================================

# Usamos Debian Bullseye como sistema base.
# El subject exige Alpine o Debian (penúltima versión estable).
FROM debian:bullseye

# Instalamos MariaDB Server y Client.
# - mariadb-server: el servicio de base de datos (mysqld)
# - mariadb-client: el cliente mysql para ejecutar comandos SQL
#
# Se limpia la cache de apt para reducir el tamaño final de la imagen.
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copiamos el script de inicialización al contenedor.
# Este script se encargará de:
# - arrancar MariaDB
# - crear la base de datos
# - crear el usuario
# - asignar permisos
COPY tools/setup.sh /tools/setup.sh

# Damos permisos de ejecución al script.
# Sin esto, el contenedor no podría ejecutarlo como ENTRYPOINT.
RUN chmod +x /tools/setup.sh

# Indicamos que el contenedor usa internamente el puerto 3306
# (puerto estándar de MariaDB).
# EXPOSE NO abre el puerto al host, solo documenta su uso.
EXPOSE 3306

# ENTRYPOINT define el comando que SIEMPRE se ejecuta al arrancar el contenedor.
# Aquí usamos un script para inicializar la base antes de lanzar mysqld.
ENTRYPOINT ["/tools/setup.sh"]
