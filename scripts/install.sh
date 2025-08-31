#!/bin/bash
set -e

echo "🚀 Starting SEBCom NASA Installer..."
INSTALL_DIR="/opt/SEBCom"
MYSQL_ROOT_PASS="rootpass"
DB_NAME="sebcom"
DB_USER="sebcom"
DB_PASS="sebcom123"

# -------------------------
# Root check
# -------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# -------------------------
# Directory structure
# -------------------------
mkdir -p $INSTALL_DIR/{data,logs,backups,src,public,docs,themes,plugins}
chown -R $SUDO_USER:$SUDO_USER $INSTALL_DIR

# -------------------------
# Update + Install LEMP + Tools
# -------------------------
apt update && apt upgrade -y
apt install -y nginx mariadb-server php-fpm php-mysql php-xml php-mbstring php-curl php-gd php-bcmath php-soap unzip curl gnupg software-properties-common nodejs npm git

# -------------------------
# Setup MariaDB
# -------------------------
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASS'; FLUSH PRIVILEGES;"
mysql -uroot -p$MYSQL_ROOT_PASS -e "CREATE DATABASE $DB_NAME;"
mysql -uroot -p$MYSQL_ROOT_PASS -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"

# -------------------------
# WordPress Download + Config
# -------------------------
cd $INSTALL_DIR
if [ ! -f "$INSTALL_DIR/public/wp-config.php" ]; then
  curl -O https://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz
  mv wordpress public
  rm latest.tar.gz
fi

# wp-config.php
cp public/wp-config-sample.php public/wp-config.php
sed -i "s/database_name_here/$DB_NAME/" public/wp-config.php
sed -i "s/username_here/$DB_USER/" public/wp-config.php
sed -i "s/password_here/$DB_PASS/" public/wp-config.php

# Enable multisite
sed -i "/That's all, stop editing!/i define('WP_ALLOW_MULTISITE', true);" public/wp-config.php

# -------------------------
# Nginx Config
# -------------------------
cat > /etc/nginx/sites-available/sebcom <<EOL
server {
    listen 80;
    server_name site1.local site2.local control.local;
    root $INSTALL_DIR/public;

    index index.php index.html;
    access_log $INSTALL_DIR/logs/access.log;
    error_log $INSTALL_DIR/logs/error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOL

ln -sf /etc/nginx/sites-available/sebcom /etc/nginx/sites-enabled/sebcom
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# -------------------------
# SSL Self-Signed
# -------------------------
SSL_DIR="/etc/ssl/sebcom"
mkdir -p $SSL_DIR
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout $SSL_DIR/sebcom.key \
  -out $SSL_DIR/sebcom.crt \
  -subj "/C=US/ST=State/L=City/O=SEBCom/OU=Dev/CN=site1.local"

# -------------------------
# SEBCom Control Panel Theme
# -------------------------
cd $INSTALL_DIR/themes
if [ ! -d "sebcom-control" ]; then
  git clone https://github.com/sebhosting/sebcom-theme-control sebcom-control || echo "Control Panel theme placeholder"
fi

# -------------------------
# Node Setup
# -------------------------
cd $INSTALL_DIR
npm init -y
npm install

# -------------------------
# Systemd Service (optional)
# -------------------------
cat > /etc/systemd/system/sebcom.service <<EOL
[Unit]
Description=SEBCom Stack AutoStart
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/php -S localhost:8080 -t public
Restart=always
User=$SUDO_USER

[Install]
WantedBy=multi-user.target
EOL

systemctl enable sebcom.service
systemctl start sebcom.service

# -------------------------
# Done
# -------------------------
echo "✅ SEBCom NASA Installer Complete!"
echo "Sites available:"
echo "  http://site1.local"
echo "  http://site2.local"
echo "  http://control.local (Command Center)"
echo "DB: $DB_NAME / $DB_USER / $DB_PASS"
