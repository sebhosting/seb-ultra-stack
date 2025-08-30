#!/bin/bash
set -e

echo "🚀 Welcome to SEB Ultra Stack Installer (Multisite + WooCommerce + Badass Plugins!)"

# -----------------------------
# 1️⃣ Server Preparation
# -----------------------------
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip ufw software-properties-common lsb-release software-properties-common

# -----------------------------
# 2️⃣ Ask for Inputs
# -----------------------------
read -p "Enter primary domain (e.g. example.com): " DOMAIN
read -p "Enter email for SSL and notifications: " ADMIN_EMAIL
read -s -p "Enter MariaDB root password: " DB_ROOT_PASS
echo ""
read -p "Enter WordPress admin username: " WP_ADMIN_USER
read -s -p "Enter WordPress admin password: " WP_ADMIN_PASS
echo ""
read -p "Do you want Cloudflare integration? (y/n): " USE_CF
if [[ "$USE_CF" == "y" ]]; then
    read -s -p "Enter Cloudflare API token: " CF_API_TOKEN
    echo ""
fi
read -p "Do you want SSL wildcard for multisite? (y/n): " USE_WILDCARD_SSL

# -----------------------------
# 3️⃣ Install Nginx, PHP, MariaDB, Redis
# -----------------------------
echo "Installing Nginx, PHP 8.4, MariaDB, Redis..."
sudo apt install -y nginx php8.4-fpm php8.4-mysql php8.4-xml php8.4-curl php8.4-gd php8.4-mbstring mariadb-server redis-server

# -----------------------------
# 4️⃣ Configure Firewall
# -----------------------------
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw --force enable

# -----------------------------
# 5️⃣ Secure MariaDB
# -----------------------------
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "FLUSH PRIVILEGES;"

# -----------------------------
# 6️⃣ WordPress Setup
# -----------------------------
WP_PATH="/var/www/${DOMAIN}"
sudo mkdir -p $WP_PATH
sudo chown -R $USER:$USER $WP_PATH

echo "Downloading WordPress..."
wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
tar -xzf /tmp/wordpress.tar.gz -C /tmp
cp -R /tmp/wordpress/* $WP_PATH

# Setup wp-config.php
cp $WP_PATH/wp-config-sample.php $WP_PATH/wp-config.php
sed -i "s/database_name_here/${DOMAIN//./_}/" $WP_PATH/wp-config.php
sed -i "s/username_here/root/" $WP_PATH/wp-config.php
sed -i "s/password_here/${DB_ROOT_PASS}/" $WP_PATH/wp-config.php

# Generate security keys
for key in AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT; do
    VALUE=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    sed -i "/define('${key}'/c\${VALUE}" $WP_PATH/wp-config.php
done

# Enable multisite
echo "define('WP_ALLOW_MULTISITE', true);" >> $WP_PATH/wp-config.php

# -----------------------------
# 7️⃣ Nginx Config
# -----------------------------
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
sudo tee $NGINX_CONF > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN *.${DOMAIN};

    root $WP_PATH;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff|woff2|ttf|eot)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOL

sudo ln -s $NGINX_CONF /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# -----------------------------
# 8️⃣ SSL with Let's Encrypt
# -----------------------------
if [[ "$USE_WILDCARD_SSL" == "y" ]]; then
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot certonly --nginx --agree-tos --email $ADMIN_EMAIL -d "*.$DOMAIN" -d $DOMAIN
else
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --agree-tos --email $ADMIN_EMAIL --redirect
fi

# -----------------------------
# 9️⃣ Plugins Installation
# -----------------------------
echo "Installing essential plugins..."
PLUGIN_LIST=("woocommerce" "jetpack" "contact-form-7" "wp-mail-smtp" "yoast-seo" "wp-super-cache" "wp-optimize" "redis-cache" "wordfence")
for plugin in "${PLUGIN_LIST[@]}"; do
    wp plugin install $plugin --activate --path=$WP_PATH
done

# -----------------------------
# 🔟 WooCommerce Setup
# -----------------------------
wp option update woocommerce_calc_taxes 1 --path=$WP_PATH
wp option update woocommerce_calc_discounts 1 --path=$WP_PATH

# -----------------------------
# 1️⃣1️⃣ Redis Setup
# -----------------------------
sudo sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf
sudo systemctl restart redis-server

# -----------------------------
# 1️⃣2️⃣ Cloudflare (Optional)
# -----------------------------
if [[ "$USE_CF" == "y" ]]; then
    echo "Configuring Cloudflare for $DOMAIN..."
    # Placeholder for API automation
fi

# -----------------------------
# 1️⃣3️⃣ Payment Gateway Placeholders
# -----------------------------
echo "⚡ Please configure PayPal and Stripe API keys manually in WooCommerce settings."

# -----------------------------
# 1️⃣4️⃣ Set Permissions
# -----------------------------
sudo chown -R www-data:www-data $WP_PATH
sudo find $WP_PATH -type d -exec chmod 755 {} \;
sudo find $WP_PATH -type f -exec chmod 644 {} \;

echo "✅ SEB Ultra Stack installation complete!"
echo "Visit http://$DOMAIN to finish WordPress multisite setup."

