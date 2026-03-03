# ==========================================================
# Dockerfile - Servicio NGINX con TLS (Inception 42)
# ==========================================================
#
# QUE HACE ESTE ARCHIVO
# ---------------------
# Este Dockerfile construye la imagen del reverse proxy del proyecto.
# NGINX será el único servicio expuesto al exterior para el sitio principal
# de WordPress y será responsable de hablar HTTPS con el cliente.
#
# PAPEL DE NGINX EN LA ARQUITECTURA
# ---------------------------------
# - Termina TLS en el puerto 443 del contenedor.
# - Recibe peticiones web desde el host (según puertos de compose).
# - Sirve contenido estático de WordPress.
# - Reenvía peticiones PHP a php-fpm en `wordpress:9000` (red interna Docker).
#
# REGLA IMPORTANTE DEL SUBJECT
# ----------------------------
# El contenedor debe ser construido desde Debian/Alpine (no imagen "nginx"
# ya lista de Docker Hub), y la configuración TLS debe estar explícita.
# ==========================================================

FROM debian:bullseye

# Instalación de dependencias del servicio.
# - nginx: servidor web/reverse proxy principal.
# - openssl: utilidad para crear certificado y clave autofirmados.
# - netcat-openbsd: ayuda en checks de conectividad desde scripts de arranque.
#
# Se limpia `/var/lib/apt/lists/*` para reducir el tamaño final de la imagen
# y evitar almacenar índices de paquetes innecesarios.
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Directorio estándar donde el setup guardará certificado y clave TLS.
# Mantener esta ruta fija facilita que `nginx.conf` y `setup.sh` coincidan
# sin rutas mágicas dispersas.
RUN mkdir -p /etc/nginx/ssl

# Copia de la configuración principal de NGINX.
# Este archivo define:
# - listener HTTPS (443)
# - protocolos TLS permitidos
# - root para WordPress
# - bloque FastCGI hacia wordpress:9000
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copia del script de entrada.
# En runtime, este script normalmente:
# - genera certificado autofirmado si no existe
# - espera dependencias necesarias
# - ejecuta NGINX en primer plano para que Docker supervise el proceso
COPY tools/setup.sh /tools/setup.sh

# Permiso de ejecución obligatorio para el entrypoint.
RUN chmod +x /tools/setup.sh

# Puerto interno del servicio HTTPS.
# Recordatorio: EXPOSE no publica por sí mismo; la publicación real se hace
# en `docker-compose.yml` mediante `ports` (por ejemplo, 9443:443 o 443:443).
EXPOSE 443

# Punto de entrada del contenedor.
# Se usa script para centralizar inicialización (TLS + arranque) y mantener
# el contenedor reproducible en cada ejecución.
ENTRYPOINT ["/tools/setup.sh"]

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este Dockerfile prepara el entorno de NGINX, pero la lógica "viva"
#   de inicialización ocurre en `setup.sh`.
# - El patrón build/runtime vuelve a ser el mismo que en MariaDB:
#   Dockerfile prepara dependencias; script orquesta arranque real.
# - Si hay problemas de HTTPS en evaluación, se revisa normalmente:
#   1) puertos de compose
#   2) certificados generados en /etc/nginx/ssl
#   3) directivas TLS/FastCGI en nginx.conf
#   4) logs de NGINX y estado de wordpress:9000
# ==========================================================
