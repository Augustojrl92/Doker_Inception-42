#!/bin/sh
# ==========================================================
# setup.sh - Runtime Redis (Bonus Inception 42)
# ==========================================================
#
# QUE HACE ESTE SCRIPT
# --------------------
# Este script es el ENTRYPOINT del contenedor Redis.
# Su tarea es arrancar `redis-server` con parametros compatibles con
# comunicacion entre contenedores dentro de la red Docker.
#
# FLUJO
# -----
# 1) Activa modo estricto.
# 2) Ejecuta redis-server en foreground para que sea PID 1 del contenedor.
# ==========================================================

# Modo estricto: aborta si un comando falla.
set -e

# Arranque de Redis:
# --bind 0.0.0.0       : escucha en todas las interfaces del contenedor.
# --port 6379          : puerto estandar de Redis.
# --protected-mode no  : permite acceso desde otros contenedores del bridge.
#                        (si quedara "yes", podria rechazar conexiones remotas).
#
# `exec` reemplaza el shell por redis-server para gestion correcta de senales.
exec redis-server --bind 0.0.0.0 --port 6379 --protected-mode no

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este script es corto porque Redis no necesita bootstrap de datos.
# - Lo esencial es exponer Redis a la red interna para WordPress.
# - Si WordPress no conecta, revisar:
#   1) nombre de host `redis` en wp-config
#   2) estado del contenedor redis
#   3) logs de WordPress y plugin redis-cache
# ==========================================================
