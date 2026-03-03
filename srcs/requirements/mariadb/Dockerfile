# ==========================================================
# Dockerfile - Servicio MariaDB (Inception 42)
# ==========================================================
#
# QUE HACE ESTE ARCHIVO
# ---------------------
# Este Dockerfile construye la imagen del servicio de base de datos.
# En Docker, una "imagen" es una plantilla inmutable con todo lo necesario
# (sistema base + paquetes + scripts) para crear contenedores repetibles.
#
# OBJETIVO DENTRO DE INCEPTION
# ----------------------------
# - Ofrecer una instancia MariaDB aislada en su propio contenedor.
# - Permitir inicialización automática (DB, usuario, permisos) vía setup.sh.
# - Mantener persistencia real usando volúmenes (definidos en compose).
#
# REGLA DEL SUBJECT
# -----------------
# Inception exige construir desde Alpine o Debian (penúltima estable),
# evitando imágenes preconfiguradas de servicios.

# Base del sistema operativo de la imagen.
# Elegimos Debian Bullseye para cumplir el subject y mantener consistencia
# con el resto de servicios del proyecto.
FROM debian:bullseye

# Instalación de paquetes necesarios para MariaDB.
# - mariadb-server: daemon de base de datos (mysqld).
# - mariadb-client: cliente CLI para ejecutar comandos SQL desde scripts.
#
# Nota de optimización:
# Se elimina /var/lib/apt/lists/* para reducir tamaño final de imagen.
# Esto no afecta al runtime; solo evita basura de índices apt en capas.
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copia del script de arranque/initialization.
# Este script es el "cerebro" del contenedor en runtime:
# - prepara directorios/permisos
# - inicializa datadir en primer arranque
# - crea DB/usuarios con variables de entorno
# - arranca mysqld en foreground
COPY tools/setup.sh /tools/setup.sh

# Permisos de ejecución para el script de entrada.
# Sin chmod +x, ENTRYPOINT fallaría con "permission denied".
RUN chmod +x /tools/setup.sh

# Puerto interno estándar de MariaDB.
# IMPORTANTE:
# EXPOSE no publica puertos al host por sí mismo; solo documenta intención.
# La publicación real se controla desde docker-compose con "ports" (si aplica).
EXPOSE 3306

# Comando principal del contenedor.
# ENTRYPOINT garantiza que siempre se ejecute setup.sh al iniciar.
# Esto permite un arranque determinista y alineado con la lógica de Inception.
ENTRYPOINT ["/tools/setup.sh"]

# ==========================================================
# CONCLUSION (ESTUDIO RAPIDO)
# ==========================================================
#
# - Este Dockerfile NO contiene lógica SQL compleja: delega esa lógica al
#   script setup.sh para mantener separación clara entre build y runtime.
# - "Build-time" (Dockerfile): preparar entorno base y dependencias.
# - "Run-time" (setup.sh): inicializar datos y arrancar servicio.
# - Es una arquitectura limpia para defensa:
#   imagen mínima + script explícito + persistencia vía volumen compose.
# - Si MariaDB falla en evaluación, normalmente el diagnóstico se hace
#   en setup.sh/logs, no en este Dockerfile.
# ==========================================================
