# ==========================================================
# Dockerfile - MariaDB
# Proyecto Inception - 42
#
# OBJETIVO:
#   1) Construir la imagen del servicio MariaDB
#   2) Instalar el servidor y cliente MariaDB
#   3) Preparar el arranque mediante setup.sh
# ==========================================================

FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

COPY tools/setup.sh /tools/setup.sh

RUN chmod +x /tools/setup.sh

EXPOSE 3306

ENTRYPOINT ["/tools/setup.sh"]
