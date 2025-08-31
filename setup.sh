#!/usr/bin/env bash
set -euo pipefail

# ===============================
# SEBCom Ultra Stack Installer
# Nginx + PHP 8.4 + MariaDB + Redis
# WordPress Multisite (Subdomains)
# SEBCom Dashboard (Dark/Light)
# SSL + Security
# Resumable checkpoints
# ===============================

STATE_DIR="/opt/sebcom-state"
LOG_FILE="/var/log/sebcom-setup.log"
mkdir -p "$STATE_DIR" "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

# Helpers
mark_step() { touch "$STATE_DIR/$1.done"; }
is_done() { [[ -f "$STATE_DIR/$1.done" ]]; }

prompt() {
  local var_name="$1" prompt_text="$2" default_val="${3:-}"
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
  local var_name="$1" prompt_text="$2"
  if [[ -n "${!var_name:-}" ]]; then return 0; fi
  read -rsp "$prompt_text: " val || true
  echo
  export "$var_name"="$val"
}

confirm() {
  local q="${1:-Proceed?}"
  read -rp "$q [y/N]: " ans || true
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

retry_apt() {
  local cmd="$*"
  for i in 1 2 3; do
    if eval "$cmd"; then return 0; fi
    echo "apt attempt $i failed; fixing..."
    apt-get -y -f install || true
    apt-get update || true
    sleep 2
  done
  eval "$cmd"
}

systemd_enable_start() {
  local svc="$1"
  systemctl enable "$svc" >/dev/null 2>&1 || true
  systemctl restart "$svc"
}

# -------------------
# Step 00: Basics
# -------------------
if ! is_done "00_basics"; then
  echo "==> Step 00: System prep & timezone"
  export DEBIAN_FRONTEND=noninteractive
  prompt "TZ_REGION" "Timezone" "UTC"
  timedatectl set-timezone "$TZ_REGION" || true
  apt-get update
  retry_apt "apt-get -y upgrade"
  retry_apt "apt-get -y install ca-certificates apt-transport-https software-properties-common curl wget git unzip jq ufw fail2ban gnupg lsb-release"
  mark_step "00_basics"
fi

# -------------------
# Step 01: Nginx + PPAs
# -------------------
if ! is_done "01_nginx_ppas"; then
  echo "==> Step 01: Nginx + PPAs"
  add-apt-repository -y ppa:ondrej/php
  add-apt-repository -y ppa:ondrej/nginx
  apt-get update
  retry_apt "apt-get -y install nginx"
  systemd_enable_start nginx
  mark_step "01_nginx_ppas"
fi

# -------------------
# Step 02: PHP 8.4 install
# -------------------
PHP_MAIN="8.4"
PHP_FALLBACK="8.3"
PHP_PACKAGES_COMMON="cli fpm mysql curl mbstring gd xml zip intl bcmath soap imagick readline"

if ! is_done "02_php"; then
  echo "==> Step 02: PHP $PHP_MAIN"
  if apt-cache policy "php${PHP_MAIN}-fpm" | grep -q Candidate; then
    retry_apt "apt-get -y install $(echo php${PHP_MAIN}-{${PHP_PACKAGES_COMMON// /,}})"
    PHP_SELECTED="$PHP_MAIN"
  else
    echo "PHP $PHP_MAIN not found, installing fallback $PHP_FALLBACK"
    retry_apt "apt-get -y install $(echo php${PHP_FALLBACK}-{${PHP_PACKAGES_COMMON// /,}})"
    PHP_SELECTED="$PHP_FALLBACK"
  fi

  PHP_INI="/etc/php/${PHP_SELECTED}/fpm/php.ini"
  sed -ri "s/^;?cgi.fix_pathinfo\s*=.*/cgi.fix_pathinfo=0/" "$PHP_INI"
  sed -ri "s/^;?memory_limit\s*=.*/memory_limit=1024M/" "$PHP_INI"
  sed -ri "s/^;?max_execution_time\s*=.*/max_execution_time=300/" "$PHP_INI"
  sed -ri "s/^;?upload_max_filesize\s*=.*/upload_max_filesize=256M/" "$PHP_INI"
  sed -ri "s/^;?post_max_size\s*=.*/post_max_size=256M/" "$PHP_INI"

  systemd_enable_start "php${PHP_SELECTED}-fpm"
  mark_step "02_php"
fi

# -------------------
# Step 03: MariaDB
# -------------------
if ! is_done "03_mariadb"; then
  echo "==> Step 03: MariaDB"
  retry_apt "apt-get -y install mariadb-server"
  systemd_enable_start mariadb

  mariadb -u root <<'SQL'
SET SQL_LOG_BIN=0;
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
UPDATE mysql.user SET plugin='unix_socket' WHERE User='root' AND Host='localhost';
FLUSH PRIVILEGES;
SQL

  mark_step "03_mariadb"
fi

# -------------------
# Step 04: Redis
# -------------------
if ! is_done "04_redis"; then
  echo "==> Step 04: Redis"
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

# -------------------
# Step 05: WordPress Inputs
# -------------------
if ! is_done "05_inputs"; then
  echo "==> Step 05: WP Inputs"
  prompt "PRIMARY_DOMAIN" "Primary domain for multisite"
  prompt "ADMIN_EMAIL" "Admin email" "admin@${PRIMARY_DOMAIN}"
  prompt "DB_NAME" "Database name" "sebcom_db"
  prompt "DB_USER" "Database user" "sebcom_user"
  prompt_secret "DB_PASS" "Database password"
  prompt "WP_ADMIN_USER" "WP admin username" "admin"
  prompt_secret "WP_ADMIN_PASS" "WP admin password"
  prompt "WP_SITE_TITLE" "Site Title" "SEBCom Ultra"
  mark_step "05_inputs"
fi

# -------------------
# Step 06: Create DB/User
# -------------------
if ! is_done "06_db_create"; then
  echo "==> Step 06: Create DB/User"
  mariadb -u root <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
  mark_step "06_db_create"
fi

# -------------------
# Step 07+: Continue with Nginx vhost, WP-CLI, SEBCom dashboard, SSL, Security...
# -------------------

echo "✅ Base stack ready. You can now continue building multisite, dashboard, SSL, and security steps."
