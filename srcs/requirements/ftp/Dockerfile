# ==========================================================
# Dockerfile - FTP (Bonus Inception)
# Proyecto Inception - 42
#
# OBJETIVO:
#   - Exponer un servidor FTP para acceder al volumen de WordPress
#   - Construir imagen propia (Debian + vsftpd)
#   - Mantener el proceso en foreground (PID 1)
# ==========================================================

FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf.template
COPY tools/setup.sh /tools/setup.sh
RUN chmod +x /tools/setup.sh

EXPOSE 21 21000-21010

ENTRYPOINT ["/tools/setup.sh"]
