# ==========================================================
# Dockerfile - Servicio WordPress con PHP-FPM (Inception 42)
# ==========================================================
#
# QUE HACE ESTE ARCHIVO
# ---------------------
# Este Dockerfile construye la imagen del servicio WordPress.
# Aquí se prepara el entorno PHP-FPM para que NGINX (en otro contenedor)
# pueda ejecutar archivos PHP por FastCGI.
#
# PAPEL DE WORDPRESS EN LA ARQUITECTURA
# -------------------------------------
# - Descarga/configura WordPress en runtime mediante `setup.sh`.
# - Se conecta a MariaDB para instalación y operación del CMS.
# - Expone PHP-FPM en puerto 9000 dentro de la red Docker.
# - Comparte volumen de `/var/www/html` con NGINX y (bonus) FTP.
#
# REGLA IMPORTANTE DEL SUBJECT
# ----------------------------
# Este contenedor NO debe incluir NGINX.
# La separación de responsabilidades es clave:
# - NGINX: TLS + entrada web
# - WordPress: aplicación PHP-FPM
# ==========================================================

FROM debian:bullseye

# Instalación de paquetes necesarios para runtime de WordPress.
# - php7.4-fpm: proceso PHP en modo FastCGI (sin servidor web embebido).
# - php7.4-mysql: extensión PHP para conectarse a MariaDB/MySQL.
# - curl: descarga de WP-CLI y/o WordPress desde script.
# - mariadb-client: utilidades para verificar disponibilidad de DB.
#
# Se elimina cache de apt al final para hacer la imagen más ligera.
RUN apt-get update && apt-get install -y \
    php7.4-fpm php7.4-mysql \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Configuración de PHP-FPM para escuchar en TCP.
# Por defecto suele usar socket UNIX local; aquí se fuerza:
#   0.0.0.0:9000
# porque NGINX está en otro contenedor y necesita conexión por red interna.
RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|g' /etc/php/7.4/fpm/pool.d/www.conf

# Directorio principal de WordPress dentro del contenedor.
# Este path será respaldado por volumen para persistir:
# - core descargado
# - wp-config.php
# - uploads/plugins/themes
RUN mkdir -p /var/www/html

# Script de arranque del servicio.
# En runtime se encarga de:
# - esperar MariaDB
# - instalar/actualizar WordPress si hace falta
# - generar wp-config.php
# - crear usuario normal si no existe
# - lanzar php-fpm en foreground
COPY tools/setup.sh /tools/setup.sh

# Permiso de ejecución del entrypoint.
RUN chmod +x /tools/setup.sh

# Puerto interno FastCGI.
# No se publica al host directamente en mandatory;
# solo lo consume NGINX a través de la red Docker.
EXPOSE 9000

# Punto de entrada del contenedor.
# Se usa script para centralizar lógica idempotente de instalación.
ENTRYPOINT ["/tools/setup.sh"]

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este Dockerfile no "instala WordPress" completamente en build time;
#   deja esa parte a `setup.sh` para que sea dinámica e idempotente.
# - Build-time: preparar PHP, cliente DB y estructura base.
# - Run-time: completar WordPress según estado del volumen/DB.
# - Si WordPress falla en evaluación, normalmente se revisa:
#   1) conexión a MariaDB (credenciales/host)
#   2) `wp-config.php`
#   3) estado de php-fpm en 9000
#   4) logs de `wordpress` y `nginx`
# ==========================================================
