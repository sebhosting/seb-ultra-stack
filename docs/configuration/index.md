---
layout: default
title: Configuration Manual
description: Comprehensive configuration guide for SEB Ultra Stack components
---

# 🔧 Configuration Manual

Learn how to configure and customize every aspect of your SEB Ultra Stack for optimal performance and security.

## 📁 Configuration File Locations

### **Primary Configuration Files**
```
/etc/seb-stack/
├── stack.conf           # Main stack configuration
├── domains.conf         # Domain settings
├── security.conf        # Security settings
├── performance.conf     # Performance tuning
└── backup.conf         # Backup configuration

/etc/nginx/
├── nginx.conf          # Main Nginx configuration
├── sites-available/    # Virtual host configurations
└── conf.d/            # Additional configurations

/etc/php/8.4/fpm/
├── php.ini            # PHP configuration
├── pool.d/            # PHP-FPM pool configurations
└── conf.d/            # PHP module configurations

/etc/mysql/mariadb.conf.d/
├── 50-server.cnf      # MariaDB server configuration
└── 99-seb-stack.cnf   # SEB Stack optimizations

/etc/redis/
└── redis.conf         # Redis configuration
```

## ⚙️ Stack Configuration

### **Main Configuration File**
Edit `/etc/seb-stack/stack.conf`:

```ini
[general]
# Stack version and settings
version=3.0.0
environment=production
debug=false
log_level=info

# Default domain settings
default_domain=example.com
admin_email=admin@example.com

# Paths
web_root=/var/www
backup_path=/var/backups/seb-stack
log_path=/var/log/seb-stack

[services]
# Service management
nginx=enabled
php-fpm=enabled
mariadb=enabled
redis=enabled
fail2ban=enabled
ufw=enabled

# Service auto-restart
auto_restart=true
restart_threshold=3
```

### **Apply Configuration Changes**
```bash
# Reload stack configuration
sudo seb-stack reload-config

# Restart specific service
sudo seb-stack restart nginx

# Restart all services
sudo seb-stack restart-all
```

## 🌐 Nginx Configuration

### **Main Nginx Settings**
Edit `/etc/nginx/nginx.conf`:

```nginx
# Main nginx configuration optimized for WordPress
user www-data;
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # File Upload Settings
    client_max_body_size 256M;
    client_body_timeout 60s;
    client_header_timeout 60s;
    
    # Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;
    
    # Brotli Compression
    brotli on;
    brotli_comp_level 6;
    brotli_types
        text/plain
        text/css
        application/json
        application/javascript
        text/xml
        application/xml
        application/xml+rss
        text/javascript;
}
```

### **Site-Specific Configuration**
Create `/etc/nginx/sites-available/example.com`:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;
    
    root /var/www/example.com/public;
    index index.php index.html;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # WordPress specific
    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt { log_not_found off; access_log off; allow all; }
    location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        
        # Security
        fastcgi_hide_header X-Powered-By;
        
        # Performance
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_read_timeout 300;
    }
    
    # Block access to sensitive files
    location ~* /(?:uploads|files)/.*\.php$ {
        deny all;
    }
    
    location ~ /\. {
        deny all;
    }
}
```

## 🐘 PHP Configuration

### **Main PHP Settings**
Edit `/etc/php/8.4/fpm/php.ini`:

```ini
[PHP]
# Core Settings
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
upload_max_filesize = 256M
post_max_size = 256M
max_file_uploads = 20

# Session Settings
session.save_handler = redis
session.save_path = "tcp://127.0.0.1:6379"
session.gc_maxlifetime = 1440
session.cookie_secure = 1
session.cookie_httponly = 1

# OPcache Settings
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
opcache.save_comments = 1
opcache.validate_timestamps = 0

# Security Settings
expose_php = Off
allow_url_fopen = Off
allow_url_include = Off
display_errors = Off
log_errors = On
error_log = /var/log/php/error.log

# WordPress Optimizations
auto_prepend_file = 
auto_append_file = 
default_mimetype = "text/html"
default_charset = "UTF-8"
```

### **PHP-FPM Pool Configuration**
Edit `/etc/php/8.4/fpm/pool.d/www.conf`:

```ini
[www]
user = www-data
group = www-data

listen = /var/run/php/php8.4-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

# Process Management
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 15
pm.max_requests = 1000

# Performance Tuning
request_terminate_timeout = 300
request_slowlog_timeout = 10s
slowlog = /var/log/php/fpm-slow.log

# Security
security.limit_extensions = .php .php3 .php4 .php5 .php7 .php8

# Environment Variables
env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
```

## 🗄️ MariaDB Configuration

### **Server Configuration**
Edit `/etc/mysql/mariadb.conf.d/99-seb-stack.cnf`:

```ini
[mysqld]
# Basic Settings
bind-address = 127.0.0.1
port = 3306
socket = /var/run/mysqld/mysqld.sock

# Character Set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# MyISAM Settings
key_buffer_size = 128M
myisam_recover_options = BACKUP,FORCE

# InnoDB Settings
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_log_buffer_size = 16M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50
innodb_file_per_table = 1

# Query Cache (disabled for modern MariaDB)
query_cache_type = 0
query_cache_size = 0

# Connection Settings
max_connections = 200
max_allowed_packet = 256M
thread_cache_size = 8
table_open_cache = 4096

# Logging
general_log = 0
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2
log_queries_not_using_indexes = 0

# Security
local_infile = 0
skip_show_database

[mysql]
default-character-set = utf8mb4

[mysqldump]
default-character-set = utf8mb4
```

### **Database Optimization Commands**
```bash
# Optimize all databases
sudo seb-stack optimize-db --all

# Repair specific database
sudo seb-stack repair-db wordpress

# Check database status
sudo seb-stack db-status

# Monitor slow queries
sudo tail -f /var/log/mysql/slow-query.log
```

## 🔴 Redis Configuration

### **Main Redis Settings**
Edit `/etc/redis/redis.conf`:

```ini
# Network
bind 127.0.0.1
port 6379
tcp-backlog 511
timeout 300

# General
daemonize yes
supervised systemd
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log

# Snapshotting
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis

# Memory Management
maxmemory 512mb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# Append Only File
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Security
requirepass your_redis_password
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""
rename-command CONFIG "CONFIG_a1b2c3d4"
```

### **Redis Performance Commands**
```bash
# Monitor Redis performance
redis-cli --latency-history -h 127.0.0.1

# Check Redis info
redis-cli info

# Monitor Redis commands
redis-cli monitor

# Clear Redis cache
sudo seb-stack clear-cache redis
```

## 🛡️ Security Configuration

### **UFW Firewall Settings**
```bash
# Configure firewall rules
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (change port if needed)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

### **Fail2Ban Configuration**
Edit `/etc/fail2ban/jail.local`:

```ini
[DEFAULT]
# Ban settings
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

# Email settings
destemail = admin@example.com
sender = fail2ban@example.com
mta = sendmail
action = %(action_mwl)s

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[wordpress]
enabled = true
port = http,https
logpath = /var/log/auth.log
maxretry = 3
```

## 📊 Monitoring Configuration

### **System Monitoring**
Edit `/etc/seb-stack/monitoring.conf`:

```ini
[monitoring]
# Enable monitoring
enabled = true
check_interval = 60
alert_threshold = 80

# Services to monitor
services = nginx,php8.4-fpm,mariadb,redis-server

# Resource monitoring
cpu_threshold = 80
memory_threshold = 85
disk_threshold = 90
load_threshold = 2.0

# Alerts
email_alerts = true
slack_webhook = https://hooks.slack.com/your-webhook
```

### **Log Rotation**
Create `/etc/logrotate.d/seb-stack`:

```
/var/log/seb-stack/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 0644 root root
    postrotate
        systemctl reload seb-stack
    endscript
}
```

## 🔄 Configuration Management Commands

### **Configuration Commands**
```bash
# View current configuration
sudo seb-stack config show

# Edit configuration
sudo seb-stack config edit stack

# Validate configuration
sudo seb-stack config validate

# Backup configuration
sudo seb-stack config backup

# Restore configuration
sudo seb-stack config restore backup-file.tar.gz

# Reset to defaults
sudo seb-stack config reset --component=nginx
```

### **Service Management**
```bash
# Check service status
sudo seb-stack status

# Restart specific service
sudo seb-stack restart nginx

# Reload configuration without restart
sudo seb-stack reload php-fpm

# Test configuration syntax
sudo seb-stack test nginx
sudo seb-stack test php
```

---

**Next:** Learn about [Performance Tuning](../performance/) to optimize your stack for maximum speed.
