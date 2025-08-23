#!/usr/bin/env bash
set -euo pipefail

cat <<'BANNER'
[38;5;45m███████╗███████╗██████╗     ██╗   ██╗██╗     ████████╗██████╗  █████╗
██╔════╝██╔════╝██╔══██╗    ██║   ██║██║     ╚══██╔══╝██╔══██╗██╔══██╗
███████╗█████╗  ██████╔╝    ██║   ██║██║        ██║   ██████╔╝███████║
╚════██║██╔══╝  ██╔═══╝     ██║   ██║██║        ██║   ██╔═══╝ ██╔══██║
███████║███████╗██║         ╚██████╔╝███████╗   ██║   ██║     ██║  ██║
╚══════╝╚══════╝╚═╝          ╚═════╝ ╚══════╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝[0m
   🚀 SEB Ultra Stack - High-Performance WordPress Multisite Stack
BANNER

echo "→ This installer sets up Nginx + PHP 8.3 + MariaDB + Redis + SSL on Ubuntu 24.04 LTS"

read -rp "Primary domain (e.g. sebhosting.com): " PRIMARY_DOMAIN
read -rp "Admin email for SSL (e.g. admin@${PRIMARY_DOMAIN}): " ADMIN_EMAIL
read -rsp "MariaDB root password: " DB_ROOT_PASSWORD; echo
read -rp "WordPress admin username: " WP_ADMIN_USER
read -rsp "WordPress admin password: " WP_ADMIN_PASSWORD; echo
read -rp "Cloudflare API Token (optional, Enter to skip): " CLOUDFLARE_API_TOKEN || true
read -rp "PayPal Client ID (optional, Enter to skip): " PAYPAL_CLIENT_ID || true
read -rp "PayPal Client Secret (optional, Enter to skip): " PAYPAL_CLIENT_SECRET || true

REDIS_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)

cat > .env <<ENV
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
DB_NAME=seb_wp
DB_USER=seb_wp_user
DB_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24)

WP_ADMIN_USER=${WP_ADMIN_USER}
WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}
WP_ADMIN_EMAIL=${ADMIN_EMAIL}

REDIS_PASSWORD=${REDIS_PASSWORD}

CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN:-}
PAYPAL_CLIENT_ID=${PAYPAL_CLIENT_ID:-}
PAYPAL_CLIENT_SECRET=${PAYPAL_CLIENT_SECRET:-}
ENV
chmod 600 .env

sudo apt-get update -y
sudo apt-get install -y nginx mariadb-server php-fpm php-cli php-mysql php-xml php-mbstring php-curl php-zip php-gd php-intl redis-server certbot python3-certbot-nginx fail2ban unzip curl rsync

# Redis
sudo sed -i 's/^# *unixsocket .*$/unixsocket \/var\/run\/redis\/redis-server.sock/' /etc/redis/redis.conf || true
sudo sed -i 's/^# *unixsocketperm .*$/unixsocketperm 770/' /etc/redis/redis.conf || true
if ! grep -q '^requirepass' /etc/redis/redis.conf; then
  echo "requirepass ${REDIS_PASSWORD}" | sudo tee -a /etc/redis/redis.conf >/dev/null
else
  sudo sed -i "s/^requirepass .*/requirepass ${REDIS_PASSWORD}/" /etc/redis/redis.conf
fi
sudo usermod -aG redis www-data || true
sudo systemctl enable --now redis-server

# MariaDB
sudo systemctl enable --now mariadb
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"
sudo mysql -uroot -p"${DB_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS seb_wp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -uroot -p"${DB_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS 'seb_wp_user'@'localhost' IDENTIFIED BY (SELECT REPLACE(UUID(),'-',''));"
sudo mysql -uroot -p"${DB_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON seb_wp.* TO 'seb_wp_user'@'localhost'; FLUSH PRIVILEGES;"

# WordPress
curl -sL https://wordpress.org/latest.zip -o /tmp/wordpress.zip
sudo rm -rf /var/www/html/*
sudo unzip -q /tmp/wordpress.zip -d /var/www/html/
sudo rsync -a /var/www/html/wordpress/ /var/www/html/
sudo rm -rf /var/www/html/wordpress
sudo chown -R www-data:www-data /var/www/html

# wp-config
cat > /var/www/html/wp-config.php <<'WPCONFIG'
<?php
$env = __DIR__ . '/.env';
if (file_exists($env)) {
  $vars = parse_ini_file($env, false, INI_SCANNER_RAW);
  foreach ($vars as $k => $v) { $_ENV[$k] = $v; }
}
define( 'DB_NAME',     $_ENV['DB_NAME'] ?? 'seb_wp' );
define( 'DB_USER',     $_ENV['DB_USER'] ?? 'seb_wp_user' );
define( 'DB_PASSWORD', $_ENV['DB_PASSWORD'] ?? '' );
define( 'DB_HOST',     'localhost' );
define( 'DB_CHARSET',  'utf8mb4' );
define( 'DB_COLLATE',  '' );
define( 'WP_REDIS_PASSWORD', $_ENV['REDIS_PASSWORD'] ?? '' );
define( 'WP_REDIS_HOST', '/var/run/redis/redis-server.sock' );
define( 'WP_REDIS_SCHEME', 'unix' );
define( 'WP_ALLOW_MULTISITE', true );
if (!defined('AUTH_KEY')) {
  $salt = @file_get_contents('https://api.wordpress.org/secret-key/1.1/salt/');
  if ($salt) eval($salt);
}
define( 'DISALLOW_FILE_EDIT', true );
$table_prefix = 'wp_';
define( 'WP_DEBUG', false );
if ( ! defined( 'ABSPATH' ) ) define( 'ABSPATH', __DIR__ . '/' );
require_once ABSPATH . 'wp-settings.php';
WPCONFIG
sudo chown www-data:www-data /var/www/html/wp-config.php

# Nginx
cat > /etc/nginx/sites-available/wordpress <<NGINX
server {
  listen 80;
  server_name ${PRIMARY_DOMAIN};
  root /var/www/html;
  index index.php;
  client_max_body_size 64M;
  location / { try_files $uri $uri/ /index.php?$args; }
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php-fpm.sock;
  }
  location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    try_files $uri $uri/ @fallback;
    expires max;
    log_not_found off;
  }
  location @fallback { rewrite ^ /index.php last; }
  add_header X-Frame-Options "SAMEORIGIN";
  add_header X-Content-Type-Options "nosniff";
  add_header Referrer-Policy "strict-origin-when-cross-origin";
}
NGINX
sudo ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# SSL
if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  sudo apt-get install -y python3-certbot-dns-cloudflare
  mkdir -p ~/.secrets/certbot && chmod 700 ~/.secrets
  cat > ~/.secrets/certbot/cloudflare.ini <<CF
dns_cloudflare_api_token = ${CLOUDFLARE_API_TOKEN}
CF
  chmod 600 ~/.secrets/certbot/cloudflare.ini
  sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini -d "${PRIMARY_DOMAIN}" -d "*.$PRIMARY_DOMAIN" --agree-tos -m "${ADMIN_EMAIL}" --non-interactive
else
  sudo certbot --nginx -d "${PRIMARY_DOMAIN}" --agree-tos -m "${ADMIN_EMAIL}" --redirect --non-interactive
fi

# wp-cli
curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
php wp-cli.phar --info >/dev/null 2>&1 && sudo mv wp-cli.phar /usr/local/bin/wp && sudo chmod +x /usr/local/bin/wp

sudo -u www-data wp plugin install woocommerce jetpack fluent-smtp redis-cache really-simple-ssl --path=/var/www/html --allow-root --quiet || true
sudo -u www-data wp core install --path=/var/www/html --url="https://${PRIMARY_DOMAIN}" --title="SEB Ultra Stack" --admin_user="${WP_ADMIN_USER}" --admin_password="${WP_ADMIN_PASSWORD}" --admin_email="${ADMIN_EMAIL}" --skip-email --allow-root
sudo -u www-data wp core multisite-convert --title="SEB Network" --allow-root

echo "✅ Installed at https://${PRIMARY_DOMAIN} (admin at /wp-admin)"
