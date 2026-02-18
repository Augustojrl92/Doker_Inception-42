# ==========================================================
# Dockerfile - Static Website (Bonus Inception)
# Proyecto Inception - 42
#
# OBJETIVO:
#   - Servir un sitio estatico (sin PHP) como bonus.
#   - Construir imagen propia basada en Debian.
#   - Exponer contenido por HTTP interno en puerto 8080.
# ==========================================================

FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY website/ /var/www/static/

EXPOSE 8080

ENTRYPOINT ["nginx", "-g", "daemon off;"]
