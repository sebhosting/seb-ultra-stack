#!/usr/bin/env bash
set -euo pipefail

cyan()  { printf "\033[36m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }

bold "🔥 SEB Ultra Stack — Interactive Installer"

prompt() {
  local var="$1" msg="$2" def="${3:-}"
  if [ -n "$def" ]; then
    read -r -p "$msg [$def]: " val || true
    val="${val:-$def}"
  else
    read -r -p "$msg: " val || true
  fi
  echo "$var=$val" >> .env.tmp
}

safewrite_env() {
  if [ -f .env ]; then
    mv .env ".env.bak.$(date +%s)"
  fi
  mv .env.tmp .env
}

rm -f .env.tmp
touch .env.tmp

cyan "→ Basic settings"
prompt DOMAIN "Your root domain (e.g. example.com)" "example.com"
prompt ADMIN_EMAIL "Admin email (for certs/alerts)" "admin@example.com"

cyan "→ Database"
prompt DB_ROOT_PASSWORD "MySQL root password" "change-me"
prompt DB_NAME "WordPress DB name" "wordpress"
prompt DB_USER "WordPress DB user" "wpuser"
prompt DB_PASSWORD "WordPress DB user password" "change-me-too"

cyan "→ WordPress"
echo "WP_TABLE_PREFIX=wp_" >> .env.tmp
echo "WP_DEBUG=false" >> .env.tmp
echo "MULTISITE=true" >> .env.tmp
echo "SUBDOMAIN_INSTALL=true" >> .env.tmp

cyan "→ Redis"
echo "REDIS_HOST=redis" >> .env.tmp
echo "REDIS_PORT=6379" >> .env.tmp

cyan "→ Optional integrations"
read -r -p "Use Cloudflare DNS-01 for wildcard SSL? (y/N): " CF
if [[ "${CF,,}" == "y" ]]; then
  prompt CLOUDFLARE_EMAIL "Cloudflare account email"
  prompt CLOUDFLARE_API_TOKEN "Cloudflare API token (Zone.DNS edit)"
else
  echo "CLOUDFLARE_EMAIL=" >> .env.tmp
  echo "CLOUDFLARE_API_TOKEN=" >> .env.tmp
fi

read -r -p "Configure PayPal API for Woo now? (y/N): " PP
if [[ "${PP,,}" == "y" ]]; then
  prompt PAYPAL_CLIENT_ID "PayPal Client ID"
  prompt PAYPAL_CLIENT_SECRET "PayPal Client Secret"
else
  echo "PAYPAL_CLIENT_ID=" >> .env.tmp
  echo "PAYPAL_CLIENT_SECRET=" >> .env.tmp
fi

safewrite_env
green "✅ Wrote .env"
green "Next: run 'docker compose up -d'"
