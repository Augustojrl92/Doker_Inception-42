# ==========================================================
# Dockerfile - Servicio Redis (Bonus Inception 42)
# ==========================================================
#
# QUE HACE ESTE ARCHIVO
# ---------------------
# Este Dockerfile construye la imagen del servicio Redis usado como cache.
# Redis se utiliza en WordPress para object cache y reducir consultas repetidas
# a MariaDB, mejorando tiempos de respuesta.
#
# PAPEL EN EL STACK
# -----------------
# - Redis vive en contenedor independiente.
# - WordPress accede por red interna (`redis:6379`).
# - No necesita exponer puerto al exterior para mandatory.
#
# REGLA DE ENFOQUE
# ----------------
# Build-time (Dockerfile): instalar binario de Redis y copiar entrypoint.
# Run-time (setup.sh): ejecutar redis-server en foreground.
# ==========================================================

# Base Debian, consistente con el resto de servicios del proyecto.
FROM debian:bullseye

# Instala servidor Redis desde repositorios Debian.
# Se limpia cache apt para reducir tamaño de la imagen final.
RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# Copia script de arranque del servicio.
COPY tools/setup.sh /tools/setup.sh
# Permiso de ejecucion para usarlo como ENTRYPOINT.
RUN chmod +x /tools/setup.sh

# Puerto interno estandar de Redis.
# EXPOSE documenta intencion; no publica por si solo al host.
EXPOSE 6379

# Arranque por script para centralizar parametros de redis-server.
ENTRYPOINT ["/tools/setup.sh"]

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este Dockerfile es intencionalmente minimalista: Redis no requiere
#   provisionado complejo como MariaDB o WordPress.
# - Si Redis falla en evaluacion, revisar:
#   1) que el contenedor arranque y quede "Up"
#   2) que WordPress use `WP_REDIS_HOST=redis` y puerto 6379
#   3) que no haya conflicto por puertos publicados innecesarios
# ==========================================================
