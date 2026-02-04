# USER_DOC

This document explains how an end user or administrator can operate the stack.

## Services provided
- NGINX: HTTPS entrypoint (TLS 1.2/1.3).
- WordPress: application (php-fpm only).
- MariaDB: database for WordPress.

## Start and stop
From the project root:
```
make build
```
Stop containers:
```
make down
```

## Access the website and admin panel
- Campus (no sudo): https://localhost:8443
- Final VM: https://<login>.42.fr (port 443 only)

Admin panel:
```
https://<host>/wp-admin
```

## Credentials and secrets
- Current setup reads credentials from `srcs/.env`.
- Keep `.env` and `secrets/` out of git.
- If you migrate to Docker secrets, store `db_password` and `db_root_password` in `secrets/` and update compose/scripts accordingly.

## Check services status
```
make ps
```

Check logs:
```
make logs
```

Verify HTTPS:
```
curl -kI https://localhost:8443 | head -n 10
```

Verify WordPress is installed:
```
docker exec wordpress wp core is-installed --allow-root --path=/var/www/html
```

## Data persistence
- MariaDB data: /home/<login>/data/mariadb
- WordPress files: /home/<login>/data/wordpress
