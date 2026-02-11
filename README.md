*This project has been created as part of the 42 curriculum by aurodrig.*

# Description
This project builds a small Docker-based infrastructure for the 42 Inception subject.
The stack includes MariaDB, WordPress (php-fpm), and NGINX with TLS. Containers are
built from custom Dockerfiles and connected through a dedicated Docker network.
Data is persisted on the host under `/home/<login>/data`.

## Project overview and design choices
- Docker is used instead of full VMs to keep services isolated, lightweight and reproducible.
- Each service has its own container and its own Dockerfile.
- NGINX is the only public entrypoint and exposes HTTPS only.
- WordPress uses php-fpm (no nginx inside the WP container).
- MariaDB runs as a dedicated database container.
- Volumes map to host paths in /home/<login>/data for persistence.

## Oral explanations (evaluation)
### How Docker and Docker Compose work
Docker builds images (immutable templates) and runs containers from them. Containers share the host kernel but remain isolated.
Docker Compose defines multiple services in a single file and orchestrates build/run, networking, and volumes as one stack.

### Image usage with and without Compose
Without Compose, you run each container manually with `docker run` and manage networks/volumes yourself.
With Compose, the file declares all services, dependencies, networks and volumes, and `docker compose up` manages them together.

### Benefits of Docker vs VMs
VMs run full operating systems and are heavier in CPU/RAM/disk. Docker shares the host kernel, starts faster,
uses fewer resources, and makes service stacks reproducible.

### Why this directory structure
The subject requires `srcs/` to contain all configuration, and a root `Makefile` to orchestrate the build.
This separation keeps code and config organized, and makes evaluation/review predictable.

## Sources included in this repository
- `Makefile` at repository root for lifecycle commands.
- `srcs/docker-compose.yml` for service orchestration.
- `srcs/requirements/nginx/` for TLS web server container.
- `srcs/requirements/wordpress/` for php-fpm + WordPress bootstrap.
- `srcs/requirements/mariadb/` for database bootstrap.
- `secrets/` for local sensitive files (kept out of git).

## Comparisons
- Virtual Machines vs Docker:
  VM runs a full OS per service; Docker shares the host kernel and is lighter/faster.
- Secrets vs Environment Variables:
  Secrets are safer for sensitive data; env vars are simpler but must be kept out of git.
- Docker Network vs Host Network:
  Docker network isolates containers; host network bypasses isolation and is forbidden.
- Docker Volumes vs Bind Mounts:
  Volumes are managed by Docker; bind mounts map explicit host paths.

# Instructions
## Requirements
- Docker Engine and Docker Compose
- A Linux VM (as required by the subject)

## Build and run
From the project root:
```
make build
```

## Stop
```
make down
```

## Logs
```
make logs
```

## Access
- In campus without sudo: https://localhost:8443
- In the final VM: https://<login>.42.fr (port 443 only)

## Validation quick checks
```bash
make ps
curl -kI https://localhost:8443 | head -n 10
docker exec wordpress wp user list --allow-root --path=/var/www/html
```

# Resources
- Docker docs: https://docs.docker.com/
- Compose docs: https://docs.docker.com/compose/
- MariaDB docs: https://mariadb.com/kb/en/documentation/
- NGINX docs: https://nginx.org/en/docs/
- WordPress docs: https://wordpress.org/documentation/
- WP-CLI docs: https://developer.wordpress.org/cli/commands/

## AI usage
AI was used to draft explanations, review the subject requirements, and help improve
scripts (idempotency, comments, and troubleshooting). All generated content was
reviewed and adjusted before integration.
