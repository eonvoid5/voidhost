#!/bin/bash
set -e

# VOIDHOST Cloudflare connection helper

echo "VOIDHOST — Cloudflare Tunnel"

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "Installing cloudflared..."
  mkdir -p --mode=0755 /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
  echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared jammy main' | tee /etc/apt/sources.list.d/cloudflared.list >/dev/null
  apt-get update
  apt-get install -y cloudflared
fi

cloudflared tunnel --url http://localhost:443
