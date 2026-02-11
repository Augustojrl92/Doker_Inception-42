# Checklist de Evaluación Inception (Paso a Paso)

Este checklist sigue el orden de la escala de evaluación de 42.

**Importante**
1. Ejecuta estos comandos en la VM usada para la evaluación.
2. En campus/rootless usa el puerto `8443` en vez de `443`.
3. Sustituye `<login>` por tu login de 42 (rutas y dominio).

## 1) Preliminares
1. Confirmar que el estudiante está presente.
2. Verificar que el repo es el correcto y fue clonado en carpeta vacía.
3. Todos los archivos de configuración deben estar en `srcs/` y debe haber `Makefile` en la raíz.

## 2) Limpiar estado de Docker (evaluador)
```bash
docker stop $(docker ps -qa)
docker rm $(docker ps -qa)
docker rmi -f $(docker images -qa)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q) 2>/dev/null
```

## 3) Leer archivos antes de ejecutar
1. `srcs/docker-compose.yml` NO debe tener `network: host` ni `links:`.
2. `srcs/docker-compose.yml` debe incluir `networks:`.
3. Makefile/scripts NO deben usar `--link`.
4. Dockerfiles/entrypoints NO deben usar `tail -f`, `sleep infinity`, `while true`.

## 4) Ejecutar el proyecto
```bash
make build
```

## 5) Explicación del proyecto (oral)
1. Explicar Docker y Docker Compose.
2. Diferencia entre usar imágenes con y sin Compose.
3. Ventajas de Docker vs VM.
4. Justificar la estructura de carpetas.

### Guía de respuesta (oral, versión extensa)
- **Docker y Docker Compose:**
  Docker permite empaquetar una aplicación y sus dependencias en una **imagen** inmutable.
  A partir de esa imagen se crean **contenedores** que se ejecutan aislados, pero comparten el kernel del host.
  Docker Compose es una herramienta de orquestación que define **múltiples servicios** en un solo archivo (`docker-compose.yml`),
  incluyendo redes, volúmenes, variables de entorno y dependencias entre servicios. Con un solo comando (`docker compose up`)
  se construye y se levanta todo el stack.

- **Diferencia entre usar imágenes con y sin Compose:**
  Sin Compose se deben lanzar contenedores manualmente con `docker run`, creando redes y montando volúmenes uno a uno,
  además de gestionar el orden de arranque. Con Compose, toda esa configuración se declara en el YAML,
  y Docker Compose se encarga de crear red, volúmenes y arrancar servicios en el orden correcto.
  En resumen: sin Compose es manual y propenso a errores; con Compose es reproducible y declarativo.

- **Ventajas de Docker vs VM:**
  Una VM ejecuta un sistema operativo completo con su propio kernel, lo que consume más CPU, RAM y disco.
  Docker ejecuta contenedores que **comparten el kernel del host**, por eso es más ligero y rápido en arranque.
  Además, las imágenes garantizan consistencia entre entornos (desarrollo, pruebas y producción).

- **Justificación de la estructura de carpetas:**
  El subject exige que toda la configuración esté en `srcs/` y que haya un `Makefile` en la raíz.
  Esto separa claramente el **orquestador** (Makefile) de la **configuración de servicios** (docker-compose y Dockerfiles).
  También facilita la evaluación: el evaluador sabe exactamente dónde buscar archivos y puede reproducir el despliegue rápido.

## 6) Configuración simple
1. Verificar solo HTTPS:
```bash
curl -kI https://<login>.42.fr | head -n 10
```
2. En campus (sin sudo):
```bash
curl -kI https://127.0.0.1:8443 | head -n 10
```
3. Verificar que **NO** responde en `http://<login>.42.fr` (puerto 80).

## 7) Docker Basics
1. Un Dockerfile por servicio.
2. Basados en `debian:bullseye` o Alpine (penúltima estable).
3. Imágenes construidas localmente (no DockerHub salvo base).
4. `make build` crea todos los contenedores con Compose.

## 8) Docker Network
```bash
docker network ls
```
Explicar qué hace la red Docker.

**Respuesta sugerida (más extensa):**
La red Docker actúa como un *switch virtual* aislado para los contenedores del proyecto.
Dentro de esa red, los servicios se resuelven por nombre mediante DNS interno
(`mariadb`, `wordpress`, `nginx`) sin necesidad de conocer IPs.
Esto permite que WordPress se conecte a MariaDB y que NGINX haga proxy a PHP‑FPM
de forma segura y aislada.  
Además, al no usar `network: host`, los servicios internos no quedan expuestos
al host, reduciendo superficie de ataque y cumpliendo el requisito del subject.

**Ejemplo de salida y cómo interpretarla:**
```
NETWORK ID     NAME             DRIVER    SCOPE
a962a55f643a   bridge           bridge    local
a4c50e135acf   host             host      local
736add97d7b2   none             null      local
8097608958be   srcs_inception   bridge    local
```
- `bridge`, `host`, `none`: redes por defecto de Docker.
- `srcs_inception`: red creada por el proyecto (es la que usan los contenedores).

**Dónde se define y se usa (líneas del proyecto):**
- Definición de red: `srcs/docker-compose.yml` líneas **186–193**.
- Uso en servicios:
  - `mariadb` líneas **65–69**
  - `wordpress` líneas **100–102**
  - `nginx` líneas **164–171**

## 9) NGINX con SSL/TLS
1. `docker compose ps` muestra `nginx`.
2. HTTP (puerto 80) no debe responder.
3. HTTPS muestra WordPress y usa TLSv1.2/1.3.

## 10) WordPress + php-fpm y volumen
1. `docker compose ps` muestra `wordpress`.
2. Dockerfile de WordPress NO instala nginx.
3. Volumen existe:
```bash
docker volume ls
docker volume inspect srcs_wordpress_data | head -n 20
```
Debe mostrar `/home/<login>/data/wordpress`.
4. Iniciar sesión en `/wp-admin` con admin (sin “admin” en el nombre).
5. Añadir comentario y editar página, verificar en la web.

## 11) MariaDB y volumen
1. `docker compose ps` muestra `mariadb`.
2. Dockerfile de MariaDB NO instala nginx.
3. Volumen existe:
```bash
docker volume ls
docker volume inspect srcs_mariadb_data | head -n 20
```
Debe mostrar `/home/<login>/data/mariadb`.
4. Login root sin password debe FALLAR.
5. Login con usuario DB y password, DB no está vacía:
```bash
docker exec mariadb mariadb -u root -p
```
```sql
SHOW DATABASES;
```

## 12) Persistencia
1. Reiniciar la VM.
2. Ejecutar `make build` otra vez.
3. Verificar que cambios de WordPress y DB persisten.

## 13) Bonus (solo si mandatory está perfecto)
1. Redis cache para WordPress.
2. FTP server al volumen de WordPress.
3. Sitio estático (no PHP).
4. Adminer.
5. Servicio extra y justificar por qué es útil.
