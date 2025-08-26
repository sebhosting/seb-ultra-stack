#!/usr/bin/env bash
set -euo pipefail
echo "== SEB Ultra Stack Installer =="
read -rp "Primary domain (e.g., example.com): " DOMAIN
read -rp "Admin email (for SSL notices): " ADMIN_EMAIL
read -rp "MySQL root password: " -s DB_ROOT; echo
read -rp "Use Cloudflare DNS-01 for wildcard SSL? (y/N): " CF_SSL
if [[ "${CF_SSL,,}" == "y" ]]; then
  read -rp "Cloudflare API Token: " CF_API_TOKEN
  read -rp "Cloudflare Zone ID: " CF_ZONE_ID
fi
read -rp "Configure Redis object cache? (Y/n): " USE_REDIS
cat > .env <<ENV
DOMAIN=${DOMAIN}
ADMIN_EMAIL=${ADMIN_EMAIL}
DB_ROOT=${DB_ROOT}
USE_REDIS=${USE_REDIS:-Y}
CF_ENABLE=$([[ "${CF_SSL,,}" == "y" ]] && echo "Y" || echo "N")
CF_API_TOKEN=${CF_API_TOKEN:-}
CF_ZONE_ID=${CF_ZONE_ID:-}
ENV
chmod 600 .env
echo "✅ .env written."
