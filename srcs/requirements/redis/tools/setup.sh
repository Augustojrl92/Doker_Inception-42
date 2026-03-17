#!/bin/sh
# ==========================================================
# setup.sh - Redis (Bonus Inception)
# Proyecto Inception - 42
#
# OBJETIVO:
#   - Arrancar Redis en foreground (PID 1) para Docker
#   - Exponer Redis dentro de la red interna de Docker
# ==========================================================

set -e

# protected-mode no: permite conexiones desde otros contenedores de la red.
exec redis-server --bind 0.0.0.0 --port 6379 --protected-mode no
