#!/bin/sh
# ==========================================================
# setup.sh - Runtime Portainer (Bonus Inception 42)
# Portainer es una interfaz web para administrar Docker
# (contenedores, imagenes, volumenes y redes) de forma visual.
# ==========================================================
#
# QUE HACE ESTE SCRIPT
# --------------------
# Este script actua como ENTRYPOINT del contenedor Portainer.
# Su objetivo es validar prerequisitos de seguridad y despues arrancar
# Portainer como proceso principal del contenedor.
#
# FLUJO DE ARRANQUE
# -----------------
# 1) Activa modo estricto para abortar ante errores.
# 2) Comprueba que existe el secret con password admin.
# 3) Garantiza directorio de datos persistentes.
# 4) Ejecuta Portainer en foreground usando docker.sock.
# ==========================================================

# `-e`: aborta si un comando falla.
# `-u`: aborta si se usa variable no definida.
set -eu

# Ruta donde docker compose monta el secret de password admin.
PASS_FILE="/run/secrets/portainer_admin_password"

# Validacion de seguridad:
# sin secret, se evita arrancar un panel de admin sin control inicial.
if [ ! -f "$PASS_FILE" ]; then
  # Error a stderr para que se vea en logs de docker.
  echo "Missing secret: portainer_admin_password" >&2
  # Codigo de salida != 0 para marcar fallo de contenedor.
  exit 1
fi

# Crea directorio de persistencia de Portainer si no existe.
mkdir -p /data

# `exec` reemplaza shell por proceso Portainer (PID 1 real).
# Flags relevantes:
# -H unix:///var/run/docker.sock : endpoint Docker del host.
# --data /data                   : persistencia de configuracion.
# --http-enabled                 : habilita interfaz HTTP (sin TLS propio).
# --admin-password-file          : inicializa password admin desde secret.
exec /opt/portainer/portainer \
  -H unix:///var/run/docker.sock \
  --data /data \
  --http-enabled \
  --admin-password-file "$PASS_FILE"

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este script es pequeno pero critico: protege el arranque exigiendo secret.
# - Si falla Portainer, revisar primero:
#   1) que el archivo secret exista y este montado
#   2) que docker.sock este montado en la ruta esperada
#   3) que el puerto publicado en compose sea accesible
# ==========================================================
