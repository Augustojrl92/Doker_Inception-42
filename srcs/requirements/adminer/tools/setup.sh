#!/bin/sh
# ==========================================================
# setup.sh - Runtime Adminer (Bonus Inception 42)
# ==========================================================
#
# QUE HACE ESTE SCRIPT
# --------------------
# Es el ENTRYPOINT del contenedor Adminer.
# Arranca el servidor embebido de PHP para servir `index.php` de Adminer.
#
# CONTEXTO DE USO
# ---------------
# - Adminer es un unico archivo PHP, no requiere NGINX ni Apache.
# - El servidor embebido de PHP es suficiente para entorno de bonus.
# - El puerto interno 8080 se publica en compose como 8081 en host.
# ==========================================================

# Modo estricto: si falla un comando, termina el contenedor.
set -e

# Adminer es una app PHP única; usamos el servidor integrado de PHP
# en foreground para que sea el PID 1 del contenedor.
# `-S 0.0.0.0:8080` => escucha en todas interfaces del contenedor.
# `-t /var/www/html` => directorio raiz donde esta index.php.
# `exec` => reemplaza shell por PHP para manejo correcto de senales.
exec php -S 0.0.0.0:8080 -t /var/www/html

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este script es corto porque Adminer no necesita bootstrap de datos.
# - Si no carga en navegador, revisar:
#   1) contenedor adminer en estado Up
#   2) mapeo de puerto (host 8081 -> container 8080)
#   3) logs del contenedor para errores de PHP
# ==========================================================
