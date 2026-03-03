# ESTUDIO - Inception 42 (Guia Completa del Proyecto)

## 1) Proposito de este documento
Este documento resume y explica de forma estructurada todo el proyecto `intra3`, incluyendo:
- Arquitectura general.
- Mandatory y bonus.
- Flujo de arranque de servicios.
- Rol de cada Dockerfile, `setup.sh` y archivos de configuracion.
- Variables de entorno y secrets.
- Pruebas recomendadas para defensa.
- Errores comunes y como diagnosticarlos.

La idea es que puedas estudiar el proyecto de extremo a extremo, justificar decisiones en defensa y depurar rapido cualquier fallo.

---

## 2) Estructura real del proyecto
En la raiz del repo tienes:
- `Makefile`: comandos operativos (`build`, `up`, `down`, `status`, etc.).
- `srcs/docker-compose.yml`: orquestacion principal.
- `srcs/.env`: variables de configuracion.
- `srcs/secrets/`: secretos (actualmente Portainer).
- `srcs/requirements/<servicio>/`: Dockerfile y runtime de cada servicio.

Servicios actuales definidos en `docker-compose.yml`:
- Mandatory: `mariadb`, `wordpress`, `nginx`.
- Bonus: `redis`, `adminer`, `ftp`, `static_site`, `portainer`.

---

## 3) Vision de arquitectura
### Flujo principal mandatory
1. `mariadb` levanta base de datos y garantiza DB/usuarios.
2. `wordpress` espera MariaDB, instala WordPress (si falta), configura usuarios y arranca PHP-FPM.
3. `nginx` genera cert TLS (si falta), espera `wordpress:9000` y expone sitio por HTTPS.

### Flujo bonus
- `redis`: cache de objetos para WordPress.
- `adminer`: panel web para gestionar MariaDB.
- `ftp`: acceso FTP al volumen de WordPress.
- `static_site`: web estatica separada.
- `portainer`: panel de administracion visual de Docker.

---

## 4) Docker Compose (cerebro del stack)
Archivo: `srcs/docker-compose.yml`

### Que controla
- Build de imagenes por servicio.
- Redes internas (`inception` bridge).
- Persistencia (`mariadb_data`, `wordpress_data`, `portainer_data`).
- Puertos publicados al host.
- Variables (`env_file`, `environment`).
- Secret de Portainer.

### Puertos host actuales
- NGINX principal: `9443 -> 443`.
- Adminer: `8081 -> 8080`.
- FTP control: `2121 -> 21`.
- FTP pasivo: `21000-21010 -> 21000-21010`.
- Static site: `8082 -> 8080`.
- Portainer: `9000 -> 9000`.

Nota: el puerto HTTPS en VM final suele ser `443`, pero en este entorno usas `9443`.

---

## 5) Makefile (operacion diaria)
Archivo: `Makefile`

Targets clave:
- `make up`: levanta servicios sin rebuild.
- `make build`: rebuild + up.
- `make down`: baja stack.
- `make re`: down + build.
- `make ps`: estado de contenedores.
- `make logs`: logs de todo.
- `make status`: checklist orientado a evaluacion.
- `make fclean`: baja stack y borra imagenes/volumenes del compose.
- `make clean-evaluate`: limpieza total estilo evaluador (agresiva).

---

## 6) Mandatory en detalle

## 6.1 MariaDB
Archivos:
- `srcs/requirements/mariadb/Dockerfile`
- `srcs/requirements/mariadb/tools/setup.sh`

### Que hace
- Instala `mariadb-server` y `mariadb-client`.
- En runtime:
  - prepara permisos/socket/datadir,
  - inicializa DB en primer arranque,
  - garantiza en cada arranque DB y usuarios (idempotencia),
  - arranca `mysqld` en foreground.

### Puntos de defensa
- Diferencia build-time vs run-time.
- Por que usar `IF NOT EXISTS` y `FLUSH PRIVILEGES`.
- Por que `exec mysqld ...` como PID 1.

## 6.2 WordPress
Archivos:
- `srcs/requirements/wordpress/Dockerfile`
- `srcs/requirements/wordpress/tools/setup.sh`

### Que hace
- Instala PHP-FPM + MySQL extension + cliente MariaDB + curl.
- Configura PHP-FPM por TCP `0.0.0.0:9000`.
- En runtime:
  - espera DB,
  - asegura WP-CLI,
  - descarga core si falta,
  - crea `wp-config.php` si falta,
  - instala WordPress solo una vez,
  - crea usuario normal,
  - arranca `php-fpm7.4 -F`.

### Puntos de defensa
- Por que WordPress no incluye NGINX.
- Idempotencia de `wp core is-installed`.
- Distincion admin vs usuario normal.

## 6.3 NGINX principal
Archivos:
- `srcs/requirements/nginx/Dockerfile`
- `srcs/requirements/nginx/conf/nginx.conf`
- `srcs/requirements/nginx/tools/setup.sh`

### Que hace
- Instala NGINX + OpenSSL + netcat.
- `setup.sh`:
  - genera certificado autofirmado si falta,
  - espera `wordpress:9000`,
  - arranca NGINX (`daemon off`).
- `nginx.conf`:
  - escucha `443 ssl`,
  - TLS `v1.2/v1.3`,
  - root en volumen WordPress,
  - `try_files` para front-controller,
  - FastCGI a `wordpress:9000`.

### Puntos de defensa
- HTTP no expuesto en mandatory.
- Funcion de `fastcgi_pass` y `SCRIPT_FILENAME`.
- Justificacion de cert self-signed.

---

## 7) Bonus en detalle

## 7.1 Redis
Archivos:
- `srcs/requirements/redis/Dockerfile`
- `srcs/requirements/redis/tools/setup.sh`

### Que hace
- Contenedor Redis dedicado para cache de WordPress.
- Arranque simple: `redis-server --bind 0.0.0.0 --port 6379 --protected-mode no`.

### Integracion WP
- En setup de WordPress se configuran constantes Redis.
- Se instala/activa plugin `redis-cache`.

## 7.2 Adminer
Archivos:
- `srcs/requirements/adminer/Dockerfile`
- `srcs/requirements/adminer/tools/setup.sh`

### Que hace
- Descarga `latest.php` de Adminer a `/var/www/html/index.php`.
- Sirve con `php -S 0.0.0.0:8080 -t /var/www/html`.
- Acceso host por `http://127.0.0.1:8081`.

## 7.3 FTP (vsftpd)
Archivos:
- `srcs/requirements/ftp/Dockerfile`
- `srcs/requirements/ftp/tools/setup.sh`
- `srcs/requirements/ftp/conf/vsftpd.conf`

### Que hace
- Crea usuario FTP desde `.env`.
- Renderiza config desde plantilla (`__FTP_ROOT__`, `__FTP_PASV_ADDRESS__`).
- Modo pasivo listo para Docker.
- Expone control + puertos pasivos.

### Punto clave
Si login funciona pero transferencias fallan, revisar PASV + puertos.

## 7.4 Static Site
Archivos:
- `srcs/requirements/static_site/Dockerfile`
- `srcs/requirements/static_site/conf/nginx.conf`
- `srcs/requirements/static_site/website/index.html`

### Que hace
- Servicio NGINX independiente para web estatica bonus.
- Escucha en `8080` interno, publicado como `8082` en host.
- Sirve `index.html` desde `/var/www/static`.

## 7.5 Portainer (free choice)
Archivos:
- `srcs/requirements/portainer/Dockerfile`
- `srcs/requirements/portainer/tools/setup.sh`
- `srcs/secrets/portainer_admin_password`

### Que hace
- Descarga binario oficial de Portainer CE.
- Requiere secret de password admin para arrancar.
- Monta `docker.sock` + volumen `/data`.

### Punto de seguridad
No poner comentarios dentro del archivo secreto; solo valor puro.

---

## 8) Variables de entorno (.env)
Archivo: `srcs/.env`

Grupos actuales:
- Dominio: `DOMAIN_NAME`.
- MariaDB: `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`.
- WordPress: `WP_URL`, `WP_TITLE`, `WP_ADMIN_*`, `WP_USER_*`.
- FTP: `FTP_USER`, `FTP_PASSWORD`.

Regla practica:
- `.env` para desarrollo local.
- `secrets` para credenciales sensibles en entornos mas duros.

---

## 9) Secrets actuales y futuros
Carpeta: `srcs/secrets/`

Actual:
- `portainer_admin_password`.

Sugeridos a futuro:
- `mariadb_root_password`
- `wordpress_db_password`
- `wp_admin_password`
- `wp_user_password`
- `ftp_password`
- `wp_auth_keys`

Ya existe documentacion especifica en:
- `srcs/secrets/README.md`

---

## 10) Persistencia y almacenamiento
Volumenes compose:
- `mariadb_data`: datos DB.
- `wordpress_data`: sitio WordPress (core, uploads, plugins, config).
- `portainer_data`: datos panel Portainer.

Que debes defender:
- Down/up no borra datos.
- Rebuild de imagen no implica perder contenido si volumen se mantiene.

---

## 11) Red Docker y DNS interno
Red definida: `inception` (bridge).

Ventaja:
- Los servicios se ven por nombre (`mariadb`, `wordpress`, `redis`) sin IP fija.

Esto simplifica:
- `fastcgi_pass wordpress:9000`
- conexiones DB en `mariadb`
- Redis host `redis`

---

## 12) Pruebas recomendadas (mandatory)

## 12.1 Levantar y verificar estado
```bash
cd ~/Desktop/Icepcion/intra3
make build
make ps
```

## 12.2 HTTPS OK y HTTP bloqueado
```bash
curl -kI https://127.0.0.1:9443 | head -n 10
curl -I http://127.0.0.1:80 | head -n 10
```

## 12.3 WordPress funcional
- Entrar en `https://127.0.0.1:9443/wp-login.php`.
- Login con admin y usuario normal.
- Editar pagina/comentar para comprobar funcionalidad.

## 12.4 MariaDB funcional
```bash
docker exec -it mariadb sh -lc 'mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"'
docker exec -it mariadb sh -lc 'mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;"'
```

## 12.5 Persistencia
1. Cambiar algo visible en WordPress.
2. `make down && make up`.
3. Confirmar que el cambio sigue.

---

## 13) Pruebas recomendadas (bonus)

## 13.1 Redis
```bash
docker compose -f srcs/docker-compose.yml exec -T wordpress sh -lc 'wp redis status --allow-root --path=/var/www/html'
```

## 13.2 Adminer
- Abrir `http://127.0.0.1:8081`.
- Login a `mariadb` con usuario/clave correspondiente.

## 13.3 FTP
```bash
curl -v --ftp-pasv ftp://ftpuser:ftp_pass_42@127.0.0.1:2121/ --max-time 15
```
Subida prueba:
```bash
echo "ftp test $(date)" > /tmp/ftp_test.txt
curl --ftp-pasv -T /tmp/ftp_test.txt ftp://ftpuser:ftp_pass_42@127.0.0.1:2121/uploads/
```

## 13.4 Static site
- Abrir `http://127.0.0.1:8082`.

## 13.5 Portainer
- Abrir `http://127.0.0.1:9000`.
- Inicializar/entrar con password definida por secret.

---

## 14) Errores comunes y diagnostico rapido

1. **WordPress reinicia en bucle**
- Revisar logs de `wordpress`.
- Confirmar DB/user creados en MariaDB.
- Verificar variables `.env` coherentes.

2. **MariaDB arranca pero WordPress no conecta**
- Revisar `MYSQL_*` en `.env`.
- Confirmar que `wp-config.php` tenga host `mariadb`.

3. **NGINX devuelve 502**
- WordPress/PHP-FPM no esta listo.
- Verificar que `wordpress:9000` este escuchando.

4. **FTP login ok pero LIST/STOR falla**
- Error tipico de modo pasivo.
- Revisar PASV address y puertos `21000-21010`.

5. **Portainer no arranca**
- Secret ausente/mal montado.
- `docker.sock` no montado en ruta correcta.

---

## 15) Estrategia de defensa (recomendada)
Orden sugerido al presentar:
1. Explicar arquitectura general (mandatory primero).
2. Mostrar `docker-compose.yml` y red/volumenes.
3. Probar HTTPS y login WordPress.
4. Probar persistencia.
5. Mostrar MariaDB no vacia.
6. Solo despues, enseñar bonus uno por uno.

Mensaje clave:
- Infraestructura modular.
- Servicios aislados.
- Persistencia real.
- Idempotencia en scripts de arranque.

---

## 16) Conclusiones finales
Este proyecto esta estructurado para ser:
- Reproducible: `make build` levanta todo de forma consistente.
- Explicable: cada servicio tiene Dockerfile + setup + config claros.
- Escalable: bonus separados, faciles de activar y defender.
- Mantenible: comentarios extensos en archivos criticos.

Si mantienes esta estructura, en evaluacion puedes defender no solo que "funciona",
sino por que funciona y como lo depurarias si algo falla.

---

## 17) Marco teorico esencial (basado en subject + ng_3)

## 17.1 Docker no es una VM
Una VM virtualiza hardware completo (kernel propio, init propio, sistema operativo completo).  
Un contenedor Docker virtualiza a nivel de sistema operativo (namespaces, cgroups) y comparte kernel del host.

Implicaciones practicas:
- Contenedor arranca mucho mas rapido.
- Menor consumo de RAM/disco.
- Menor aislamiento que una VM completa (por compartir kernel).
- Modelo ideal para servicios desacoplados.

Defensa corta:
"Una VM emula una maquina completa; un contenedor empaqueta un proceso con sus dependencias. En Inception necesito separar servicios, no crear sistemas completos por cada uno."

## 17.2 Imagen vs contenedor
- Imagen: plantilla inmutable (capas + metadata).
- Contenedor: instancia en ejecucion de una imagen.

Con Docker Compose:
- Defines topologia de multiples servicios.
- Gestionas ciclo de vida con una sola declaracion.
- Aseguras repetibilidad (mismo resultado en cada `up --build`).

## 17.3 Por que PID 1 importa
En contenedores, el proceso principal (PID 1):
- Define vida/muerte del contenedor.
- Debe recibir señales de parada para shutdown limpio.

Por eso usas `exec` en scripts:
- `exec mysqld ...`
- `exec php-fpm7.4 -F`
- `exec nginx -g "daemon off;"`
- `exec redis-server ...`

Y por eso el subject prohibe parches tipo `tail -f` o `sleep infinity`.

## 17.4 Daemon en foreground
Buena practica Docker:
- No mezclar `daemon + shell`.
- Ejecutar proceso real en foreground.

Ventajas:
- Logs directos.
- Señales correctas.
- Reinicios previsibles con `restart:`.

## 17.5 Idempotencia
Idempotencia = ejecutar n veces sin romper estado.

Aplicado en tu proyecto:
- MariaDB crea DB/user con `IF NOT EXISTS`.
- WordPress verifica `wp core is-installed`.
- Usuario normal se crea solo si no existe.
- Redis/Adminer/Static no reprovisionan de forma destructiva.

---

## 18) Comparativas teoricas pedidas por el subject

## 18.1 VM vs Docker
VM:
- SO completo por instancia.
- Mayor aislamiento y overhead.
- Arranques mas lentos.

Docker:
- Aislamiento de procesos compartiendo kernel.
- Ligero y rapido.
- Ideal para microservicios.

## 18.2 Secrets vs Environment Variables
Env vars (`.env`):
- Simples y rapidas para desarrollo.
- Riesgo de filtracion en inspecciones/logs.

Secrets:
- Montados como archivo en `/run/secrets/...`.
- Menor exposicion accidental.
- Mejor para credenciales sensibles reales.

Diseño recomendado:
- Local: `.env`.
- Entorno mas estricto: secrets.

## 18.3 Docker network bridge vs host network
Bridge (tu caso):
- DNS interno entre servicios.
- Aislamiento y control de puertos.
- Topologia limpia y portable.

Host (prohibido en Inception):
- Sin aislamiento de red entre host/contenedor.
- Menos control de superficie expuesta.

## 18.4 Volumes vs Bind mounts
Named volumes:
- Gestionados por Docker.
- Persistentes y portables.
- Recomendados en subject para DB/web files.

Bind mounts:
- Dependientes de ruta host.
- Utiles en desarrollo, menos portables.

---

## 19) Teoria de red aplicada a tu stack

### 19.1 DNS interno
En red bridge, cada contenedor resuelve por nombre:
- `mariadb`
- `wordpress`
- `redis`

Sin IP hardcodeada.

### 19.2 Flujo web principal
1. Cliente -> NGINX por HTTPS.
2. NGINX intenta recurso estatico (`try_files`).
3. Si es PHP, FastCGI a `wordpress:9000`.
4. WordPress consulta MariaDB.

### 19.3 Flujo cache Redis
1. WordPress consulta clave cache.
2. Si hit, evita query DB.
3. Si miss, consulta DB y guarda en Redis.

Resultado: menor latencia y menos carga en MariaDB.

---

## 20) Teoria de seguridad minima

## 20.1 Principio de minimo privilegio funcional
Separacion de responsabilidades:
- NGINX: entrada TLS.
- WordPress: aplicacion PHP.
- MariaDB: datos.

Esto limita impacto de fallos y mejora mantenibilidad.

## 20.2 Exposicion minima de puertos
Mandatory:
- NGINX es entrypoint principal del sitio.

Bonus:
- Se publican solo puertos estrictamente necesarios para cada servicio.

## 20.3 Credenciales fuera de Dockerfile
Nunca meter passwords en Dockerfile:
- quedan en capas de imagen,
- son faciles de extraer.

Usar `.env`/secrets.

## 20.4 TLS en evaluacion
- Debe demostrarse TLSv1.2/v1.3.
- Certificado puede ser self-signed.
- HTTP del sitio principal no debe ser via 80 publico.

---

## 21) Teoria de evaluacion (ng_3)
Puntos de corte directos si fallan:
- `network: host` o `links`.
- comandos hacky/infinite loop en Dockerfiles/scripts.
- mandatory no funcional.
- WordPress mostrando instalador.
- root DB sin password.

Puntos obligatorios de demostracion:
- HTTPS funcional.
- HTTP bloqueado para sitio principal.
- WordPress admin + usuario normal.
- MariaDB no vacia.
- Persistencia tras reinicio.

Regla bonus:
- Solo cuenta si mandatory esta perfecto.

---

## 22) Observabilidad y depuracion teorica
Secuencia profesional:
1. Estado (`docker compose ps`).
2. Logs (`docker compose logs ...`).
3. Prueba interna (`docker exec ...`).
4. Prueba externa (`curl`, browser, ftp client).

Checklist por capas:
- Red (puertos/DNS).
- Proceso (PID 1 vivo).
- Datos (volumen montado).
- Aplicacion (respuesta funcional).

---

## 23) Preparacion para mini-cambio en defensa
El subject contempla modificaciones pequenas en vivo.
Para estar listo:
- Ubica rapidamente donde vive cada cambio:
  - Puerto: compose/conf.
  - Credencial: `.env`/secrets.
  - Arranque: `setup.sh`.
  - Dependencia: Dockerfile.
- Reconstruye solo servicio afectado.
- Verifica con 1-2 comandos concretos.

---

## 24) Requisitos documentales teoricos (subject actual)
Ademas de codigo funcional, se pide documentacion:
- `README.md` (en ingles): descripcion, instrucciones, recursos, uso de AI.
- `USER_DOC.md`: guia operativa para usuario/admin.
- `DEV_DOC.md`: guia tecnica para desarrollo/setup.

Lectura de fondo:
No basta con que funcione; debe ser explicable, mantenible y defendible.
