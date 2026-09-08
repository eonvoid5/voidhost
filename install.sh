#!/usr/bin/env bash
set -euo pipefail

REPO_TARBALL="https://github.com/eonvoid5/voidhost/archive/refs/heads/main.tar.gz"
APP_DIR="/var/www/voidhost"
PORT="6565"
PIDFILE="/tmp/voidhost.pid"

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

# Stop a previous VOID HOSTING process without requiring systemd.
if [ -f "$PIDFILE" ]; then
  OLD_PID="$(cat "$PIDFILE" 2>/dev/null || true)"
  [ -n "$OLD_PID" ] && kill "$OLD_PID" 2>/dev/null || true
  rm -f "$PIDFILE"
fi
pkill -f "python3 -m http.server $PORT --bind" 2>/dev/null || true

# Containers such as GitHub Codespaces do not run systemd. Start the static
# server directly in the background so the installer works there and on VPSes.
nohup python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$APP_DIR" >/tmp/voidhost.log 2>&1 &
PID=$!
echo "$PID" > "$PIDFILE"

sleep 1
echo "[3/4] Starting VOID HOSTING..."
if ! kill -0 "$PID" 2>/dev/null || ! ss -ltn 2>/dev/null | grep -q ":$PORT "; then
  echo "ERROR: VOID HOSTING failed to start on port $PORT"
  cat /tmp/voidhost.log 2>/dev/null || true
  exit 1
fi

echo "[4/4] Installation complete!"
IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo
echo "========================================"
echo "       VOID HOSTING INSTALLED"
echo "========================================"
echo "Website: http://${IP:-YOUR_VPS_IP}:$PORT"
echo "Files:   $APP_DIR"
echo "Port:    $PORT"
echo "========================================"
