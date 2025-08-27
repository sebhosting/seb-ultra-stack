#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

echo "🔥 SEB Ultra Stack — Interactive Installer (Ubuntu 24.04)"
echo "--------------------------------------------------------"

prompt()       { local p="$1"; local v; read -rp "$p: " v; echo "$v"; }
prompt_secret(){ local p="$1"; local v; read -rsp "$p: " v; echo; echo "$v"; }
yn() { local p="$1"; local a; read -rp "$p [y/N]: " a; [[ "${a:-N}" =~ ^[Yy]$ ]]; }

DOMAIN=$(prompt "Primary domain (example.com)")
EMAIL=$(prompt "Admin email (for SSL notices)")
DB_ROOT=$(prompt_secret "MariaDB root password")
CF_TOKEN=$(prompt "Cloudflare API Token (optional for DNS-01 wildcard)")
PAYPAL_ID=$(prompt "PayPal Client ID (optional)")
PAYPAL_SECRET=$(prompt_secret "PayPal Secret (optional)")
INSTALL_MONITORING="N"
if yn "Install Prometheus + Grafana (docker-compose)?"; then INSTALL_MONITORING="Y"; fi

# Save local env (not committed)
cat > .env <<EOF
DOMAIN=${DOMAIN}
EMAIL=${EMAIL}
DB_ROOT=${DB_ROOT}
CLOUDFLARE_API_TOKEN=${CF_TOKEN}
PAYPAL_CLIENT_ID=${PAYPAL_ID}
PAYPAL_SECRET=${PAYPAL_SECRET}
EOF
chmod 600 .env
echo "✅ Saved .env"

echo "🔧 Updating apt and installing base packages..."
apt-get update -y
apt-get install -y software-properties-common curl git unzip ufw fail2ban ca-certificates

echo "📦 Installing Nginx, MariaDB, PHP 8.3, Redis..."
apt-get install -y nginx mariadb-server redis-server php8.3 php8.3-fpm php8.3-mysql php8.3-xml php8.3-curl php8.3-zip php8.3-gd php8.3-mbstring php8.3-intl

echo "🛡️ Configuring UFW..."
ufw allow OpenSSH || true
ufw allow "Nginx Full" || true
yes | ufw enable || true

echo "🛡️ Securing MariaDB..."
mysql -u root <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT}';
FLUSH PRIVILEGES;
SQL

DB_NAME=wp_${DOMAIN//./_}
DB_USER=wpuser
DB_PASS=$(openssl rand -base64 18)
mysql -u root -p"${DB_ROOT}" -e "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p"${DB_ROOT}" -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -u root -p"${DB_ROOT}" -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

echo "🔌 Redis tuning..."
sed -i 's/^#* *maxmemory-policy.*$/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf || true
systemctl enable --now redis-server

echo "🌐 Nginx server block..."
cat > /etc/nginx/sites-available/${DOMAIN}.conf <<NGINX
server {
  listen 80;
  server_name ${DOMAIN} *.${DOMAIN};

  root /var/www/${DOMAIN};
  index index.php index.html;

  client_max_body_size 64M;

  location / {
    try_files \$uri \$uri/ /index.php?\$args;
  }

  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.3-fpm.sock;
  }

  location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires max;
    log_not_found off;
  }

  add_header X-Frame-Options "SAMEORIGIN";
  add_header X-Content-Type-Options "nosniff";
  add_header Referrer-Policy "strict-origin-when-cross-origin";
}
NGINX

ln -sf /etc/nginx/sites-available/${DOMAIN}.conf /etc/nginx/sites-enabled/${DOMAIN}.conf
rm -f /etc/nginx/sites-enabled/default
mkdir -p /var/www/${DOMAIN}
chown -R www-data:www-data /var/www/${DOMAIN}
nginx -t && systemctl reload nginx

echo "📥 Installing WP-CLI & WordPress core..."
curl -sSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /usr/local/bin/wp

sudo -u www-data bash -lc "cd /var/www/${DOMAIN} && wp core download --locale=en_US"

# Create config with DB creds
sudo -u www-data wp config create \
  --path="/var/www/${DOMAIN}" \
  --dbname="${DB_NAME}" --dbuser="${DB_USER}" --dbpass="${DB_PASS}" --dbhost="localhost" \
  --skip-check

# Append PayPal constants if provided
if [[ -n "${PAYPAL_ID}" && -n "${PAYPAL_SECRET}" ]]; then
  echo "📦 Adding PayPal constants to wp-config.php..."
  cat >> /var/www/${DOMAIN}/wp-config.php <<PHP
// SEB Ultra Stack — PayPal bootstrap
if (!defined('SEB_PAYPAL_CLIENT_ID')) define('SEB_PAYPAL_CLIENT_ID', '${PAYPAL_ID}');
if (!defined('SEB_PAYPAL_SECRET')) define('SEB_PAYPAL_SECRET', '${PAYPAL_SECRET}');
PHP

  # Create mu-plugin to sync constants -> Woo settings on first run
  mkdir -p /var/www/${DOMAIN}/wp-content/mu-plugins
  cat > /var/www/${DOMAIN}/wp-content/mu-plugins/seb-paypal-bootstrap.php <<'PHPMU'
<?php
/**
 * Plugin Name: SEB Ultra — PayPal Bootstrap
 * Description: Reads SEB_PAYPAL_* constants and seeds WooCommerce PayPal plugin settings (if available).
 */
add_action('init', function () {
    if (!defined('SEB_PAYPAL_CLIENT_ID') || !defined('SEB_PAYPAL_SECRET')) return;
    $opt_name = 'woocommerce-ppcp-settings';
    $opts = get_option($opt_name, []);
    if (!is_array($opts)) $opts = [];
    $changed = false;
    if (empty($opts['client_id']) || $opts['client_id'] !== SEB_PAYPAL_CLIENT_ID) { $opts['client_id'] = SEB_PAYPAL_CLIENT_ID; $changed = true; }
    if (empty($opts['client_secret']) || $opts['client_secret'] !== SEB_PAYPAL_SECRET) { $opts['client_secret'] = SEB_PAYPAL_SECRET; $changed = true; }
    if ($changed) update_option($opt_name, $opts);
});
PHPMU
  chown -R www-data:www-data /var/www/${DOMAIN}/wp-content/mu-plugins
fi

# Install core & multisite
sudo -u www-data wp core install \
  --path="/var/www/${DOMAIN}" \
  --url="https://${DOMAIN}" \
  --title="SEB Ultra Network" \
  --admin_user="admin" \
  --admin_password="$(openssl rand -hex 12)" \
  --admin_email="${EMAIL}"

sudo -u www-data wp core multisite-convert \
  --path="/var/www/${DOMAIN}" \
  --title="SEB Ultra Network" \
  --subdomains

echo "🔐 SSL — Let's Encrypt"
apt-get install -y certbot python3-certbot-nginx
if [[ -n "${CF_TOKEN}" ]]; then
  echo "Using Cloudflare DNS-01 for wildcard cert..."
  apt-get install -y python3-certbot-dns-cloudflare
  mkdir -p /root/.secrets
  CF_INI=/root/.secrets/cloudflare.ini
  echo "dns_cloudflare_api_token = ${CF_TOKEN}" > "${CF_INI}"
  chmod 600 "${CF_INI}"
  certbot certonly --dns-cloudflare --dns-cloudflare-credentials "${CF_INI}" \
    -d "${DOMAIN}" -d "*.${DOMAIN}" --non-interactive --agree-tos -m "${EMAIL}" || true

  # Switch Nginx to SSL
  sed -i 's/listen 80;/listen 80; return 301 https:\\/\\/$host$request_uri;/' /etc/nginx/sites-available/${DOMAIN}.conf
  cat >> /etc/nginx/sites-available/${DOMAIN}.conf <<SSL
server {
  listen 443 ssl http2;
  server_name ${DOMAIN} *.${DOMAIN};
  root /var/www/${DOMAIN};
  index index.php index.html;

  ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5;
  add_header Strict-Transport-Security "max-age=31536000" always;

  location / { try_files \\$uri \\$uri/ /index.php?\\$args; }
  location ~ \\.php$ { include snippets/fastcgi-php.conf; fastcgi_pass unix:/run/php/php8.3-fpm.sock; }
  location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg)$ { expires max; log_not_found off; }
  add_header X-Frame-Options "SAMEORIGIN";
  add_header X-Content-Type-Options "nosniff";
  add_header Referrer-Policy "strict-origin-when-cross-origin";
}
SSL

else
  echo "Using HTTP challenge for base domain (no wildcard). You can re-run with Cloudflare token later."
  certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos -m "${EMAIL}" || true
fi

nginx -t && systemctl reload nginx

echo "🧩 Plugins (installed, not activated):"
sudo -u www-data wp plugin install \
  woocommerce redis-cache wp-mail-smtp jetpack fluent-smtp --path="/var/www/${DOMAIN}" --force || true

# Monitoring (optional)
if [[ "${INSTALL_MONITORING}" == "Y" ]]; then
  echo "📈 Installing Docker + docker-compose plugin for monitoring..."
  apt-get install -y docker.io docker-compose-plugin
  systemctl enable --now docker
  (cd monitoring && docker compose up -d)
fi

echo "🩺 Health check:"
bash scripts/healthcheck.sh || true

echo "✅ Completed."
echo "Visit: https://${DOMAIN}"
