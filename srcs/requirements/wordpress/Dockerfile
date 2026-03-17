# ==========================================================
# Dockerfile - WordPress (PHP-FPM)
# Proyecto Inception - 42
#
# OBJETIVO:
#   1) Construir la imagen del servicio WordPress
#   2) Instalar PHP-FPM y dependencias necesarias
#   3) Configurar PHP-FPM para escuchar en 9000
#   4) Preparar el arranque mediante setup.sh
# ==========================================================

FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm php7.4-mysql \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|g' /etc/php/7.4/fpm/pool.d/www.conf

RUN mkdir -p /var/www/html

COPY tools/setup.sh /tools/setup.sh
RUN chmod +x /tools/setup.sh

EXPOSE 9000

ENTRYPOINT ["/tools/setup.sh"]
