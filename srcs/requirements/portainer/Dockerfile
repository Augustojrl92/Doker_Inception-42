# ==========================================================
# Dockerfile - Servicio Portainer (Bonus Free Choice)
# Inception 42
# Portainer es una interfaz web para administrar Docker
# (contenedores, imagenes, volumenes y redes) de forma visual.
# ==========================================================
#
# QUE HACE ESTE ARCHIVO
# ---------------------
# Este Dockerfile construye una imagen propia de Portainer CE,
# evitando usar una imagen pre-hecha para mantener coherencia con
# la filosofia del proyecto (build controlado y entendible).
#
# PAPEL DE PORTAINER EN TU STACK
# ------------------------------
# - Proveer panel web para visualizar/gestionar contenedores Docker.
# - Usar un volumen de datos propio (`/data`) para persistir configuracion.
# - Leer password inicial de admin desde secret.
#
# REGLA DE DISEÑO
# ---------------
# Build-time (Dockerfile): descarga binario + dependencias.
# Run-time (setup.sh): valida secret y arranca proceso principal.
# ==========================================================

# Imagen base Debian estable (alineada con el resto de servicios del proyecto).
FROM debian:bullseye

# Version parametrizable de Portainer para facilitar upgrades controlados.
ARG PORTAINER_VERSION=2.20.3

# Dependencias minimas necesarias:
# - ca-certificates: validacion TLS al descargar por HTTPS.
# - curl: descarga del tarball oficial.
# - tar: descompresion del paquete.
# Limpieza de cache apt para reducir tamaño de imagen.
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Crea directorio de datos persistentes y descarga binario oficial.
# El tar.gz se extrae en /opt, quedando /opt/portainer/portainer.
RUN mkdir -p /data \
    && curl -fsSL "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz" \
      | tar -xz -C /opt

# Copia el script de arranque que hará validaciones de runtime.
COPY tools/setup.sh /tools/setup.sh
# Permiso de ejecucion para usarlo como ENTRYPOINT.
RUN chmod +x /tools/setup.sh

# Puerto HTTP de Portainer dentro del contenedor.
# La publicacion real al host se define en docker-compose (p.ej. 9000:9000).
EXPOSE 9000

# Punto de entrada del contenedor.
# Centraliza validacion de secret y arranque del proceso principal.
ENTRYPOINT ["/tools/setup.sh"]

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este Dockerfile no configura usuarios ni credenciales: eso queda a setup.sh
#   y secrets en runtime.
# - Si Portainer falla en arranque, revisar normalmente:
#   1) descarga correcta del binario en build
#   2) montaje de secret y docker.sock en compose
#   3) permisos/estado de /data
# ==========================================================
