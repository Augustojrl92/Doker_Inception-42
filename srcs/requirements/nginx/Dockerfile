# ================================
# Dockerfile para NGINX (TLS)
# Proyecto Inception - 42
#
# Objetivo:
# - Servir HTTPS en el puerto 443
# - Usar TLSv1.2 y TLSv1.3
# - Hacer proxy FastCGI hacia wordpress:9000
# ================================

FROM debian:bullseye

# Instalamos nginx y openssl
# openssl se usará para generar un certificado autofirmado dentro del contenedor
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Crear carpetas típicas para certificados
RUN mkdir -p /etc/nginx/ssl

# Copiamos la configuración nginx (la crearemos en el siguiente micro-paso)
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copiamos el script de arranque (genera certificado y arranca nginx)
COPY tools/setup.sh /tools/setup.sh
RUN chmod +x /tools/setup.sh

# Exponemos el puerto HTTPS
EXPOSE 443

# Arranque mediante script (para generar cert y luego ejecutar nginx)
ENTRYPOINT ["/tools/setup.sh"]
