#!/usr/bin/env bash
set -euo pipefail

REPO_TARBALL="https://github.com/eonvoid5/voidhost/archive/refs/heads/main.tar.gz"
APP_DIR="/var/www/voidhost"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root: sudo bash install.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx curl ca-certificates tar

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
curl -fsSL "$REPO_TARBALL" | tar -xz --strip-components=1 -C "$APP_DIR"
chown -R www-data:www-data "$APP_DIR"

cat > /etc/nginx/sites-available/voidhost <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/voidhost;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/voidhost /etc/nginx/sites-enabled/voidhost
nginx -t
systemctl enable nginx
systemctl restart nginx

IP=$(hostname -I | awk '{print $1}')
echo
echo "========================================"
echo " VOID HOSTING INSTALLED SUCCESSFULLY"
echo "========================================"
echo "Website: http://$IP"
echo "App directory: $APP_DIR"
echo "Port: 80 (Nginx)"
echo "========================================"
