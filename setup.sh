#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# SEB Ultra Stack - One Shot Installer (Badass Edition)
# Nginx + PHP 8.4 (fallback 8.3) + MariaDB + Redis
# WordPress Multisite (SUBDOMAINS) + WooCommerce + Security
# Custom Admin Dashboard + Dark/Light Theme
# SSL (LE or Cloudflare Wildcard) + Cloudflare API (optional)
# Resumable checkpoints
# ==========================================================

# ---------- Globals / Paths ----------
STATE_DIR="/opt/seb-ultra-state"
LOG_FILE="/var/log/seb-ultra-setup.log"
mkdir -p "$(dirname "$LOG_FILE")" "$STATE_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# Default versions
PHP_MAIN="8.4"
PHP_FALLBACK="8.3"
PHP_SELECTED=""
PHP_PACKAGES_COMMON="cli fpm mysql curl mbstring gd xml zip intl bcmath soap imagick readline"
PHP_INI=""
PHP_FPM_POOL_DIR=""
PHP_FPM_SOCKET=""
WP_CLI_BIN="/usr/local/bin/wp"

# ------------- Helpers ---------------
mark_step() { touch "$STATE_DIR/$1.done"; }
is_done()   { [[ -f "$STATE_DIR/$1.done" ]]; }

prompt() {
  local var_name="$1"; local prompt_text="$2"; local default_val="${3:-}"
  local val=""
  if [[ -n "${!var_name:-}" ]]; then return 0; fi
  if [[ -n "$default_val" ]]; then
    read -rp "$prompt_text [$default_val]: " val || true
    val="${val:-$default_val}"
  else
    read -rp "$prompt_text: " val || true
  fi
  export "$var_name"="$val"
}

prompt_secret() {
  local var_name="$1"; local prompt_text="$2"
  local val=""
  if [[ -n "${!var_name:-}" ]]; then return 0; fi
  read -rsp "$prompt_text: " val || true; echo
  export "$var_name"="$val"
}

confirm() {
  local q="${1:-Proceed?}"
  read -rp "$q [y/N]: " ans || true
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

systemd_enable_start() {
  local svc="$1"
  systemctl enable "$svc" >/dev/null 2>&1 || true
  systemctl restart "$svc"
  systemctl status "$svc" --no-pager -l || true
}

retry_apt() {
  local cmd="$*"
  for i in {1..3}; do
    if eval "$cmd"; then return 0; fi
    echo "apt attempt $i failed; fixing and retrying..."
    apt-get -y -f install || true
    apt-get update || true
    sleep 2
  done
  eval "$cmd"
}

php_set_version_vars() {
  PHP_SELECTED="$1"
  PHP_INI="/etc/php/${PHP_SELECTED}/fpm/php.ini"
  PHP_FPM_POOL_DIR="/etc/php/${PHP_SELECTED}/fpm/pool.d"
  PHP_FPM_SOCKET="/var/run/php/php${PHP_SELECTED}-fpm.sock"
}

# ------------- Step 00: Timezone / Basics -------------
if ! is_done "00_basics"; then
  echo "==> Step 00: System prep & timezone"
  export DEBIAN_FRONTEND=noninteractive

  prompt "TZ_REGION" "Enter your timezone (e.g. America/Chicago or Europe/Berlin)" "UTC"
  timedatectl set-timezone "$TZ_REGION" || true

  apt-get update
  retry_apt "apt-get -y upgrade"
  retry_apt "apt-get -y install ca-certificates apt-transport-https software-properties-common curl wget git unzip jq ufw fail2ban gnupg lsb-release"

  mark_step "00_basics"
fi

#!/bin/bash

# ----------------------------
# PHP 8.4 Installation Helper
# ----------------------------

echo "==> Adding Ondřej PHP PPA for Nginx..."
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update

# List of required PHP packages
PHP_PACKAGES=(
    php8.4-fpm
    php8.4-mysql
    php8.4-xml
    php8.4-curl
    php8.4-gd
    php8.4-mbstring
    php8.4-intl
    php8.4-bcmath
    php8.4-soap
    php8.4-imagick
    php8.4-readline
)

# Retry mechanism
MAX_RETRIES=3
for i in $(seq 1 $MAX_RETRIES); do
    echo "==> Attempt $i: Installing PHP 8.4 packages..."
    sudo apt update --fix-missing
    sudo apt install -y "${PHP_PACKAGES[@]}" && break
    echo "==> Attempt $i failed; retrying in 5 seconds..."
    sleep 5
done

# Verify installation
echo "==> Verifying PHP installation..."
php -v || { echo "PHP 8.4 installation failed!"; exit 1; }

echo "==> PHP 8.4 installed successfully."

# ------------- Step 01: Nginx + PPAs -------------
if ! is_done "01_nginx_ppas"; then
  echo "==> Step 01: Add PPAs (PHP & Nginx) and install Nginx"
  add-apt-repository -y ppa:ondrej/php
  add-apt-repository -y ppa:ondrej/nginx
  apt-get update
  retry_apt "apt-get -y install nginx"

  systemd_enable_start nginx

  mark_step "01_nginx_ppas"
fi

# ------------- Step 02: PHP 8.4 (fallback 8.3) -------------
if ! is_done "02_php"; then
  echo "==> Step 02: Install PHP ${PHP_MAIN} (fallback ${PHP_FALLBACK})"
  if apt-cache policy "php${PHP_MAIN}-fpm" | grep -q Candidate; then
    retry_apt "apt-get -y install php${PHP_MAIN}-$(echo $PHP_PACKAGES_COMMON)"
    php_set_version_vars "$PHP_MAIN"
  else
    echo "PHP ${PHP_MAIN} not found, installing ${PHP_FALLBACK}"
    retry_apt "apt-get -y install php${PHP_FALLBACK}-$(echo $PHP_PACKAGES_COMMON)"
    php_set_version_vars "$PHP_FALLBACK"
  fi

  # Harden & tune PHP-FPM
  sed -ri "s/^;?cgi.fix_pathinfo\s*=.*/cgi.fix_pathinfo=0/" "$PHP_INI"
  sed -ri "s/^;?memory_limit\s*=.*/memory_limit = 1024M/" "$PHP_INI"
  sed -ri "s/^;?max_execution_time\s*=.*/max_execution_time = 300/" "$PHP_INI"
  sed -ri "s/^;?upload_max_filesize\s*=.*/upload_max_filesize = 256M/" "$PHP_INI"
  sed -ri "s/^;?post_max_size\s*=.*/post_max_size = 256M/" "$PHP_INI"

  # OPcache tune
  cat >/etc/php/${PHP_SELECTED}/mods-available/opcache.ini <<EOF
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=512
opcache.interned_strings_buffer=64
opcache.max_accelerated_files=32531
opcache.validate_timestamps=0
opcache.revalidate_freq=0
opcache.jit_buffer_size=256M
opcache.jit=1255
EOF

  systemd_enable_start "php${PHP_SELECTED}-fpm"

  mark_step "02_php"
fi

# ------------- Step 03: MariaDB -------------
if ! is_done "03_mariadb"; then
  echo "==> Step 03: Install & secure MariaDB"
  retry_apt "apt-get -y install mariadb-server"

  systemd_enable_start mariadb

  # mysql_secure_installation (quiet)
  mariadb -u root <<'SQL'
SET SQL_LOG_BIN=0;
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
UPDATE mysql.user SET plugin='unix_socket' WHERE User='root' AND Host='localhost';
FLUSH PRIVILEGES;
SQL

  mark_step "03_mariadb"
fi

# ------------- Step 04: Redis -------------
if ! is_done "04_redis"; then
  echo "==> Step 04: Install & tune Redis"
  retry_apt "apt-get -y install redis-server"

  cat >/etc/redis/redis.conf <<'EOF'
supervised systemd
maxmemory 256mb
maxmemory-policy allkeys-lru
save ""
appendonly no
bind 127.0.0.1 ::1
protected-mode yes
port 6379
logfile /var/log/redis/redis-server.log
EOF

  systemd_enable_start redis-server
  mark_step "04_redis"
fi

# ------------- Step 05: Domain & WP inputs -------------
if ! is_done "05_inputs"; then
  echo "==> Step 05: Collect site & WordPress details"
  prompt "PRIMARY_DOMAIN" "Primary domain for multisite (root domain, no protocol)"
  prompt "ADMIN_EMAIL" "Admin email" "admin@${PRIMARY_DOMAIN}"

  prompt "DB_NAME" "Database name (no spaces)"
  prompt "DB_USER" "Database user"
  prompt_secret "DB_PASS" "Database password (hidden)"

  prompt "WP_ADMIN_USER" "WP admin username" "admin"
  prompt_secret "WP_ADMIN_PASS" "WP admin password (hidden)"
  prompt "WP_SITE_TITLE" "Site Title" "SEB Ultra"

  # Optional integrations
  echo "Optional: Cloudflare API (for wildcard DNS-01). Leave blank to skip."
  prompt "CF_API_TOKEN" "Cloudflare API Token" ""
  prompt "CF_API_EMAIL" "Cloudflare Email" ""
  echo "Optional: Stripe/PayPal keys (used by Woo). You can add them later in WP."
  prompt "STRIPE_PK" "Stripe Publishable Key" ""
  prompt "STRIPE_SK" "Stripe Secret Key" ""
  prompt "PAYPAL_CLIENT_ID" "PayPal Client ID" ""
  prompt "PAYPAL_CLIENT_SECRET" "PayPal Client Secret" ""
  echo "Optional: WP Mail SMTP (you can configure later in WP)."
  prompt "SMTP_HOST" "SMTP Host" ""
  prompt "SMTP_USER" "SMTP Username" ""
  prompt_secret "SMTP_PASS" "SMTP Password (hidden)"
  prompt "SMTP_PORT" "SMTP Port" "587"
  prompt "SMTP_SECURE" "SMTP Security (tls/ssl/none)" "tls"

  mark_step "05_inputs"
fi

# ------------- Step 06: Create DB / User -------------
if ! is_done "06_db_create"; then
  echo "==> Step 06: Creating database & user"
  mariadb -u root <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
  mark_step "06_db_create"
fi

# ------------- Step 07: Nginx vhost -------------
if ! is_done "07_nginx_site"; then
  echo "==> Step 07: Nginx site config"
  WEB_ROOT="/var/www/${PRIMARY_DOMAIN}"
  PUBLIC_DIR="${WEB_ROOT}/public"
  mkdir -p "$PUBLIC_DIR"

  cat >/etc/nginx/sites-available/${PRIMARY_DOMAIN}.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${PRIMARY_DOMAIN} *.${PRIMARY_DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${PRIMARY_DOMAIN} *.${PRIMARY_DOMAIN};

    root ${PUBLIC_DIR};
    index index.php index.html;

    # TEMP self-signed placeholder until LE step (prevents nginx from failing)
    ssl_certificate     /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    client_max_body_size 256M;

    location ~* \.(css|gif|ico|jpeg|jpg|js|png|svg|webp|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass unix:${PHP_FPM_SOCKET};
        fastcgi_read_timeout 300;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_hide_header X-Powered-By;
    }

    location ~* /(wp-config\.php|\.ht|\.git|composer\.(json|lock)|/vendor/) { deny all; }
    location ~* /(?:uploads|files)/.*\.php$ { deny all; }
}
EOF

  ln -sf /etc/nginx/sites-available/${PRIMARY_DOMAIN}.conf /etc/nginx/sites-enabled/${PRIMARY_DOMAIN}.conf
  nginx -t
  systemctl reload nginx
  mark_step "07_nginx_site"
fi

# ------------- Step 08: WP-CLI + WordPress -------------
if ! is_done "08_wp_core"; then
  echo "==> Step 08: Install WP-CLI & WordPress core"
  if [[ ! -x "$WP_CLI_BIN" ]]; then
    curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o "$WP_CLI_BIN"
    chmod +x "$WP_CLI_BIN"
  fi

  WEB_ROOT="/var/www/${PRIMARY_DOMAIN}"
  PUBLIC_DIR="${WEB_ROOT}/public"

  cd "$PUBLIC_DIR"
  if [[ ! -f wp-load.php ]]; then
    curl -fsSL https://wordpress.org/latest.tar.gz | tar xz --strip-components=1
  fi

  # Generate salts (fallback if API fails)
  SALTS="$(curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/ || true)"
  if [[ -z "$SALTS" ]]; then
    SALTS=$(php -r 'function r($l){$c="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}";$s="";for($i=0;$i<$l;$i++){$s.=$c[random_int(0,strlen($c)-1)];}return $s;} foreach(["AUTH_KEY","SECURE_AUTH_KEY","LOGGED_IN_KEY","NONCE_KEY","AUTH_SALT","SECURE_AUTH_SALT","LOGGED_IN_SALT","NONCE_SALT"] as $k){echo "define(\x27$k\x27,\x27".r(64)."\x27);\n";}')
  fi

  # Create wp-config.php
  cat >"${PUBLIC_DIR}/wp-config.php" <<EOF
<?php
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASSWORD', '${DB_PASS}');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

${SALTS}

\$table_prefix = 'wp_';

define('WP_DEBUG', false);
define('DISALLOW_FILE_EDIT', true);
define('AUTOMATIC_UPDATER_DISABLED', true);
define('FS_METHOD', 'direct');

define('WP_ALLOW_MULTISITE', true);
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', true);
define('DOMAIN_CURRENT_SITE', '${PRIMARY_DOMAIN}');
define('PATH_CURRENT_SITE', '/');
define('SITE_ID_CURRENT_SITE', 1);
define('BLOG_ID_CURRENT_SITE', 1);
define('COOKIE_DOMAIN', '.${PRIMARY_DOMAIN}');

define('FORCE_SSL_ADMIN', true);

if ( !defined('ABSPATH') ) define('ABSPATH', __DIR__ . '/');
require_once ABSPATH . 'wp-settings.php';
EOF

  # perms
  adduser --system --ingroup www-data --home "$WEB_ROOT" --no-create-home --shell /usr/sbin/nologin websvc || true
  chown -R www-data:www-data "$WEB_ROOT"
  find "$WEB_ROOT" -type d -exec chmod 755 {} \;
  find "$WEB_ROOT" -type f -exec chmod 644 {} \;

  # Install WP core
  sudo -u www-data -H "$WP_CLI_BIN" core install \
    --path="$PUBLIC_DIR" \
    --url="https://${PRIMARY_DOMAIN}" \
    --title="${WP_SITE_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASS}" \
    --admin_email="${ADMIN_EMAIL}" \
    --skip-email

  # Convert to multisite subdomains
  sudo -u www-data -H "$WP_CLI_BIN" core multisite-convert --title="${WP_SITE_TITLE}" --subdomains

  mark_step "08_wp_core"
fi

# ------------- Step 09: Plugins + Theme + Admin Dashboard -------------
if ! is_done "09_plugins_theme"; then
  echo "==> Step 09: Install essential plugins, custom theme, custom admin dashboard"

  PUBLIC_DIR="/var/www/${PRIMARY_DOMAIN}/public"
  cd "$PUBLIC_DIR"

  # Plugins
  sudo -u www-data -H "$WP_CLI_BIN" plugin install \
    woocommerce jetpack wordpress-seo wordfence contact-form-7 \
    redis-cache wp-optimize wp-mail-smtp --activate-network

  # Enable object cache
  sudo -u www-data -H "$WP_CLI_BIN" redis enable || true

  # Create custom theme "seb-ultra" (dark/light)
  THEME_DIR="${PUBLIC_DIR}/wp-content/themes/seb-ultra"
  mkdir -p "$THEME_DIR"
  cat >"$THEME_DIR/style.css" <<'EOF'
/*
Theme Name: SEB Ultra
Description: Sleek, dark-first theme with light mode toggle.
Version: 1.0.0
Author: SEB Hosting
Text Domain: seb-ultra
*/
:root{--bg:#0b0f14;--fg:#eaeef3;--muted:#a7b0bb;--accent:#5cc8ff}
@media (prefers-color-scheme: light){:root{--bg:#ffffff;--fg:#0b0f14;--muted:#445}} 
body{margin:0;font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;background:var(--bg);color:var(--fg);line-height:1.6}
a{color:var(--accent);text-decoration:none}
.header{padding:24px;border-bottom:1px solid #222;display:flex;gap:16px;align-items:center;justify-content:space-between}
.container{max-width:1100px;margin:0 auto;padding:24px}
.btn{padding:10px 16px;border:1px solid #333;border-radius:10px;display:inline-block}
.toggle{cursor:pointer;border:1px solid #333;border-radius:12px;padding:8px 12px}
.light body{background:#fff;color:#0b0f14}
EOF

  cat >"$THEME_DIR/functions.php" <<'EOF'
<?php
add_action('wp_enqueue_scripts', function(){
  wp_enqueue_style('seb-ultra', get_stylesheet_uri(),[], '1.0.0');
  wp_enqueue_script('seb-ultra-js', get_template_directory_uri().'/toggle.js', [], '1.0.0', true);
});
add_theme_support('title-tag');
add_theme_support('post-thumbnails');
register_nav_menus(['primary'=>'Primary']);
EOF

  cat >"$THEME_DIR/toggle.js" <<'EOF'
(()=>{const key="seb-ultra-mode";function apply(v){if(v==="light"){document.documentElement.classList.add("light");}else{document.documentElement.classList.remove("light");}}
const saved=localStorage.getItem(key);if(saved){apply(saved);}document.addEventListener("DOMContentLoaded",()=>{const t=document.getElementById("mode-toggle");if(!t) return;t.addEventListener("click",()=>{const v=document.documentElement.classList.contains("light")?"dark":"light";localStorage.setItem(key,v);apply(v);});});})();
EOF

  cat >"$THEME_DIR/index.php" <<'EOF'
<?php get_header(); ?>
<div class="container">
  <h1><?php bloginfo('name'); ?></h1>
  <p><?php bloginfo('description'); ?></p>
  <?php if ( have_posts() ) : while ( have_posts() ) : the_post(); ?>
    <article>
      <h2><a href="<?php the_permalink();?>"><?php the_title();?></a></h2>
      <div><?php the_excerpt();?></div>
    </article>
  <?php endwhile; endif; ?>
</div>
<?php get_footer(); ?>
EOF

  cat >"$THEME_DIR/header.php" <<'EOF'
<!doctype html><html <?php language_attributes(); ?>><head>
<meta charset="<?php bloginfo('charset'); ?>"><meta name="viewport" content="width=device-width,initial-scale=1">
<?php wp_head(); ?>
</head><body <?php body_class(); ?>>
<header class="header container">
  <a class="btn" href="<?php echo esc_url(home_url('/')); ?>">SEB Ultra</a>
  <button id="mode-toggle" class="toggle" aria-label="Toggle theme">🌓</button>
</header>
EOF

  cat >"$THEME_DIR/footer.php" <<'EOF'
<footer class="container"><p>&copy; <?php echo date('Y'); ?> SEB Ultra.</p></footer>
<?php wp_footer(); ?></body></html>
EOF

  sudo -u www-data -H "$WP_CLI_BIN" theme activate seb-ultra

  # Custom Admin Dashboard plugin
  PLUGIN_DIR="${PUBLIC_DIR}/wp-content/plugins/seb-ultra-dashboard"
  mkdir -p "$PLUGIN_DIR"
  cat >"$PLUGIN_DIR/seb-ultra-dashboard.php" <<'EOF'
<?php
/**
 * Plugin Name: SEB Ultra Dashboard
 * Description: Custom admin dashboard with quick actions and health.
 * Version: 1.0.0
 * Author: SEB Hosting
 */
if (!defined('ABSPATH')) exit;

add_action('admin_menu', function(){
  add_menu_page('SEB Ultra', 'SEB Ultra', 'manage_options', 'seb-ultra', 'seb_ultra_page', 'dashicons-performance', 2);
});

function seb_ultra_page(){
  ?>
  <div class="wrap">
    <h1>SEB Ultra Control Panel</h1>
    <p>Quick utilities and status.</p>
    <div style="display:flex;gap:20px;flex-wrap:wrap">
      <div class="card" style="padding:16px;border:1px solid #ddd;border-radius:12px;max-width:420px">
        <h2>Cache</h2>
        <p>Redis Object Cache status: <?php echo (function_exists('wp_cache_supports')?'Enabled':'Unknown'); ?></p>
        <form method="post">
          <?php wp_nonce_field('seb_ultra_action','seb_ultra_nonce'); ?>
          <button class="button button-primary" name="seb_ultra_flush" value="1">Flush All Caches</button>
        </form>
      </div>
      <div class="card" style="padding:16px;border:1px solid #ddd;border-radius:12px;max-width:420px">
        <h2>Server</h2>
        <ul>
          <li>PHP: <?php echo phpversion(); ?></li>
          <li>Memory Limit: <?php echo ini_get('memory_limit'); ?></li>
          <li>Upload Max: <?php echo ini_get('upload_max_filesize'); ?></li>
        </ul>
      </div>
    </div>
  </div>
  <?php
}

add_action('admin_init', function(){
  if (!current_user_can('manage_options')) return;
  if (!isset($_POST['seb_ultra_nonce']) || !wp_verify_nonce($_POST['seb_ultra_nonce'],'seb_ultra_action')) return;
  if (isset($_POST['seb_ultra_flush'])) {
    if (function_exists('wp_cache_flush')) wp_cache_flush();
    if (function_exists('wp_cache_flush_group')) @wp_cache_flush_group('object-cache');
    wp_redirect(admin_url('admin.php?page=seb-ultra&flushed=1'));
    exit;
  }
});
EOF

  sudo -u www-data -H "$WP_CLI_BIN" plugin activate seb-ultra-dashboard

  mark_step "09_plugins_theme"
fi

# ------------- Step 10: Woo + Payments baseline (keys stored as options if provided) -------------
if ! is_done "10_payments"; then
  echo "==> Step 10: Payment keys (optional)"
  PUBLIC_DIR="/var/www/${PRIMARY_DOMAIN}/public"
  set +e
  if [[ -n "$STRIPE_PK" ]]; then
    sudo -u www-data -H "$WP_CLI_BIN" option update wc_stripe_publishable_key "$STRIPE_PK" --path="$PUBLIC_DIR"
  fi
  if [[ -n "$STRIPE_SK" ]]; then
    sudo -u www-data -H "$WP_CLI_BIN" option update wc_stripe_secret_key "$STRIPE_SK" --path="$PUBLIC_DIR"
  fi
  if [[ -n "$PAYPAL_CLIENT_ID" ]]; then
    sudo -u www-data -H "$WP_CLI_BIN" option update wc_ppcp_client_id "$PAYPAL_CLIENT_ID" --path="$PUBLIC_DIR"
  fi
  if [[ -n "$PAYPAL_CLIENT_SECRET" ]]; then
    sudo -u www-data -H "$WP_CLI_BIN" option update wc_ppcp_client_secret "$PAYPAL_CLIENT_SECRET" --path="$PUBLIC_DIR"
  fi
  set -e
  mark_step "10_payments"
fi

# ------------- Step 11: SSL (Let’s Encrypt regular or Cloudflare wildcard) -------------
if ! is_done "11_ssl"; then
  echo "==> Step 11: SSL setup"
  retry_apt "apt-get -y install certbot python3-certbot-nginx"
  if [[ -n "$CF_API_TOKEN" && -n "$CF_API_EMAIL" ]]; then
    echo "Cloudflare creds provided. Attempting wildcard."
    retry_apt "apt-get -y install python3-certbot-dns-cloudflare"
    mkdir -p /root/.secrets/certbot
    CF_INI="/root/.secrets/certbot/cloudflare.ini"
    cat >"$CF_INI" <<EOF
dns_cloudflare_api_token = ${CF_API_TOKEN}
EOF
    chmod 600 "$CF_INI"
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials "$CF_INI" \
      -d "${PRIMARY_DOMAIN}" -d "*.${PRIMARY_DOMAIN}" --agree-tos -m "${ADMIN_EMAIL}" --non-interactive || true

    if [[ -f "/etc/letsencrypt/live/${PRIMARY_DOMAIN}/fullchain.pem" ]]; then
      sed -ri "s#ssl-cert-snakeoil.pem#letsencrypt/live/${PRIMARY_DOMAIN}/fullchain.pem#; s#ssl-cert-snakeoil.key#letsencrypt/live/${PRIMARY_DOMAIN}/privkey.pem#" \
        "/etc/nginx/sites-available/${PRIMARY_DOMAIN}.conf"
      nginx -t && systemctl reload nginx
    fi
  else
    echo "No Cloudflare creds. Installing standard cert for ${PRIMARY_DOMAIN} (and www)."
    certbot --nginx -d "${PRIMARY_DOMAIN}" -d "www.${PRIMARY_DOMAIN}" --agree-tos -m "${ADMIN_EMAIL}" --non-interactive || true
  fi

  # Auto renew
  systemctl enable certbot.timer >/dev/null 2>&1 || true
  systemctl restart certbot.timer || true

  mark_step "11_ssl"
fi

# ------------- Step 12: Security (UFW, Fail2Ban, SSH) -------------
if ! is_done "12_security"; then
  echo "==> Step 12: Security hardening"

  # UFW
  ufw allow OpenSSH || true
  ufw allow 'Nginx Full' || true
  yes | ufw enable || true
  ufw status verbose || true

  # Fail2Ban basic (already installed)
  systemd_enable_start fail2ban

  # SSH hardening (disable root login)
  if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    sed -ri "s/^PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
  else
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
  fi
  systemctl restart ssh || true

  mark_step "12_security"
fi

# ------------- Step 13: Nginx microcache + performance (optional, safe defaults) -------------
if ! is_done "13_perf"; then
  echo "==> Step 13: Nginx performance (microcaching & buffers)"
  cat >/etc/nginx/conf.d/fastcgi-cache.conf <<'EOF'
fastcgi_cache_path /var/cache/nginx/fastcgi levels=1:2 keys_zone=WORDPRESS:100m max_size=5g inactive=60m use_temp_path=off;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
fastcgi_cache_methods GET HEAD;
fastcgi_ignore_headers Cache-Control Expires Set-Cookie;
EOF

  # Append microcache to server block (safe: only adds header if caching hits)
  if ! grep -q "X-Cache-Status" "/etc/nginx/sites-available/${PRIMARY_DOMAIN}.conf"; then
    sed -i "/location \//,/\}/{/try_files/ a \        fastcgi_cache WORDPRESS;\n        fastcgi_cache_valid 200 301 302 1m;\n        fastcgi_cache_use_stale error timeout updating http_500 http_503;\n        fastcgi_cache_bypass \$http_cookie;\n        fastcgi_no_cache \$http_cookie;\n        add_header X-Cache-Status \$upstream_cache_status;" "/etc/nginx/sites-available/${PRIMARY_DOMAIN}.conf"
  fi

  nginx -t && systemctl reload nginx
  mark_step "13_perf"
fi

# ------------- Step 14: Permissions recap & service restart -------------
if ! is_done "14_perms_finalize"; then
  echo "==> Step 14: Final perms & service reload"
  WEB_ROOT="/var/www/${PRIMARY_DOMAIN}"
  chown -R www-data:www-data "$WEB_ROOT"
  find "$WEB_ROOT" -type d -exec chmod 755 {} \;
  find "$WEB_ROOT" -type f -exec chmod 644 {} \;

  systemctl restart nginx
  systemctl restart "php${PHP_SELECTED}-fpm"
  systemctl restart mariadb
  systemctl restart redis-server

  mark_step "14_perms_finalize"
fi

# ------------- Step 15: Output / Next steps -------------
echo "====================================================="
echo " SEB Ultra Stack is READY 🎉"
echo "====================================================="
echo "Domain:              https://${PRIMARY_DOMAIN}"
echo "Web root:            /var/www/${PRIMARY_DOMAIN}/public"
echo "PHP-FPM:             ${PHP_SELECTED} (${PHP_FPM_SOCKET})"
echo "MariaDB DB:          ${DB_NAME}"
echo "MariaDB User:        ${DB_USER}"
echo "WP Admin:            https://${PRIMARY_DOMAIN}/wp-admin/"
echo "WP Admin User:       ${WP_ADMIN_USER}"
echo "Email:               ${ADMIN_EMAIL}"
echo "-----------------------------------------------------"
echo "Multisite (subdomains) is enabled. Configure wildcard DNS:"
echo "  A   @                -> YOUR_SERVER_IP"
echo "  A   *.${PRIMARY_DOMAIN} -> YOUR_SERVER_IP"
echo "If using Cloudflare, enable orange-cloud & set proxy as desired."
echo "-----------------------------------------------------"
echo "SSL: If you used Cloudflare token, wildcard cert attempted."
echo "     Otherwise a standard LE cert was installed (domain + www)."
echo "-----------------------------------------------------"
echo "Resume/Retry: Script is resumable. Fix issues and re-run:"
echo "  sudo ./setup.sh"
echo "Check log: $LOG_FILE"
echo "====================================================="
