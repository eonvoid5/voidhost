# VOIDHOST

Premium Minecraft hosting panel/node branding based on the JTG Pterodactyl Docker setup.

## Brand

- Name: **VOIDHOST**
- Style: glass / blur / neon green Minecraft-inspired
- Logo: `branding/voidhost-logo.svg`
- Application name: `VOIDHOST`
- Panel directory: `/srv/voidhost/panel`
- Wings directory: `/srv/voidhost/wings`

## Install Panel

```bash
curl -fsSL https://raw.githubusercontent.com/eonvoid5/voidhost/main/install-panel.sh -o install-panel.sh
chmod +x install-panel.sh
sudo ./install-panel.sh
```

## Install Wings

```bash
curl -fsSL https://raw.githubusercontent.com/eonvoid5/voidhost/main/install-wings.sh -o install-wings.sh
chmod +x install-wings.sh
sudo ./install-wings.sh
```

## Cloudflare connection

```bash
curl -fsSL https://raw.githubusercontent.com/eonvoid5/voidhost/main/connect.sh -o connect.sh
chmod +x connect.sh
sudo ./connect.sh
```

## Admin user

After the panel starts:

```bash
cd /srv/voidhost/panel
docker compose run --rm panel php artisan p:user:make
```
