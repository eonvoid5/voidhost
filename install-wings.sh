#!/bin/bash
set -e

# VOIDHOST Wings Installer
# Rebranded from the JTG Wings Docker installer.

echo "========================================="
echo "          VOIDHOST WINGS"
echo "      Minecraft Server Node"
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

mkdir -p /srv/voidhost/wings
cd /srv/voidhost/wings

cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  wings:
    image: ghcr.io/pterodactyl/wings:v1.6.1
    restart: always
    networks:
      - wings0
    ports:
      - "8080:8080"
      - "2022:2022"
      - "443:443"
    tty: true
    environment:
      TZ: "UTC"
      WINGS_UID: 988
      WINGS_GID: 988
      WINGS_USERNAME: voidhost
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/containers/:/var/lib/docker/containers/
      - /etc/pterodactyl/:/etc/pterodactyl/
      - /var/lib/pterodactyl/:/var/lib/pterodactyl/
      - /var/log/pterodactyl/:/var/log/pterodactyl/
      - /tmp/pterodactyl/:/tmp/pterodactyl/
      - /etc/ssl/certs:/etc/ssl/certs:ro

networks:
  wings0:
    name: wings0
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.0.0/16
    driver_opts:
      com.docker.network.bridge.name: wings0
EOF

$COMPOSE up -d

echo ""
echo "VOIDHOST Wings installation complete."
echo "Node ports: 8080, 2022, 443"
