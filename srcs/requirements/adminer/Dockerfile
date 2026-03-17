# ==========================================================
# Dockerfile - Adminer (Bonus Inception)
# Proyecto Inception - 42
#
# OBJETIVO:
#   - Levantar Adminer como servicio bonus para gestionar MariaDB
#   - Construir imagen propia (sin usar imagen pre-hecha de Adminer)
#   - Mantener un contenedor simple: PHP CLI + servidor embebido
#
# NOTAS:
#   - Base Debian (permitida por el subject)
#   - Adminer se descarga como archivo PHP único (index.php)
#   - El arranque real se hace en /tools/setup.sh
# ==========================================================

FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-cli \
    php7.4-mysql \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html

RUN curl -fsSL https://www.adminer.org/latest.php -o /var/www/html/index.php

COPY tools/setup.sh /tools/setup.sh
RUN chmod +x /tools/setup.sh

EXPOSE 8080

ENTRYPOINT ["/tools/setup.sh"]
