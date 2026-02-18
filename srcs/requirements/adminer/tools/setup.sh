#!/bin/sh
# ==========================================================
# setup.sh - Arranque de Adminer (Bonus Inception)
# Proyecto Inception - 42
#
# OBJETIVO:
#   - Servir Adminer en el puerto interno 8080
#   - Ejecutar en foreground para cumplir buenas practicas Docker
#
# DETALLE:
#   - Adminer es una aplicacion PHP de un solo archivo (index.php)
#   - Se usa el servidor embebido de PHP:
#       php -S 0.0.0.0:8080 -t /var/www/html
#   - En docker-compose este 8080 se publica como 8081 en el host
# ==========================================================

set -e

# Adminer es una app PHP única; usamos el servidor integrado de PHP
# en foreground para que sea el PID 1 del contenedor.
exec php -S 0.0.0.0:8080 -t /var/www/html
