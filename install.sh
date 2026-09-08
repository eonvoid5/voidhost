#!/usr/bin/env bash
set -euo pipefail

REPO_TARBALL="https://github.com/eonvoid5/voidhost/archive/refs/heads/main.tar.gz"
APP_DIR="/var/www/voidhost"
PORT="8080"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run: sudo bash install.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/4] Installing required packages..."
apt-get update -y
apt-get install -y --no-install-recommends nginx curl ca-certificates tar

echo "[2/4] Downloading VOID HOSTING..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
curl -fsSL "$REPO_TARBALL" | tar -xz --strip-components=1 -C "$APP_DIR"
chown -R www-data:www-data "$APP_DIR"

# The VPS/container environment may deny binding to privileged port 80.
# Serve VOID HOSTING through Nginx on 8080 instead.
rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/voidhost <<EOF
server {
    listen $PORT;
    listen [::]:$PORT;
    server_name _;

    root $APP_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location ~* \.(css|js|svg|png|jpg|jpeg|webp|gif|ico)$ {
        try_files \$uri =404;
        expires 7d;
        add_header Cache-Control "public";
    }
}
EOF

ln -sf /etc/nginx/sites-available/voidhost /etc/nginx/sites-enabled/voidhost

echo "[3/4] Starting Nginx..."
nginx -t
systemctl enable nginx
systemctl restart nginx

echo "[4/4] Done!"
IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo
echo "========================================"
echo "       VOID HOSTING INSTALLED"
echo "========================================"
echo "Website: http://${IP:-YOUR_VPS_IP}:$PORT"
echo "Files:   $APP_DIR"
echo "HTTP:    port $PORT"
echo "========================================"
