#!/bin/sh
# ==========================================================
# setup.sh - Runtime FTP (vsftpd) Bonus Inception 42
# ==========================================================
#
# QUE HACE ESTE SCRIPT
# --------------------
# Es el ENTRYPOINT del contenedor FTP.
# Su trabajo es preparar usuario/directorios/config y arrancar vsftpd.
#
# FLUJO GENERAL
# -------------
# 1) Lee variables de entorno (usuario/password/ip pasiva).
# 2) Crea usuario FTP si no existe.
# 3) Prepara directorios de trabajo y permisos.
# 4) Renderiza plantilla de vsftpd con valores runtime.
# 5) Arranca vsftpd en foreground (PID 1).
# ==========================================================

# Modo estricto: aborta ante primer error.
set -e

# Usuario FTP configurable por entorno (fallback por defecto).
FTP_USER="${FTP_USER:-ftpuser}"
# Password FTP configurable por entorno.
FTP_PASSWORD="${FTP_PASSWORD:-ftp_pass_42}"
# Ruta expuesta por FTP (normalmente volumen de WordPress).
FTP_ROOT="/srv/ftp"
# Directorio requerido por vsftpd para chroot seguro.
VSFTPD_CHROOT_DIR="/var/run/vsftpd/empty"
# IP anunciada en modo pasivo (en local suele ser 127.0.0.1).
FTP_PASV_ADDRESS="${FTP_PASV_ADDRESS:-127.0.0.1}"

# Crear usuario FTP si no existe.
# `id` verifica existencia; si no existe, se crea con home y shell.
if ! id "$FTP_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/sh "$FTP_USER"
fi

# Establece/actualiza password del usuario FTP.
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

# Directorio de datos del FTP (montado desde docker-compose).
# Asegura raiz FTP.
mkdir -p "$FTP_ROOT"
# Directorio interno requerido por vsftpd para chroot seguro.
mkdir -p "$VSFTPD_CHROOT_DIR"
# Carpeta de escritura dedicada para no tocar permisos del core de WP.
mkdir -p "$FTP_ROOT/uploads"
# Ownership para que usuario FTP pueda escribir en uploads.
chown -R "$FTP_USER:$FTP_USER" "$FTP_ROOT/uploads"

# Renderiza plantilla de configuracion con variables del entorno.
# Copia plantilla base.
cp /etc/vsftpd.conf.template /etc/vsftpd.conf
# Sustituye marcador de ruta FTP.
sed -i "s|__FTP_ROOT__|${FTP_ROOT}|g" /etc/vsftpd.conf
# Sustituye marcador de IP pasiva.
sed -i "s|__FTP_PASV_ADDRESS__|${FTP_PASV_ADDRESS}|g" /etc/vsftpd.conf

# vsftpd en foreground para cumplir buenas practicas Docker (PID 1).
# `exec` reemplaza shell por daemon FTP para manejo correcto de senales.
exec /usr/sbin/vsftpd /etc/vsftpd.conf

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este script convierte una plantilla estatica en config util para Docker.
# - Si FTP conecta pero no transfiere, casi siempre es tema de PASV/puertos.
# - Revisar siempre:
#   1) FTP_PASV_ADDRESS correcto para tu entorno
#   2) puertos 2121 y 21000-21010 publicados
#   3) permisos de /srv/ftp/uploads
# ==========================================================
