# ==========================================================
# Makefile - Inception
# Proyecto Inception - 42
#
# OBJETIVO:
#   1) Simplificar comandos de Docker Compose
#   2) Centralizar targets de build, logs, limpieza y debug
#   3) Ofrecer ayudas de comprobacion para la evaluacion
#
# NOTA:
#   - Este proyecto publica HTTPS directamente en 443
#   - HOST y PORT pueden sobreescribirse al invocar make
# ==========================================================

# -----------------------------------------------
# Docker Compose
# -----------------------------------------------

# Carpeta donde está docker-compose.yml
COMPOSE_DIR = srcs

# Comando docker compose ejecutado apuntando al compose dentro de srcs
DC = docker compose -f $(COMPOSE_DIR)/docker-compose.yml

# -----------------------------------------------
# URL de prueba (para `make status`)
#
# HOST: por defecto localhost
# PORT: por defecto 443
# -----------------------------------------------
HOST ?= 127.0.0.1
PORT ?= 443
URL  = https://$(HOST):$(PORT)

# -----------------------------------------------
# Targets
# -----------------------------------------------
.PHONY: all prepare-data up down build re ps logs nginx-logs wp-logs db-logs exec-nginx exec-wp exec-db status evaluate clean fclean reset-data clean-evaluate

# Target por defecto
all: up

# Directorios persistentes requeridos por el subject
prepare-data:
	mkdir -p /home/aurodrig/data/mariadb
	mkdir -p /home/aurodrig/data/wordpress

# Levantar servicios (sin rebuild)
up: prepare-data
	$(DC) up -d

# Levantar servicios forzando rebuild de imágenes
build: prepare-data
	$(DC) up -d --build

# Parar y borrar contenedores/red (NO borra datos del host en bind mounts)
down:
	$(DC) down

# Reinicio completo: down + build
re: down build

# Estado de contenedores del compose
ps:
	$(DC) ps

# Logs de todo (follow)
logs:
	$(DC) logs -f

# Logs por servicio (útil para debug)
nginx-logs:
	$(DC) logs -f nginx

wp-logs:
	$(DC) logs -f wordpress

db-logs:
	$(DC) logs -f mariadb

# Entrar a los contenedores (shell interactivo)
exec-nginx:
	docker exec -it nginx bash || docker exec -it nginx sh

exec-wp:
	docker exec -it wordpress bash || docker exec -it wordpress sh

exec-db:
	docker exec -it mariadb bash || docker exec -it mariadb sh

# -----------------------------------------------
# Status "modo evaluador"
# -----------------------------------------------
status:
	@echo "=============================================="
	@echo " Inception - STATUS (modo evaluador)"
	@echo " URL prueba: $(URL)"
	@echo "----------------------------------------------"
	@echo " Tip:"
	@echo "   local:  make status"
	@echo "   custom: make status HOST=<host> PORT=<port>"
	@echo "=============================================="
	@echo ""
	@echo "1) Servicios (docker compose ps):"
	@$(DC) ps
	@echo ""
	@echo "2) Puertos expuestos (solo nginx deberia mostrar puertos):"
	@docker ps --format 'table {{.Names}}\t{{.Ports}}' | (head -n 1; grep -E 'nginx|mariadb|wordpress' || true)
	@echo ""
	@echo "3) Mounts MariaDB (debe apuntar a /home/<login>/data/mariadb):"
	@docker inspect mariadb --format '{{range .Mounts}}{{println .Type " - " .Source " -> " .Destination}}{{end}}' || true
	@echo ""
	@echo "4) Mounts WordPress (debe apuntar a /home/<login>/data/wordpress):"
	@docker inspect wordpress --format '{{range .Mounts}}{{println .Type " - " .Source " -> " .Destination}}{{end}}' || true
	@echo ""
	@echo "5) Test HTTPS (cabeceras):"
	@curl -kI $(URL) | head -n 20 || true
	@echo ""
	@echo "6) Test instalador (debe responder 200/302):"
	@curl -kI $(URL)/wp-admin/install.php | head -n 20 || true
	@echo ""
	@echo "✅ Si ves 200/302 y los mounts apuntan a /home/<login>/data, vas bien."

# Checklist rapido basado en la evaluacion
evaluate:
	./scripts/evaluate.sh

# -----------------------------------------------
# Limpiezas
# -----------------------------------------------

# Limpieza “suave”
clean: down

# Limpieza “fuerte” (¡¡cuidado!!)

fclean:
	$(DC) down --rmi all -v --remove-orphans

# Resetea la persistencia real del host (¡¡cuidado!!)

reset-data:
	docker run --rm --entrypoint sh -v /home/aurodrig/data:/data srcs-nginx -lc 'rm -rf /data/wordpress/* /data/wordpress/.[!.]* /data/wordpress/..?* /data/mariadb/* /data/mariadb/.[!.]* /data/mariadb/..?*'

# Limpieza total estilo evaluador (borra TODO en Docker)
clean-evaluate:
	docker stop $$(docker ps -qa) || true
	docker rm $$(docker ps -qa) || true
	docker rmi -f $$(docker images -qa) || true
	docker volume rm $$(docker volume ls -q) || true
	docker network rm $$(docker network ls -q) 2>/dev/null || true
