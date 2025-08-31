#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# SEB Ultra Stack - Fresh Installer + SEBCom Control Center
# ==========================================================

STATE_DIR="/opt/seb-ultra-state"
LOG_FILE="/var/log/seb-ultra-setup.log"
mkdir -p "$(dirname "$LOG_FILE")" "$STATE_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

PHP_MAIN="8.4"
PHP_FALLBACK="8.3"
PHP_PACKAGES_COMMON="cli fpm mysql curl mbstring gd xml zip intl bcmath soap imagick readline"
WP_CLI_BIN="/usr/local/bin/wp"

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

# -----------------------------
# Step 00: System prep
# -----------------------------
if ! is_done "00_basics"; then
  echo "==> Step 00: System prep & timezone"
  export DEBIAN_FRONTEND=noninteractive
  prompt "TZ_REGION" "Enter your timezone (e.g. UTC, America/New_York)" "UTC"
  timedatectl set-timezone "$TZ_REGION" || true
  apt-get update
  retry_apt "apt-get -y upgrade"
  retry_apt "apt-get -y install ca-certificates apt-transport-https software-properties-common curl wget git unzip jq ufw fail2ban gnupg lsb-release"
  mark_step "00_basics"
fi

# -----------------------------
# Step 01: PHP 8.4
# -----------------------------
if ! is_done "01_php"; then
  echo "==> Step 01: Install PHP ${PHP_MAIN} (fallback ${PHP_FALLBACK})"
  add-apt-repository -y ppa:ondrej/php
  apt-get update
  if apt-cache policy "php${PHP_MAIN}-fpm" | grep -q Candidate; then
    retry_apt "apt-get -y install php${PHP_MAIN}-$(echo $PHP_PACKAGES_COMMON)"
    php_set_version_vars "$PHP_MAIN"
  else
    retry_apt "apt-get -y install php${PHP_FALLBACK}-$(echo $PHP_PACKAGES_COMMON)"
    php_set_version_vars "$PHP_FALLBACK"
  fi
  # PHP tuning
  sed -ri "s/^;?memory_limit\s*=.*/memory_limit = 1024M/" "$PHP_INI"
  sed -ri "s/^;?max_execution_time\s*=.*/max_execution_time = 300/" "$PHP_INI"
  sed -ri "s/^;?upload_max_filesize\s*=.*/upload_max_filesize = 256M/" "$PHP_INI"
  sed -ri "s/^;?post_max_size\s*=.*/post_max_size = 256M/" "$PHP_INI"
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
  mark_step "01_php"
fi

# -----------------------------
# Step 02: Nginx
# -----------------------------
if ! is_done "02_nginx"; then
  echo "==> Step 02: Install Nginx"
  add-apt-repository -y ppa:ondrej/nginx
  apt-get update
  retry_apt "apt-get -y install nginx"
  systemd_enable_start nginx
  mark_step "02_nginx"
fi

# -----------------------------
# Step 03: MariaDB
# -----------------------------
if ! is_done "03_mariadb"; then
  echo "==> Step 03: Install MariaDB"
  retry_apt "apt-get -y install mariadb-server"
  systemd_enable_start mariadb
  mariadb -u root <<'SQL'
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
UPDATE mysql.user SET plugin='unix_socket' WHERE User='root' AND Host='localhost';
FLUSH PRIVILEGES;
SQL
  mark_step "03_mariadb"
fi

# -----------------------------
# Step 04: Redis
# -----------------------------
if ! is_done "04_redis"; then
  echo "==> Step 04: Install Redis"
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

# -----------------------------
# Step 05: Domain & WP inputs
# -----------------------------
if ! is_done "05_inputs"; then
  echo "==> Step 05: Collect site & WordPress details"
  prompt "PRIMARY_DOMAIN" "Primary domain (no protocol)"
  prompt "ADMIN_EMAIL" "Admin email" "admin@${PRIMARY_DOMAIN}"
  prompt "DB_NAME" "Database name" "seb_ultra_db"
  prompt "DB_USER" "Database user" "seb_ultra_user"
  prompt_secret "DB_PASS" "Database password (hidden)"
  prompt "WP_ADMIN_USER" "WP admin username" "admin"
  prompt_secret "WP_ADMIN_PASS" "WP admin password (hidden)"
  prompt "WP_SITE_TITLE" "Site Title" "SEB Ultra"
  mark_step "05_inputs"
fi

# -----------------------------
# Step 06: Create DB/User
# -----------------------------
if ! is_done "06_db_create"; then
  echo "==> Step 06: Creating database"
  mariadb -u root <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
  mark_step "06_db_create"
fi

# -----------------------------
# Step 07: Nginx site
# -----------------------------
if ! is_done "07_nginx_site"; then
  echo "==> Step 07: Configure Nginx site"
  WEB_ROOT="/var/www/${PRIMARY_DOMAIN}"
  PUBLIC_DIR="${WEB_ROOT}/public"
  mkdir -p "$PUBLIC_DIR"
  cat >/etc/nginx/sites-available/${PRIMARY_DOMAIN}.conf <<EOF
server {
    listen 80;
    server_name ${PRIMARY_DOMAIN} *.${PRIMARY_DOMAIN};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${PRIMARY_DOMAIN} *.${PRIMARY_DOMAIN};
    root ${PUBLIC_DIR};
    index index.php index.html;
    ssl_certificate     /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    location / { try_files \$uri \$uri/ /index.php?\$args; }
    location ~ \.php\$ { include fastcgi_params; fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; fastcgi_pass unix:${PHP_FPM_SOCKET}; }
}
EOF
  ln -sf /etc/nginx/sites-available/${PRIMARY_DOMAIN}.conf /etc/nginx/sites-enabled/
  nginx -t && systemctl reload nginx
  mark_step "07_nginx_site"
fi

# -----------------------------
# Step 08: WP Core
# -----------------------------
if ! is_done "08_wp_core"; then
  echo "==> Step 08: Install WP-CLI & WordPress"
  if [[ ! -x "$WP_CLI_BIN" ]]; then
    curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o "$WP_CLI_BIN"
    chmod +x "$WP_CLI_BIN"
  fi
  cd "$PUBLIC_DIR"
  curl -fsSL https://wordpress.org/latest.tar.gz | tar xz --strip-components=1
  SALTS="$(curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/)"
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
define('FS_METHOD', 'direct');
define('WP_ALLOW_MULTISITE', true);
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', true);
define('DOMAIN_CURRENT_SITE', '${PRIMARY_DOMAIN}');
define('PATH_CURRENT_SITE', '/');
define('SITE_ID_CURRENT_SITE', 1);
define('BLOG_ID_CURRENT_SITE', 1);
define('COOKIE_DOMAIN', '.${PRIMARY_DOMAIN}');
if ( !defined('ABSPATH') ) define('ABSPATH', __DIR__ . '/');
require_once ABSPATH . 'wp-settings.php';
EOF
  adduser --system --ingroup www-data --home "$WEB_ROOT" --no-create-home --shell /usr/sbin/nologin websvc || true
  chown -R www-data:www-data "$WEB_ROOT"
  sudo -u www-data -H "$WP_CLI_BIN" core install --path="$PUBLIC_DIR" --url="https://${PRIMARY_DOMAIN}" --title="${WP_SITE_TITLE}" --admin_user="${WP_ADMIN_USER}" --admin_password="${WP_ADMIN_PASS}" --admin_email="${ADMIN_EMAIL}" --skip-email
  sudo -u www-data -H "$WP_CLI_BIN" core multisite-convert --title="${WP_SITE_TITLE}" --subdomains
  mark_step "08_wp_core"
fi

# -----------------------------
# Step 08b: SEBCom Plugin
# -----------------------------
if ! is_done "08b_sebcom"; then
  echo "==> Step 08b: Install SEBCom Control Center"
  PLUGIN_DIR="${PUBLIC_DIR}/wp-content/plugins/sebcom-control"
  mkdir -p "$PLUGIN_DIR"
  cat >"$PLUGIN_DIR/sebcom-control.php" <<'EOF'
<?php
/**
 * Plugin Name: SEBCom - Ultimate Command Center
 * Description: Multisite dashboard with 3-site base limit
 * Version: 1.0.0
 */
if (!defined('ABSPATH')) exit;
add_filter('wpmu_validate_blog_signup', function($result){
    $max_sites = 3;
    if(get_sites(['number' => $max_sites+1])){
        $result['errors']->add('max_sites','Base tier: max 3 sites');
    }
    return $result;
});
add_action('network_admin_menu', function(){
    add_menu_page('SEBCom','SEBCom','manage_network','sebcom','sebcom_page','dashicons-admin-generic',2);
});
function sebcom_page(){ ?>
<div class="wrap"><h1>SEBCom Control Center</h1>
<p>Multisite limit: 3 (Base Tier)</p>
<p>PHP: <?php echo phpversion(); ?> | Memory: <?php echo ini_get('memory_limit'); ?></p>
<p>Redis Cache: <?php echo (function_exists('wp_cache_supports')?'Enabled':'Disabled'); ?></p>
</div><?php }
EOF
  sudo -u www-data -H "$WP_CLI_BIN" plugin activate sebcom-control
  mark_step "08b_sebcom"
fi

# -----------------------------
# Final perms & restart
# -----------------------------
WEB_ROOT="/var/www/${PRIMARY_DOMAIN}"
chown -R www-data:www-data "$WEB_ROOT"
find "$WEB_ROOT" -type d -exec chmod 755 {} \;
find "$WEB_ROOT" -type f -exec chmod 644 {} \;
systemctl restart nginx "php${PHP_SELECTED}-fpm" mariadb redis-server

echo "====================================================="
echo " SEB Ultra Stack + SEBCom is READY 🎉"
echo "====================================================="
echo "Domain: https://${PRIMARY_DOMAIN}"
echo "Web root: ${PUBLIC_DIR}"
echo "PHP-FPM: ${PHP_SELECTED}"
echo "DB: ${DB_NAME} | User: ${DB_USER}"
echo "WP Admin: https://${PRIMARY_DOMAIN}/wp-admin/"
echo "Multisite Base Tier: 3 sites max"
echo "====================================================="
