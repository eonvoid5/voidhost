#!/bin/bash
set -e

# VOIDHOST Panel Installer
# Rebranded from the JTG Docker installer.

echo "========================================="
echo "          VOIDHOST PANEL"
echo "   Minecraft Hosting Control Panel"
echo "========================================="

if [ "$(id -u)" != "0" ]; then
  echo "This installer must be run as root."
  exit 1
fi

command -v docker >/dev/null 2>&1 || {
  echo "Docker is required. Install Docker first."
  exit 1
}

if command -v docker compose >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  echo "Docker Compose is required."
  exit 1
fi

mkdir -p /srv/voidhost/panel
cd /srv/voidhost/panel

cat > docker-compose.yml <<'EOF'
version: '3.8'

x-common:
  database: &db-environment
    MYSQL_PASSWORD: "CHANGE_ME"
    MYSQL_ROOT_PASSWORD: "CHANGE_ME_TOO"
  panel: &panel-environment
    APP_NAME: "VOIDHOST"
    APP_URL: "https://voidhost.example.com"
    APP_TIMEZONE: "UTC"
    APP_SERVICE_AUTHOR: "noreply@voidhost.example.com"
    TRUSTED_PROXIES: "*"
  mail: &mail-environment
    MAIL_FROM: "noreply@voidhost.example.com"
    MAIL_DRIVER: "smtp"
    MAIL_HOST: "mail"
    MAIL_PORT: "1025"
    MAIL_USERNAME: ""
    MAIL_PASSWORD: ""
    MAIL_ENCRYPTION: "true"

services:
  database:
    image: mariadb:10.5
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - "./data/database:/var/lib/mysql"
    environment:
      <<: *db-environment
      MYSQL_DATABASE: "panel"
      MYSQL_USER: "pterodactyl"

  cache:
    image: redis:alpine
    restart: always

  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: always
    ports:
      - "8030:80"
      - "4433:443"
    links:
      - database
      - cache
    volumes:
      - "./data/var:/app/var"
      - "./data/nginx:/etc/nginx/http.d"
      - "./data/certs:/etc/letsencrypt"
      - "./data/logs:/app/storage/logs"
    environment:
      <<: [*panel-environment, *mail-environment]
      DB_PASSWORD: "CHANGE_ME"
      APP_ENV: "production"
      APP_ENVIRONMENT_ONLY: "false"
      CACHE_DRIVER: "redis"
      SESSION_DRIVER: "redis"
      QUEUE_DRIVER: "redis"
      REDIS_HOST: "cache"
      DB_HOST: "database"
      DB_PORT: "3306"

networks:
  default:
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF

mkdir -p ./data/{database,var,nginx,certs,logs}
$COMPOSE up -d

echo ""
echo "VOIDHOST Panel installation complete."
echo "Panel: http://YOUR_SERVER_IP:8030"
echo ""
echo "Create an admin user with:"
echo "$COMPOSE run --rm panel php artisan p:user:make"
