# ==========================================================
# Dockerfile - Redis (Bonus Inception)
# Proyecto Inception - 42
#
# OBJETIVO:
#   - Levantar Redis como servicio bonus para cache en WordPress
#   - Construir imagen propia con Debian (sin imagen pre-hecha)
# ==========================================================

FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

COPY tools/setup.sh /tools/setup.sh
RUN chmod +x /tools/setup.sh

EXPOSE 6379

ENTRYPOINT ["/tools/setup.sh"]
