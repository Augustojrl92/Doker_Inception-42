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

# Imagen base permitida por el subject (Debian estable previa).
FROM debian:bullseye

# PHP + driver MySQL para ejecutar Adminer, curl para descargarlo.
RUN apt-get update && apt-get install -y \
    php7.4-cli \
    php7.4-mysql \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Directorio web servido por el built-in server de PHP.
RUN mkdir -p /var/www/html
# Descarga de Adminer en un único index.php.
RUN curl -fsSL https://www.adminer.org/latest.php -o /var/www/html/index.php

# Script de arranque como entrypoint (proceso principal del contenedor).
COPY tools/setup.sh /tools/setup.sh
RUN chmod +x /tools/setup.sh

# Puerto interno del contenedor (publicado luego en compose).
EXPOSE 8080

ENTRYPOINT ["/tools/setup.sh"]
