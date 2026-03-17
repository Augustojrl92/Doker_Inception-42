#!/bin/sh
# ==========================================================
# setup.sh - Portainer (Bonus Inception)
# Proyecto Inception - 42
#
# OBJETIVO:
#   - Arrancar Portainer CE usando Docker socket local.
#   - Cargar password admin inicial desde Docker secret.
#   - Mantener ejecucion en foreground como PID 1.
# ==========================================================

set -eu

PASS_FILE="/run/secrets/portainer_admin_password"

if [ ! -f "$PASS_FILE" ]; then
  echo "Missing secret: portainer_admin_password" >&2
  exit 1
fi

mkdir -p /data

exec /opt/portainer/portainer \
  -H unix:///var/run/docker.sock \
  --data /data \
  --http-enabled \
  --admin-password-file "$PASS_FILE"
