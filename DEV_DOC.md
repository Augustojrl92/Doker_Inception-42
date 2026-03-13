# DEV_DOC

This document describes how a developer can set up and manage the project.

## Prerequisites
- Linux VM (as required by the subject)
- Docker Engine and Docker Compose
- Make

## Repository layout
- Makefile at root
- srcs/ for docker-compose.yml and requirements
- secrets/ for local credentials (optional, if using Docker secrets)

## Build and launch
From scratch, prepare host data directories:
```
mkdir -p /home/<login>/data/mariadb /home/<login>/data/wordpress
```

Review configuration:
- `srcs/.env`
- optional local files in `secrets/`

From the project root:
```
make build
```

## Common management commands
- List containers: `make ps`
- Tail logs: `make logs`
- Stop services: `make down`
- Rebuild: `make build`

## Volumes and persistence
Data is stored on the host in:
- /home/<login>/data/mariadb
- /home/<login>/data/wordpress

These named volumes are backed by host paths under `/home/<login>/data` to preserve data across restarts.

## Where configuration lives
- docker-compose.yml: `srcs/docker-compose.yml`
- NGINX config: `srcs/requirements/nginx/conf/nginx.conf`
- MariaDB init: `srcs/requirements/mariadb/tools/setup.sh`
- WordPress init: `srcs/requirements/wordpress/tools/setup.sh`

## Troubleshooting tips
- Check container status: `make ps`
- Inspect logs for errors: `make logs`
- If WordPress shows install.php, review the wp setup script and env vars.
- If MariaDB fails to start, verify permissions on /home/<login>/data/mariadb.
