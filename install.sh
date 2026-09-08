#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/eonvoid5/voidhost.git"
APP_DIR="/var/www/voidhost"
PORT="8080"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root: sudo bash install.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git python3 nginx

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
git clone --depth 1 "$REPO" "$APP_DIR"
chown -R www-data:www-data "$APP_DIR"

cat > /etc/systemd/system/voidhost.service <<EOF
[Unit]
Description=VOID HOSTING website
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 -m http.server $PORT --bind 127.0.0.1
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/nginx/sites-available/voidhost <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/voidhost /etc/nginx/sites-enabled/voidhost
nginx -t
systemctl daemon-reload
systemctl enable --now voidhost
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
