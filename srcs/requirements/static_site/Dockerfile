# ==========================================================
# Dockerfile - Servicio Static Site (Bonus Inception 42)
# ==========================================================
#
# QUE HACE ESTE ARCHIVO
# ---------------------
# Construye la imagen del servicio de sitio estatico.
# Este bonus demuestra un servicio web adicional sin PHP ni base de datos.
#
# PAPEL EN EL STACK
# -----------------
# - Publica una pagina estatica separada de WordPress.
# - Usa su propio NGINX y su propio puerto.
# - Mantiene independencia del servicio NGINX mandatory.
#
# REGLA DE ENFOQUE
# ----------------
# Build-time: instalar NGINX, copiar configuracion y archivos web.
# Run-time: arrancar NGINX en foreground (daemon off).
# ==========================================================

# Imagen base Debian, consistente con el proyecto.
FROM debian:bullseye

# Instala NGINX para servir contenido estatico.
# Limpia cache apt para reducir tamaño final de la imagen.
RUN apt-get update && apt-get install -y \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Configuracion principal de NGINX para este servicio.
COPY conf/nginx.conf /etc/nginx/nginx.conf
# Archivos del sitio estatico (HTML/CSS/JS/imagenes).
COPY website/ /var/www/static/

# Puerto interno del servicio static site.
EXPOSE 8080

# Arranque de NGINX en foreground para que sea PID 1 del contenedor.
ENTRYPOINT ["nginx", "-g", "daemon off;"]

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este Dockerfile es simple porque un sitio estatico no necesita runtime
#   complejo ni scripts de bootstrap.
# - Si falla en evaluacion, revisar:
#   1) ruta de archivos en /var/www/static
#   2) configuracion de listen/port en nginx.conf
#   3) mapeo de puerto en docker-compose
# ==========================================================
