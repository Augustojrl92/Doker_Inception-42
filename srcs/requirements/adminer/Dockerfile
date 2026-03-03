# ==========================================================
# Dockerfile - Servicio Adminer (Bonus Inception 42)
# ==========================================================
#
# QUE HACE ESTE ARCHIVO
# ---------------------
# Construye una imagen propia de Adminer para gestionar MariaDB desde navegador.
# Adminer es una aplicacion PHP "single-file", por eso el contenedor puede ser
# muy simple: PHP CLI + servidor web embebido.
#
# PAPEL EN EL STACK
# -----------------
# - Facilita comprobar tablas/datos de MariaDB visualmente.
# - Se usa como herramienta de administracion durante pruebas/defensa.
# - Funciona en red interna Docker conectando a host `mariadb`.
#
# REGLA DE ENFOQUE
# ----------------
# Build-time (Dockerfile): instalar PHP y descargar Adminer.
# Run-time (setup.sh): lanzar servidor embebido de PHP en foreground.
# ==========================================================

# Imagen base permitida por el subject (Debian estable previa).
FROM debian:bullseye

# Dependencias necesarias:
# - php7.4-cli: runtime PHP por linea de comandos (incluye built-in server).
# - php7.4-mysql: extension para conectar a MariaDB/MySQL.
# - curl: descarga del archivo Adminer.
# - ca-certificates: validacion TLS al descargar por HTTPS.
# Limpieza de apt para reducir tamaño final.
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
# Permiso para poder ejecutarlo al iniciar el contenedor.
RUN chmod +x /tools/setup.sh

# Puerto interno del contenedor (publicado luego en compose).
EXPOSE 8080

# Arranque controlado por script para mantener consistencia con otros servicios.
ENTRYPOINT ["/tools/setup.sh"]

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este servicio es deliberadamente minimalista: no requiere daemon complejo.
# - Si Adminer falla en evaluacion, revisar:
#   1) que index.php se haya descargado correctamente
#   2) que el contenedor este "Up" y puerto publicado
#   3) que MariaDB sea accesible desde Adminer (`Server: mariadb`)
# ==========================================================
