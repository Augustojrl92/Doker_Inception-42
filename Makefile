# =====================================================
# Makefile - Inception (42)
#
# Objetivo:
# - Simplificar comandos de Docker Compose
# - Targets típicos: up, down, build, logs, clean...
# - Target status: checklist estilo evaluador
#
# Nota campus:
# - Docker rootless suele impedir puertos < 1024 (como 443).
# - Por eso en campus publicamos 8443->443.
# - En la VM final podrás usar 443->443.
# =====================================================

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
# PORT:
# - campus: 8443 (porque no deja 443)
# - VM final: usa PORT=443
# -----------------------------------------------
HOST ?= 127.0.0.1
PORT ?= 8443
URL  = https://$(HOST):$(PORT)

# -----------------------------------------------
# Targets
# -----------------------------------------------
.PHONY: all prepare-data up down build re ps logs nginx-logs wp-logs db-logs exec-nginx exec-wp exec-db status evaluate clean fclean clean-evaluate

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
	@echo "   campus: make status        (PORT=8443)"
	@echo "   VM:     make status PORT=443"
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
# - Borra contenedores, imágenes y volúmenes del compose
# - NO borra /home/<login>/data (bind mounts) a menos que tú los borres a mano
fclean:
	$(DC) down --rmi all -v --remove-orphans

# Limpieza total estilo evaluador (borra TODO en Docker)
clean-evaluate:
	docker stop $$(docker ps -qa) || true
	docker rm $$(docker ps -qa) || true
	docker rmi -f $$(docker images -qa) || true
	docker volume rm $$(docker volume ls -q) || true
	docker network rm $$(docker network ls -q) 2>/dev/null || true
