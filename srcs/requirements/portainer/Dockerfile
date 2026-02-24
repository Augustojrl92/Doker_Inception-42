# ==========================================================
# Dockerfile - Portainer (Free Choice Bonus)
# Proyecto Inception - 42
#
# OBJETIVO:
#   - Exponer Portainer para administracion visual de Docker.
#   - Construir imagen propia basada en Debian.
#   - Ejecutar Portainer en foreground como proceso PID 1.
# ==========================================================

FROM debian:bullseye

ARG PORTAINER_VERSION=2.20.3

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data \
    && curl -fsSL "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz" \
      | tar -xz -C /opt

COPY tools/setup.sh /tools/setup.sh
RUN chmod +x /tools/setup.sh

EXPOSE 9000

ENTRYPOINT ["/tools/setup.sh"]
