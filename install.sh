#!/bin/bash
set -e
set -o pipefail

# ===============================
# SEB Ultra Stack Installer
# Fully Automated, Resumable, Multisite + WooCommerce + Security + Performance
# ===============================

# -------- Functions --------

pause() {
    echo
    read -p "Press ENTER after you fix the issue to resume..."
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or sudo."
        exit 1
    fi
}

prompt_db_credentials() {
    read -p "Enter the WordPress database username: " DB_USER
    read -sp "Enter the database password: " DB_PASS
    echo
}

prompt_domain() {
    read -p "Enter primary domain (example.com): " DOMAIN
    read -p "Enter admin email: " ADMIN_EMAIL
}

prompt_cloudflare() {
    read -p "Do you want to configure Cloudflare API? (y/n): " CF_CHOICE
    if [[ "$CF_CHOICE" =~ ^[Yy]$ ]]; then
        read -p "Cloudflare Email: " CF_EMAIL
        read -p "Cloudflare API Key: " CF_KEY
    fi
}

install_dependencies() {
    echo "Updating system packages..."
    apt update && apt upgrade -y

    echo "Installing required dependencies..."
    apt install -y software-properties-common curl wget git unzip ufw fail2ban certbot python3-certbot-nginx mariadb-server mariadb-client redis-server logrotate
}

add_php_repo() {
    echo "Adding PHP 8.4 repository..."
    add-apt-repository -y ppa:ondrej/php
    apt update
}

install_php_nginx() {
    echo "Installing PHP 8.4 + extensions..."
    apt install -y php8.4-fpm php8.4-mysql php8.4-xml php8.4-curl php8.4-gd php8.4-mbstring php8.4-zip php8.4-soap

    echo "Installing Nginx..."
    apt install -y nginx
}

configure_firewall_fail2ban() {
    echo "Configuring UFW firewall..."
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable

    echo "Configuring Fail2Ban..."
    cat > /etc/fail2ban/jail.local <<EOL
[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
maxretry = 3
EOL
    systemctl restart fail2ban
}

secure_mariadb() {
    echo "Securing MariaDB..."
    mysql_secure_installation || pause
}

create_wp_db_user() {
    echo "Creating WordPress database and user..."
    mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS wp_multisite DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" || pause
    mysql -u root -p -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" || pause
    mysql -u root -p -e "GRANT ALL PRIVILEGES ON wp_multisite.* TO '${DB_USER}'@'localhost';" || pause
    mysql -u root -p -e "FLUSH PRIVILEGES;" || pause
}

configure_php() {
    echo "Configuring PHP 8.4..."
    sed -i "s/memory_limit = .*/memory_limit = 1024M/" /etc/php/8.4/fpm/php.ini
    sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/8.4/fpm/php.ini
    systemctl restart php8.4-fpm
}

configure_nginx() {
    echo "Configuring Nginx..."
    mkdir -p /var/www/${DOMAIN}
    chown -R www-data:www-data /var/www/${DOMAIN}
    chmod -R 755 /var/www/${DOMAIN}

    cat > /etc/nginx/sites-available/${DOMAIN}.conf <<EOL
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    root /var/www/${DOMAIN};
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

    ln -sf /etc/nginx/sites-available/${DOMAIN}.conf /etc/nginx/sites-enabled/
    nginx -t || pause
    systemctl reload nginx
}

install_wordpress() {
    echo "Installing WordPress..."
    wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
    tar xzf /tmp/wordpress.tar.gz -C /tmp/
    cp -R /tmp/wordpress/* /var/www/${DOMAIN}/
    chown -R www-data:www-data /var/www/${DOMAIN}
    chmod -R 755 /var/www/${DOMAIN}

    echo "Configuring wp-config.php..."
    cp /var/www/${DOMAIN}/wp-config-sample.php /var/www/${DOMAIN}/wp-config.php
    sed -i "s/database_name_here/wp_multisite/" /var/www/${DOMAIN}/wp-config.php
    sed -i "s/username_here/${DB_USER}/" /var/www/${DOMAIN}/wp-config.php
    sed -i "s/password_here/${DB_PASS}/" /var/www/${DOMAIN}/wp-config.php

    # Generate salts
    SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    sed -i "/AUTH_KEY/c\\$SALTS" /var/www/${DOMAIN}/wp-config.php
}

install_plugins() {
    echo "Installing essential plugins..."
    wp plugin install woocommerce --activate --path=/var/www/${DOMAIN}
    wp plugin install jetpack --activate --path=/var/www/${DOMAIN}
    wp plugin install contact-form-7 --activate --path=/var/www/${DOMAIN}
    wp plugin install wp-super-cache --activate --path=/var/www/${DOMAIN}
    wp plugin install redis-cache --activate --path=/var/www/${DOMAIN}
    wp plugin install wp-optimize --activate --path=/var/www/${DOMAIN}
    wp plugin install wordfence --activate --path=/var/www/${DOMAIN}
    wp plugin install yoast-seo --activate --path=/var/www/${DOMAIN}
    wp plugin install wp-mail-smtp --activate --path=/var/www/${DOMAIN}
}

enable_ssl() {
    echo "Configuring SSL with Certbot..."
    certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email ${ADMIN_EMAIL} || pause
}

# -------- Main Execution --------

check_root
prompt_domain
prompt_db_credentials
prompt_cloudflare
install_dependencies
add_php_repo
install_php_nginx
configure_firewall_fail2ban
secure_mariadb
create_wp_db_user
configure_php
configure_nginx
install_wordpress
install_plugins
enable_ssl

echo
echo "🎉 SEB Ultra Stack installation complete!"
echo "Your site is ready at http://${DOMAIN} (https:// will be enabled via SSL)"
