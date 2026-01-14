# ================================
# Dockerfile para el servicio WordPress (php-fpm)
# Proyecto Inception - 42
#
# Este contenedor:
# - NO incluye nginx
# - Ejecuta PHP-FPM
# - Sirve WordPress vía FastCGI (puerto 9000)
# ================================

FROM debian:bullseye

# --------------------------------
# Instalación de dependencias
# --------------------------------
# php-fpm        -> motor PHP (FastCGI)
# php-mysql     -> conexión con MariaDB
# curl           -> descargar WP-CLI / WordPress
# mariadb-client -> comprobaciones DB
RUN apt-get update && apt-get install -y \
    php7.4-fpm php7.4-mysql \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------
# PHP-FPM: escuchar por TCP en 9000
# (en lugar de socket unix)
# --------------------------------
RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|g' /etc/php/7.4/fpm/pool.d/www.conf

# --------------------------------
# Directorio donde vivirá WordPress
# (se montará como volumen)
# --------------------------------
RUN mkdir -p /var/www/html

# --------------------------------
# Script de arranque
# --------------------------------
COPY tools/setup.sh /tools/setup.sh
RUN chmod +x /tools/setup.sh

# Puerto FastCGI interno
EXPOSE 9000

# Entrypoint del contenedor
ENTRYPOINT ["/tools/setup.sh"]
