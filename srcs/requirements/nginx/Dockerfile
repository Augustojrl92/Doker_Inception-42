# ==========================================================
# Dockerfile - NGINX (TLS)
# Proyecto Inception - 42
#
# OBJETIVO:
#   1) Servir HTTPS en el puerto 443
#   2) Usar TLSv1.2 y TLSv1.3
#   3) Hacer proxy FastCGI hacia wordpress:9000
# ==========================================================

FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY tools/setup.sh /tools/setup.sh
RUN chmod +x /tools/setup.sh

EXPOSE 443

ENTRYPOINT ["/tools/setup.sh"]
