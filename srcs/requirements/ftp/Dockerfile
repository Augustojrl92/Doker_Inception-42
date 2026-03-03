# ==========================================================
# Dockerfile - Servicio FTP (vsftpd) Bonus Inception 42
# ==========================================================
#
# QUE HACE ESTE ARCHIVO
# ---------------------
# Construye la imagen del servicio FTP para acceder al volumen de WordPress.
# Se basa en Debian e instala `vsftpd`, evitando imagenes preconstruidas.
#
# PAPEL EN EL STACK
# -----------------
# - Permite subir/bajar archivos al contenido de WordPress.
# - Usa modo pasivo para funcionar correctamente con Docker.
# - Comparte almacenamiento con el volumen del sitio.
#
# REGLA DE ENFOQUE
# ----------------
# Build-time: instalar vsftpd y copiar config/script.
# Run-time: crear usuario, renderizar config y arrancar daemon en foreground.
# ==========================================================

# Base Debian, consistente con el resto de servicios.
FROM debian:bullseye

# Instala servidor FTP vsftpd.
# Limpia indices apt para reducir tamaño final de imagen.
RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

# Plantilla de configuracion (se rellenara con variables en setup.sh).
COPY conf/vsftpd.conf /etc/vsftpd.conf.template
# Script de arranque/parametrizacion.
COPY tools/setup.sh /tools/setup.sh
# Permiso ejecutable para el entrypoint.
RUN chmod +x /tools/setup.sh

# Puerto de control FTP (21) y rango pasivo para datos (21000-21010).
EXPOSE 21 21000-21010

# Arranque mediante script para configurar usuario y plantilla dinamica.
ENTRYPOINT ["/tools/setup.sh"]

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este Dockerfile deja la logica variable para runtime (setup.sh),
#   lo cual es correcto porque usuario/password/IP pasiva dependen del entorno.
# - Si FTP falla, revisar:
#   1) puertos publicados en compose
#   2) config renderizada en /etc/vsftpd.conf
#   3) permisos del directorio compartido /srv/ftp
# ==========================================================
