#!/usr/bin/env bash
set -euo pipefail
cd /var/www/html

if [ ! -f index.php ]; then
  echo "→ Downloading WordPress..."
  curl -sL https://wordpress.org/latest.tar.gz | tar -xz --strip-components=1
fi
chown -R www-data:www-data /var/www/html

# Create .env if missing (best for local dev; prod should create manually)
if [ ! -f .env ]; then
  cat > .env <<ENV
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-change-me}
DB_NAME=${DB_NAME:-seb_wp}
DB_USER=${DB_USER:-seb_wp_user}
DB_PASSWORD=${DB_PASSWORD:-change-me}
WP_ADMIN_USER=${WP_ADMIN_USER:-admin}
WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD:-change-me}
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-you@example.com}
REDIS_PASSWORD=${REDIS_PASSWORD:-redis-pass}
PAYPAL_CLIENT_ID=${PAYPAL_CLIENT_ID:-}
PAYPAL_CLIENT_SECRET=${PAYPAL_CLIENT_SECRET:-}
ENV
  chmod 600 .env
fi
