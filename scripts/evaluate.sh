#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
COMPOSE_FILE="$ROOT_DIR/srcs/docker-compose.yml"
ENV_FILE="$ROOT_DIR/srcs/.env"

HOST="${HOST:-127.0.0.1}"
HTTPS_PORT="${PORT:-443}"
HTTP_PORT="${HTTP_PORT:-80}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

section() {
  printf '\n== %s ==\n' "$1"
}

run_check() {
  label="$1"
  shift

  if "$@"; then
    printf '[OK] %s\n' "$label"
  else
    printf '[KO] %s\n' "$label"
  fi
}

check_absent_pattern() {
  pattern="$1"
  target="$2"

  if grep -R -E --line-number -- "$pattern" "$target" >/dev/null 2>&1; then
    return 1
  fi

  return 0
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

need_cmd docker
need_cmd curl
need_cmd openssl
need_cmd grep
need_cmd sed

section "Static checks"
run_check "compose file exists" test -f "$COMPOSE_FILE"
run_check "no network_mode: host" check_absent_pattern 'network_mode:[[:space:]]*host' "$COMPOSE_FILE"
run_check "no links" check_absent_pattern '^[[:space:]]*links:' "$COMPOSE_FILE"
run_check "no --link in compose/scripts" check_absent_pattern '--link' "$ROOT_DIR/srcs"
run_check "no --link in Makefile" check_absent_pattern '--link' "$ROOT_DIR/Makefile"
run_check "no tail -f / sleep infinity / while true" check_absent_pattern 'tail -f|sleep infinity|while true' "$ROOT_DIR/srcs"

section "Compose services"
docker compose -f "$COMPOSE_FILE" ps

section "Network"
docker network ls | sed -n '1,20p'

section "Ports"
docker ps --format 'table {{.Names}}\t{{.Ports}}'

section "Mounts"
docker inspect mariadb wordpress nginx --format '{{.Name}}|{{range .Mounts}}{{.Type}}:{{.Name}}:{{.Source}}->{{.Destination}} {{end}}'

section "Volume backing paths"
docker volume inspect mariadb_data wordpress_data --format '{{.Name}}|device={{if .Options}}{{index .Options "device"}}{{end}}|mountpoint={{.Mountpoint}}'

section "HTTPS"
curl -kI "https://$HOST:$HTTPS_PORT" | sed -n '1,12p'

section "HTTP should fail"
if curl -I --max-time 5 "http://$HOST:$HTTP_PORT" >/tmp/inception_http_check 2>&1; then
  printf '[KO] HTTP responded on %s:%s\n' "$HOST" "$HTTP_PORT"
  sed -n '1,12p' /tmp/inception_http_check
else
  printf '[OK] HTTP is not exposed on %s:%s\n' "$HOST" "$HTTP_PORT"
  sed -n '1,12p' /tmp/inception_http_check || true
fi

section "TLS"
printf 'TLSv1.2\n'
echo | openssl s_client -connect "$HOST:$HTTPS_PORT" -tls1_2 2>/dev/null | sed -n '1,12p'
printf '\nTLSv1.3\n'
echo | openssl s_client -connect "$HOST:$HTTPS_PORT" -tls1_3 2>/dev/null | sed -n '1,12p'

section "MariaDB"
if docker exec mariadb sh -lc "mariadb -u root -e 'SHOW DATABASES;'" >/tmp/inception_db_nopass 2>&1; then
  printf '[KO] root login without password should fail\n'
  sed -n '1,12p' /tmp/inception_db_nopass
else
  printf '[OK] root login without password fails\n'
  sed -n '1,12p' /tmp/inception_db_nopass || true
fi

if [ -n "${MYSQL_ROOT_PASSWORD:-}" ]; then
  docker exec mariadb sh -lc "mariadb -u root -p\"$MYSQL_ROOT_PASSWORD\" -e 'SHOW DATABASES;'"
else
  printf 'MYSQL_ROOT_PASSWORD not loaded from %s; skipping authenticated MariaDB check\n' "$ENV_FILE"
fi

section "WordPress"
docker exec wordpress sh -lc "wp core is-installed --allow-root --path=/var/www/html"
docker exec wordpress sh -lc "wp user list --allow-root --path=/var/www/html --fields=user_login,roles --format=table"

section "Summary"
printf 'Review the volume paths above carefully: the subject requires named volumes whose data is stored inside /home/<login>/data on the host.\n'
