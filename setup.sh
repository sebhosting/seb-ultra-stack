#!/bin/bash
set -euo pipefail
echo "🚀 Starting SEB Ultra Stack setup..."

# --- Helper functions ---
prompt_secret() {
    local prompt_text=$1
    local var_name=$2
    read -s -p "$prompt_text: " input
    echo
    eval "$var_name='$input'"
}

prompt_input() {
    local prompt_text=$1
    local var_name=$2
    read -p "$prompt_text: " input
    eval "$var_name='$input'"
}

# --- 1. System update & dependencies ---
echo "🛠 Updating system packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip software-properties-common ufw fail2ban software-properties-common lsb-release gnupg2 ca-certificates

# --- 2. Prompt for secrets ---
prompt_secret "Enter MariaDB root password" DB_ROOT_PASS
prompt_secret "Enter WordPress DB user password" WP_DB_PASS
prompt_input  "Enter WordPress admin username" WP_ADMIN_USER
prompt_secret "Enter WordPress admin password" WP_ADMIN_PASS
prompt_input  "Enter domain name (without https)" DOMAIN
prompt_input  "Enable wildcard SSL? (y/n)" WILDCARD_SSL

# --- 3. Nginx + PHP + MariaDB installation ---
echo "💻 Installing Nginx, PHP, MariaDB, Redis..."
sudo apt install -y nginx mariadb-server php8.4-fpm php8.4-cli php8.4-mysql php8.4-curl php8.4-xml php8.4-mbstring php8.4-gd php8.4-zip redis-server

# --- 4. Configure MariaDB ---
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS'; FLUSH PRIVILEGES;"
sudo mysql -uroot -p"$DB_ROOT_PASS" -e "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -uroot -p"$DB_ROOT_PASS" -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY '$WP_DB_PASS'; GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost'; FLUSH PRIVILEGES;"

# --- 5. Configure Redis ---
sudo sed -i "s/^# requirepass .*$/requirepass your_redis_password/" /etc/redis/redis.conf
sudo systemctl restart redis-server

# --- 6. WordPress Multisite setup ---
echo "🌐 Installing WordPress..."
cd /var/www/
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz
sudo mv wordpress "$DOMAIN"
sudo chown -R www-data:www-data "$DOMAIN"
sudo chmod -R 755 "$DOMAIN"

cd "$DOMAIN"
sudo -u www-data wp config create --dbname=wordpress --dbuser=wpuser --dbpass="$WP_DB_PASS" --dbhost=localhost --skip-check
sudo -u www-data wp core install --url="$DOMAIN" --title="My Awesome Site" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASS" --admin_email="admin@$DOMAIN"
sudo -u www-data wp core multisite-install --subdomains --title="My Network" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASS" --admin_email="admin@$DOMAIN"

# --- 7. Install essential plugins ---
PLUGINS=(woocommerce jetpack contact-form-7 wordpress-seo wordfence wp-super-cache redis-cache wp-optimize)
for plugin in "${PLUGINS[@]}"; do
    sudo -u www-data wp plugin install "$plugin" --activate
done

# --- 8. SSL via Certbot ---
if [[ "$WILDCARD_SSL" == "y" ]]; then
    echo "🔐 Setting up wildcard SSL (DNS challenge required)..."
    sudo apt install -y certbot python3-certbot-dns-cloudflare
    read -p "Enter Cloudflare email: " CF_EMAIL
    prompt_secret "Enter Cloudflare API key" CF_API_KEY
    # Create minimal credentials file
    CF_FILE="/root/cloudflare.ini"
    echo "dns_cloudflare_email = $CF_EMAIL" > $CF_FILE
    echo "dns_cloudflare_api_key = $CF_API_KEY" >> $CF_FILE
    chmod 600 $CF_FILE
    sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials $CF_FILE -d "*.$DOMAIN" -d "$DOMAIN"
else
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email admin@$DOMAIN
fi

# --- 9. Firewall + Fail2Ban ---
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw enable
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# --- 10. Optimize PHP & Nginx (basic) ---
sudo sed -i "s/memory_limit = .*/memory_limit = 1024M/" /etc/php/8.4/fpm/php.ini
sudo sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/8.4/fpm/php.ini
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl restart php8.4-fpm

echo "🎉 SEB Ultra Stack setup complete! Visit https://$DOMAIN to check your site."
