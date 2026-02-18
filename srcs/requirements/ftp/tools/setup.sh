#!/bin/sh
# ==========================================================
# setup.sh - FTP (vsftpd) Bonus Inception
# Proyecto Inception - 42
#
# OBJETIVO:
#   - Crear un usuario FTP desde variables de entorno
#   - Configurar vsftpd con modo pasivo para Docker
#   - Servir /srv/ftp (volumen de WordPress) por FTP
#
# VARIABLES:
#   - FTP_USER
#   - FTP_PASSWORD
# ==========================================================

set -e

FTP_USER="${FTP_USER:-ftpuser}"
FTP_PASSWORD="${FTP_PASSWORD:-ftp_pass_42}"
FTP_ROOT="/srv/ftp"
VSFTPD_CHROOT_DIR="/var/run/vsftpd/empty"
FTP_PASV_ADDRESS="${FTP_PASV_ADDRESS:-127.0.0.1}"

# Crear usuario FTP si no existe.
if ! id "$FTP_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/sh "$FTP_USER"
fi

echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

# Directorio de datos del FTP (montado desde docker-compose).
mkdir -p "$FTP_ROOT"
# Directorio interno requerido por vsftpd para chroot seguro.
mkdir -p "$VSFTPD_CHROOT_DIR"
# Carpeta de escritura dedicada para no tocar permisos del core de WP.
mkdir -p "$FTP_ROOT/uploads"
chown -R "$FTP_USER:$FTP_USER" "$FTP_ROOT/uploads"

# Renderiza plantilla de configuracion con variables del entorno.
cp /etc/vsftpd.conf.template /etc/vsftpd.conf
sed -i "s|__FTP_ROOT__|${FTP_ROOT}|g" /etc/vsftpd.conf
sed -i "s|__FTP_PASV_ADDRESS__|${FTP_PASV_ADDRESS}|g" /etc/vsftpd.conf

# vsftpd en foreground para cumplir buenas practicas Docker (PID 1).
exec /usr/sbin/vsftpd /etc/vsftpd.conf
