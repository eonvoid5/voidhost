#!/usr/bin/env bash
set -euo pipefail

REPO_TARBALL="https://github.com/eonvoid5/voidhost/archive/refs/heads/main.tar.gz"
APP_DIR="/var/www/voidhost"
PORT="8080"
SERVICE="voidhost"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run: sudo bash install.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/4] Installing required packages..."
apt-get update -y
apt-get install -y --no-install-recommends curl ca-certificates tar python3

echo "[2/4] Downloading VOID HOSTING..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
curl -fsSL "$REPO_TARBALL" | tar -xz --strip-components=1 -C "$APP_DIR"
chown -R root:root "$APP_DIR"

# Use Python's static web server directly so existing/restricted Nginx
# configurations cannot break the installer. The site is exposed on 8080.
cat > "/etc/systemd/system/${SERVICE}.service" <<EOF
[Unit]
Description=VOID HOSTING Website
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 -m http.server $PORT --bind 0.0.0.0
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$SERVICE"
systemctl restart "$SERVICE"

# Verify that the website process is actually listening before declaring success.
sleep 1
if ! ss -ltn 2>/dev/null | grep -q ":$PORT "; then
  echo "ERROR: VOID HOSTING failed to start on port $PORT"
  systemctl status "$SERVICE" --no-pager || true
  exit 1
fi

echo "[3/4] Starting VOID HOSTING..."
echo "[4/4] Installation complete!"
IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo
echo "========================================"
echo "       VOID HOSTING INSTALLED"
echo "========================================"
echo "Website: http://${IP:-YOUR_VPS_IP}:$PORT"
echo "Files:   $APP_DIR"
echo "Port:    $PORT"
echo "Service: $SERVICE"
echo "========================================"
