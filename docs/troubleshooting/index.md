---
layout: default
title: Troubleshooting
description: Comprehensive troubleshooting guide for SEB Ultra Stack
---

# 🚨 Troubleshooting Guide

Diagnose and resolve issues quickly with this comprehensive troubleshooting guide for SEB Ultra Stack.

## 🔍 Quick Diagnostic Commands

### **Stack Health Check**
```bash
# Complete stack status
sudo seb-stack status --detailed

# Quick health check
sudo seb-stack health-check

# Service status overview
sudo systemctl status nginx php8.4-fpm mariadb redis-server

# Check all stack processes
sudo seb-stack ps
```

### **Instant Issue Detection**
```bash
# Check recent errors across all services
sudo seb-stack logs --errors --last-hour

# Performance issues
sudo seb-stack performance-check --quick

# Security issues
sudo seb-stack security-scan --quick

# Configuration validation
sudo seb-stack config-validate --all
```

## 🌐 Nginx Troubleshooting

### **Common Nginx Issues**

#### **Site Not Loading (502 Bad Gateway)**
```bash
# Check Nginx status
sudo systemctl status nginx

# Test configuration
sudo nginx -t

# Check PHP-FPM status
sudo systemctl status php8.4-fpm

# Check PHP-FPM socket
ls -la /var/run/php/php8.4-fpm.sock

# Restart services in order
sudo systemctl restart php8.4-fpm
sudo systemctl restart nginx

# Check error logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/php8.4-fpm.log
```

#### **Site Loading Slowly**
```bash
# Check Nginx access logs for slow requests
sudo awk '$NF > 1 {print $0}' /var/log/nginx/access.log

# Check worker connections
sudo nginx -s reload  # Reload configuration
ps aux | grep nginx   # Check worker processes

# Monitor real-time connections
sudo netstat -tuln | grep :80
sudo netstat -tuln | grep :443

# Check if rate limiting is affecting performance
sudo grep "limiting requests" /var/log/nginx/error.log
```

#### **SSL Certificate Issues**
```bash
# Check certificate status
sudo certbot certificates

# Test SSL configuration
openssl s_client -connect example.com:443 -servername example.com

# Verify certificate chain
curl -vI https://example.com

# Renew certificates if expired
sudo certbot renew --force-renewal

# Check certificate expiration
echo | openssl s_client -servername example.com -connect example.com:443 2>/dev/null | openssl x509 -noout -dates
```

### **Nginx Configuration Debugging**
```bash
# Test configuration syntax
sudo nginx -t -c /etc/nginx/nginx.conf

# Check configuration details
sudo nginx -T | grep -A 10 -B 10 "error\|warning"

# Validate specific site configuration
sudo nginx -t -c /etc/nginx/sites-available/example.com

# Check virtual host conflicts
sudo nginx -T | grep "server_name"

# Debug rewrite rules
# Add to location block temporarily:
# error_log /var/log/nginx/rewrite.log notice;
# rewrite_log on;
```

## 🐘 PHP Troubleshooting

### **PHP-FPM Issues**

#### **PHP Not Processing (White Screen)**
```bash
# Check PHP-FPM status
sudo systemctl status php8.4-fpm

# Check PHP error logs
sudo tail -f /var/log/php8.4-fpm.log

# Check PHP configuration
php --ini
php -m  # List loaded modules

# Test PHP processing
echo "<?php phpinfo(); ?>" | sudo tee /var/www/example.com/test.php
curl http://example.com/test.php

# Check memory limits
php -r "echo ini_get('memory_limit').PHP_EOL;"

# Check execution time limits
php -r "echo ini_get('max_execution_time').PHP_EOL;"
```

#### **PHP Memory Issues**
```bash
# Monitor PHP memory usage
sudo grep "Fatal error: Allowed memory" /var/log/php8.4-fpm.log

# Check current memory limit
php -r "echo ini_get('memory_limit').PHP_EOL;"

# Temporary memory limit increase
echo "memory_limit = 1024M" | sudo tee /etc/php/8.4/fpm/conf.d/99-memory-temp.ini

# Monitor PHP processes memory usage
ps aux --sort=-%mem | grep php

# Check WordPress memory usage
wp eval "echo WP_MEMORY_LIMIT . PHP_EOL; echo WP_MAX_MEMORY_LIMIT . PHP_EOL;"
```

#### **PHP Session Issues**
```bash
# Check session configuration
php -r "echo 'Session save handler: ' . ini_get('session.save_handler') . PHP_EOL;"
php -r "echo 'Session save path: ' . ini_get('session.save_path') . PHP_EOL;"

# Check Redis session storage
redis-cli keys "PHPREDIS_SESSION:*"

# Test session functionality
php -r "
session_start();
\$_SESSION['test'] = 'working';
session_write_close();
session_start();
echo 'Session test: ' . \$_SESSION['test'] . PHP_EOL;
"

# Check session directory permissions (if using files)
ls -la /var/lib/php/sessions/
```

### **OPcache Issues**
```bash
# Check OPcache status
php -r "var_dump(opcache_get_status());"

# Clear OPcache
php -r "opcache_reset();"

# Check OPcache configuration
php --ini | grep opcache

# Monitor OPcache hit rate
php -r "
\$status = opcache_get_status();
\$hit_rate = \$status['opcache_statistics']['opcache_hit_rate'];
echo 'OPcache hit rate: ' . \$hit_rate . '%' . PHP_EOL;
"

# Check for OPcache errors
sudo grep -i opcache /var/log/php8.4-fpm.log
```

## 🗄️ Database Troubleshooting

### **MariaDB Connection Issues**

#### **Can't Connect to Database**
```bash
# Check MariaDB status
sudo systemctl status mariadb

# Test database connection
mysql -u root -p -e "SELECT VERSION();"

# Check database logs
sudo tail -f /var/log/mysql/error.log

# Check listening ports
sudo netstat -tuln | grep :3306

# Test WordPress database connection
wp db check

# Check database user permissions
mysql -u root -p -e "SELECT User, Host FROM mysql.user;"
mysql -u root -p -e "SHOW GRANTS FOR 'wp_user'@'localhost';"
```

#### **Database Performance Issues**
```bash
# Check slow query log
sudo tail -f /var/log/mysql/slow-query.log

# Show currently running queries
mysql -u root -p -e "SHOW PROCESSLIST;"

# Check database locks
mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G" | grep -A 20 "TRANSACTIONS"

# Database size analysis
mysql -u root -p -e "
SELECT 
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables 
GROUP BY table_schema;"

# Check table status
wp db query "SHOW TABLE STATUS WHERE Engine='InnoDB';" | head -20
```

#### **Database Corruption Issues**
```bash
# Check and repair tables
mysql -u root -p -e "CHECK TABLE wp_posts, wp_postmeta, wp_options;"
mysql -u root -p -e "REPAIR TABLE wp_posts, wp_postmeta, wp_options;"

# WordPress database repair
wp db repair

# Check InnoDB status
mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G"

# Force InnoDB recovery (use with caution)
# Add to /etc/mysql/mariadb.conf.d/50-server.cnf:
# innodb_force_recovery = 1
# Then restart MariaDB
```

### **Database Configuration Issues**
```bash
# Check current configuration
mysql -u root -p -e "SHOW VARIABLES LIKE '%buffer%';"
mysql -u root -p -e "SHOW VARIABLES LIKE '%timeout%';"

# Monitor database connections
mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';"
mysql -u root -p -e "SHOW STATUS LIKE 'Max_used_connections';"

# Check query cache (if enabled)
mysql -u root -p -e "SHOW STATUS LIKE 'Qcache%';"
```

## 🔴 Redis Troubleshooting

### **Redis Connection Issues**
```bash
# Check Redis status
sudo systemctl status redis-server

# Test Redis connection
redis-cli ping

# Check Redis logs
sudo tail -f /var/log/redis/redis-server.log

# Check Redis configuration
redis-cli config get "*"

# Monitor Redis in real-time
redis-cli monitor

# Check Redis memory usage
redis-cli info memory
```

### **Redis Performance Issues**
```bash
# Check Redis stats
redis-cli info stats

# Monitor slow queries
redis-cli config set slowlog-log-slower-than 10000
redis-cli slowlog get 10

# Check connected clients
redis-cli info clients

# Monitor keyspace
redis-cli info keyspace

# Check for blocking operations
redis-cli info persistence
```

### **WordPress Redis Cache Issues**
```bash
# Check WordPress Redis connection
wp redis status

# Flush WordPress cache
wp cache flush
wp redis flush

# Check Redis keys used by WordPress
redis-cli keys "wp:*" | head -10

# Test object cache functionality
wp eval "
if ( wp_cache_set( 'test_key', 'test_value', 'test_group' ) ) {
    echo 'Cache set successful' . PHP_EOL;
    if ( wp_cache_get( 'test_key', 'test_group' ) === 'test_value' ) {
        echo 'Cache get successful' . PHP_EOL;
    }
}
"
```

## 🔒 SSL/TLS Troubleshooting

### **SSL Certificate Issues**
```bash
# Check certificate validity
openssl x509 -in /etc/letsencrypt/live/example.com/fullchain.pem -text -noout

# Test SSL connection
openssl s_client -connect example.com:443 -servername example.com

# Check certificate chain
curl -I https://example.com

# Verify certificate with external tools
# Use online tools: SSL Labs, SSL Checker

# Check for mixed content
curl -sL https://example.com | grep -i "http://"

# Test specific SSL ciphers
nmap --script ssl-enum-ciphers -p 443 example.com
```

### **Let's Encrypt Issues**
```bash
# Check Certbot status
sudo certbot certificates

# Test certificate renewal
sudo certbot renew --dry-run

# Manual certificate generation
sudo certbot certonly --manual -d example.com

# Check Certbot logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Fix common Certbot issues
sudo certbot delete --cert-name example.com
sudo certbot certonly --nginx -d example.com
```

## 📊 Performance Troubleshooting

### **High CPU Usage**
```bash
# Identify CPU-intensive processes
top -o %CPU
htop  # If available

# Check Apache/Nginx worker processes
ps aux | grep -E "(nginx|php-fpm)" | head -10

# Monitor system load
uptime
cat /proc/loadavg

# Check for runaway processes
ps aux --sort=-%cpu | head -20

# MySQL process monitoring
mysql -u root -p -e "SHOW PROCESSLIST;" | grep -v "Sleep"

# WordPress-specific CPU debugging
wp profile stage --all --spotlight
```

### **High Memory Usage**
```bash
# Memory usage overview
free -h
cat /proc/meminfo

# Process memory usage
ps aux --sort=-%mem | head -20

# Check for memory leaks
sudo pmap $(pgrep -f nginx) | tail -1
sudo pmap $(pgrep -f php-fpm) | tail -1

# MySQL memory usage
mysql -u root -p -e "SHOW STATUS LIKE 'innodb_buffer_pool%';"

# Check swap usage
swapon --show
vmstat 1 5
```

### **Disk I/O Issues**
```bash
# Monitor disk I/O
iostat -x 1 5
iotop  # If available

# Check disk usage
df -h
du -sh /var/www/* | sort -hr

# Find large files
find /var/www -type f -size +100M -exec ls -lh {} \;

# Check database disk usage
du -sh /var/lib/mysql/*

# Monitor slow disk operations
sudo tail -f /var/log/mysql/slow-query.log
```

## 🌐 WordPress-Specific Troubleshooting

### **WordPress Won't Load**
```bash
# Enable WordPress debugging
wp config set WP_DEBUG true
wp config set WP_DEBUG_LOG true
wp config set WP_DEBUG_DISPLAY false

# Check WordPress error logs
tail -f /var/www/example.com/wp-content/debug.log

# Test WordPress connectivity
wp cli info
wp option get home
wp option get siteurl

# Check file permissions
find /var/www/example.com -type f -exec chmod 644 {} \;
find /var/www/example.com -type d -exec chmod 755 {} \;
chmod 600 /var/www/example.com/wp-config.php

# Database connection test
wp db check
```

### **Plugin/Theme Issues**
```bash
# Deactivate all plugins
wp plugin deactivate --all

# Activate default theme
wp theme activate twentytwentyfour

# Check for plugin conflicts
wp plugin activate --all
wp plugin list --status=inactive

# Check theme functionality
wp theme list
wp eval "if (function_exists('wp_get_theme')) { var_dump(wp_get_theme()); }"

# Plugin debugging
wp plugin get problematic-plugin
```

### **WordPress Performance Issues**
```bash
# Database optimization
wp db optimize

# Clear all caches
wp cache flush
wp transient delete --expired
wp rewrite flush

# Check slow queries
wp db query "SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;"

# Profile WordPress performance
wp profile stage --all
```

## 🔐 Security Troubleshooting

### **Malware Detection**
```bash
# Scan for malware
sudo clamscan -r /var/www/ --infected --remove

# Check for suspicious files
find /var/www -name "*.php" -exec grep -l "eval\|base64_decode\|gzinflate" {} \;

# WordPress security scan
wp malcare scan  # If plugin installed
wp security check  # WordPress CLI security check

# Check file integrity
sudo aide --check

# Monitor file changes
find /var/www -type f -newermt "1 hour ago" -ls
```

### **Failed Login Issues**
```bash
# Check failed logins
sudo grep "Failed password" /var/log/auth.log | tail -20

# Check WordPress login attempts
sudo grep "wp-login" /var/log/nginx/access.log | grep -E "(404|403)" | tail -20

# Fail2Ban status
sudo fail2ban-client status
sudo fail2ban-client status wordpress

# Check banned IPs
sudo fail2ban-client status sshd
sudo iptables -L -n | grep DROP
```

### **Firewall Issues**
```bash
# Check UFW status
sudo ufw status verbose

# Test port connectivity
telnet example.com 80
telnet example.com 443

# Check iptables rules
sudo iptables -L -n

# Monitor blocked connections
sudo tail -f /var/log/ufw.log

# Test from external location
curl -I http://example.com
```

## 📧 Email Issues

### **WordPress Email Not Working**
```bash
# Test mail functionality
echo "Test email body" | mail -s "Test Subject" admin@example.com

# WordPress mail test
wp eval "wp_mail('test@example.com', 'Test Subject', 'Test message');"

# Check mail logs
sudo tail -f /var/log/mail.log

# Test SMTP configuration (if using SMTP plugin)
wp config get PHPMAILER_SMTP_HOST
wp config get PHPMAILER_SMTP_PORT

# Check mail queue
mailq
```

## 🔧 System-Level Troubleshooting

### **Service Management**
```bash
# Check all services status
sudo systemctl list-units --type=service --state=failed

# Restart services in correct order
sudo systemctl restart mariadb
sudo systemctl restart redis-server
sudo systemctl restart php8.4-fpm
sudo systemctl restart nginx

# Check service logs
sudo journalctl -u nginx -f
sudo journalctl -u php8.4-fpm -f
sudo journalctl -u mariadb -f

# Enable services for auto-start
sudo systemctl enable nginx php8.4-fpm mariadb redis-server
```

### **Network Connectivity**
```bash
# Check network connectivity
ping -c 4 8.8.8.8
ping -c 4 google.com

# DNS resolution test
nslookup example.com
dig example.com

# Port connectivity
nc -zv example.com 80
nc -zv example.com 443

# Check listening ports
sudo netstat -tuln
sudo ss -tuln

# Network interface status
ip addr show
ifconfig -a
```

### **File System Issues**
```bash
# Check disk health
sudo smartctl -a /dev/sda

# File system check
sudo fsck /dev/sda1

# Check disk errors
dmesg | grep -i error
sudo tail -f /var/log/syslog | grep -i error

# File permissions audit
find /var/www -type f \( -perm -002 -o -perm -020 \) -ls

# Check for corrupted files
find /var/www -type f -name "*.php" -exec php -l {} \; | grep -v "No syntax errors"
```

## 🚨 Emergency Recovery Procedures

### **Complete Stack Recovery**
```bash
#!/bin/bash
# Emergency stack recovery script

echo "Starting emergency recovery..."

# Stop all services
sudo systemctl stop nginx php8.4-fpm mariadb redis-server

# Check and repair file systems
sudo fsck -y /dev/sda1

# Start services one by one
sudo systemctl start mariadb
sleep 5

# Test database
if mysql -u root -p -e "SELECT 1;" > /dev/null 2>&1; then
    echo "Database OK"
else
    echo "Database failed - attempting repair"
    sudo systemctl stop mariadb
    sudo mysqld_safe --skip-grant-tables --skip-networking &
    sleep 10
    mysql -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_password';"
    sudo pkill mysqld
    sudo systemctl start mariadb
fi

# Start Redis
sudo systemctl start redis-server
redis-cli ping

# Start PHP-FPM
sudo systemctl start php8.4-fpm

# Test PHP
php -v

# Start Nginx
sudo nginx -t
sudo systemctl start nginx

# Test web connectivity
curl -I http://localhost

echo "Emergency recovery completed"
```

### **Database Emergency Recovery**
```bash
#!/bin/bash
# Database emergency recovery

BACKUP_DIR="/var/backups/emergency"
mkdir -p $BACKUP_DIR

echo "Database emergency recovery starting..."

# Stop applications
sudo systemctl stop nginx php8.4-fpm

# Backup current state (if possible)
mysqldump --all-databases > $BACKUP_DIR/emergency_backup_$(date +%Y%m%d_%H%M%S).sql

# Check for corruption
mysql -u root -p -e "CHECK TABLE mysql.user;"

# Repair system tables
mysql_upgrade --force

# Check InnoDB status
mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G" | grep -A 10 "LATEST DETECTED DEADLOCK"

# If severe corruption, restore from backup
read -p "Restore from latest backup? (y/N): " restore_choice
if [ "$restore_choice" = "y" ]; then
    LATEST_BACKUP=$(ls -t /var/backups/databases/*.sql.gz | head -1)
    if [ -f "$LATEST_BACKUP" ]; then
        echo "Restoring from: $LATEST_BACKUP"
        gunzip -c "$LATEST_BACKUP" | mysql -u root -p
    fi
fi

# Restart services
sudo systemctl start mariadb php8.4-fpm nginx

echo "Database recovery completed"
```

## 📋 Diagnostic Information Collection

### **System Information Script**
Create `/usr/local/bin/collect-diagnostics.sh`:

```bash
#!/bin/bash

DIAG_DIR="/tmp/seb-stack-diagnostics-$(date +%Y%m%d_%H%M%S)"
mkdir -p $DIAG_DIR

echo "Collecting SEB Ultra Stack diagnostic information..."
echo "Output directory: $DIAG_DIR"

# System information
echo "=== SYSTEM INFORMATION ===" > $DIAG_DIR/system-info.txt
uname -a >> $DIAG_DIR/system-info.txt
lsb_release -a >> $DIAG_DIR/system-info.txt 2>/dev/null
uptime >> $DIAG_DIR/system-info.txt
free -h >> $DIAG_DIR/system-info.txt
df -h >> $DIAG_DIR/system-info.txt

# Service status
echo "=== SERVICE STATUS ===" > $DIAG_DIR/service-status.txt
systemctl status nginx >> $DIAG_DIR/service-status.txt
systemctl status php8.4-fpm >> $DIAG_DIR/service-status.txt
systemctl status mariadb >> $DIAG_DIR/service-status.txt
systemctl status redis-server >> $DIAG_DIR/service-status.txt

# Configuration files
mkdir -p $DIAG_DIR/configs
cp -r /etc/nginx/nginx.conf $DIAG_DIR/configs/ 2>/dev/null
cp -r /etc/php/8.4/fpm/php.ini $DIAG_DIR/configs/ 2>/dev/null
cp -r /etc/mysql/mariadb.conf.d/ $DIAG_DIR/configs/ 2>/dev/null
cp -r /etc/redis/redis.conf $DIAG_DIR/configs/ 2>/dev/null

# Log files (last 1000 lines)
mkdir -p $DIAG_DIR/logs
tail -1000 /var/log/nginx/error.log > $DIAG_DIR/logs/nginx-error.log 2>/dev/null
tail -1000 /var/log/php8.4-fpm.log > $DIAG_DIR/logs/php-fpm.log 2>/dev/null
tail -1000 /var/log/mysql/error.log > $DIAG_DIR/logs/mysql-error.log 2>/dev/null
tail -1000 /var/log/redis/redis-server.log > $DIAG_DIR/logs/redis.log 2>/dev/null

# Process information
ps aux > $DIAG_DIR/processes.txt
netstat -tuln > $DIAG_DIR/network-ports.txt

# WordPress information (if available)
if command -v wp &> /dev/null; then
    echo "=== WORDPRESS INFORMATION ===" > $DIAG_DIR/wordpress-info.txt
    wp --version >> $DIAG_DIR/wordpress-info.txt 2>/dev/null
    wp core version >> $DIAG_DIR/wordpress-info.txt 2>/dev/null
    wp plugin list >> $DIAG_DIR/wordpress-info.txt 2>/dev/null
    wp theme list >> $DIAG_DIR/wordpress-info.txt 2>/dev/null
fi

# Database status
if command -v mysql &> /dev/null; then
    echo "=== DATABASE STATUS ===" > $DIAG_DIR/database-status.txt
    mysql -u root -p -e "SHOW STATUS;" >> $DIAG_DIR/database-status.txt 2>/dev/null
    mysql -u root -p -e "SHOW VARIABLES;" >> $DIAG_DIR/database-status.txt 2>/dev/null
    mysql -u root -p -e "SHOW PROCESSLIST;" >> $DIAG_DIR/database-status.txt 2>/dev/null
fi

# Create archive
cd /tmp
tar -czf seb-stack-diagnostics-$(date +%Y%m%d_%H%M%S).tar.gz $(basename $DIAG_DIR)
echo "Diagnostic archive created: /tmp/seb-stack-diagnostics-$(date +%Y%m%d_%H%M%S).tar.gz"

# Clean up directory
rm -rf $DIAG_DIR

echo "Diagnostic collection completed"
```

### **Performance Diagnostic Script**
Create `/usr/local/bin/performance-diagnostics.sh`:

```bash
#!/bin/bash

echo "=== SEB ULTRA STACK PERFORMANCE DIAGNOSTICS ==="
echo "Timestamp: $(date)"
echo ""

# CPU Information
echo "=== CPU INFORMATION ==="
cat /proc/cpuinfo | grep -E "(model name|cpu cores|cache size)" | head -3
echo "Current load average: $(cat /proc/loadavg)"
echo "CPU usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo ""

# Memory Information
echo "=== MEMORY INFORMATION ==="
free -h
echo ""
echo "Top 10 memory-consuming processes:"
ps aux --sort=-%mem | head -11
echo ""

# Disk I/O
echo "=== DISK I/O INFORMATION ==="
df -h
echo ""
iostat -x 1 1
echo ""

# Network Statistics
echo "=== NETWORK STATISTICS ==="
ss -tuln | grep -E "(80|443|3306|6379)"
echo ""
echo "Active connections to web server:"
netstat -an | grep -E ":80|:443" | grep ESTABLISHED | wc -l
echo ""

# Database Performance
echo "=== DATABASE PERFORMANCE ==="
if command -v mysql &> /dev/null; then
    mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null
    mysql -u root -p -e "SHOW STATUS LIKE 'Slow_queries';" 2>/dev/null
    mysql -u root -p -e "SHOW STATUS LIKE 'Queries';" 2>/dev/null
    echo "Database size:"
    mysql -u root -p -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables GROUP BY table_schema;" 2>/dev/null
fi
echo ""

# Web Server Performance
echo "=== WEB SERVER PERFORMANCE ==="
echo "Nginx worker processes: $(ps aux | grep "nginx: worker" | wc -l)"
echo "PHP-FPM processes: $(ps aux | grep "php-fpm: pool" | wc -l)"
echo ""

# Cache Status
echo "=== CACHE STATUS ==="
if command -v redis-cli &> /dev/null; then
    echo "Redis status: $(redis-cli ping)"
    redis-cli info stats | grep -E "(keyspace_hits|keyspace_misses|connected_clients)"
fi
echo ""

# WordPress Performance (if available)
echo "=== WORDPRESS PERFORMANCE ==="
if command -v wp &> /dev/null; then
    echo "WordPress version: $(wp core version 2>/dev/null)"
    echo "Active plugins: $(wp plugin list --status=active --format=count 2>/dev/null)"
    echo "Database size: $(wp db size --human-readable 2>/dev/null)"
fi

echo ""
echo "=== END OF PERFORMANCE DIAGNOSTICS ==="
```

## 🛠️ Troubleshooting Tools and Scripts

### **Log Analysis Script**
Create `/usr/local/bin/analyze-logs.sh`:

```bash
#!/bin/bash

LOG_PERIOD=${1:-"1 hour ago"}
echo "Analyzing logs from: $LOG_PERIOD"
echo "================================"

# Nginx Error Analysis
echo "=== NGINX ERRORS ==="
if [ -f /var/log/nginx/error.log ]; then
    echo "Recent Nginx errors:"
    sudo awk -v d="$(date -d "$LOG_PERIOD" "+%Y/%m/%d %H:%M:%S")" '$0 > d' /var/log/nginx/error.log | tail -20
    
    echo ""
    echo "Top error types:"
    sudo awk -v d="$(date -d "$LOG_PERIOD" "+%Y/%m/%d %H:%M:%S")" '$0 > d' /var/log/nginx/error.log | \
        grep -oE '\[error\] [0-9]+#[0-9]+: [^,]*' | cut -d: -f2 | sort | uniq -c | sort -nr | head -10
fi
echo ""

# PHP Error Analysis
echo "=== PHP ERRORS ==="
if [ -f /var/log/php8.4-fpm.log ]; then
    echo "Recent PHP errors:"
    sudo awk -v d="$(date -d "$LOG_PERIOD" "+%d-%b-%Y %H:%M:%S")" '$0 > d' /var/log/php8.4-fpm.log | tail -20
fi
echo ""

# Database Error Analysis
echo "=== DATABASE ERRORS ==="
if [ -f /var/log/mysql/error.log ]; then
    echo "Recent MySQL errors:"
    sudo awk -v d="$(date -d "$LOG_PERIOD" "+%Y-%m-%d %H:%M:%S")" '$0 > d' /var/log/mysql/error.log | tail -20
fi
echo ""

# WordPress Error Analysis
echo "=== WORDPRESS ERRORS ==="
for debug_log in /var/www/*/wp-content/debug.log; do
    if [ -f "$debug_log" ]; then
        echo "WordPress errors in: $debug_log"
        sudo awk -v d="$(date -d "$LOG_PERIOD" "+%d-%b-%Y %H:%M:%S")" '$0 > d' "$debug_log" | tail -10
    fi
done
echo ""

# System Log Analysis
echo "=== SYSTEM ERRORS ==="
if [ -f /var/log/syslog ]; then
    echo "Recent system errors:"
    sudo awk -v d="$(date -d "$LOG_PERIOD" "+%b %d %H:%M:%S")" '$0 > d' /var/log/syslog | grep -i error | tail -20
fi

echo "================================"
echo "Log analysis completed"
```

## 🔧 Common Issues Quick Reference

### **Issue Priority Matrix**
```
CRITICAL (Fix Immediately):
├─ Site completely down (502/503 errors)
├─ Database connection lost
├─ SSL certificate expired
├─ Security breach detected
└─ Data corruption

HIGH (Fix within 1 hour):
├─ Slow page load times (>5 seconds)
├─ Intermittent 502 errors
├─ High server resource usage
├─ Email not working
└─ Payment gateway issues

MEDIUM (Fix within 24 hours):
├─ Plugin conflicts
├─ Image upload issues
├─ Cache not working properly
├─ Minor configuration errors
└─ Non-critical warnings in logs

LOW (Fix when convenient):
├─ Cosmetic issues
├─ Minor performance optimizations
├─ Documentation updates
└─ Non-essential feature problems
```

### **Quick Fix Commands**
```bash
# Emergency restart of all services
sudo systemctl restart mariadb redis-server php8.4-fpm nginx

# Clear all caches
wp cache flush && redis-cli flushall && sudo systemctl reload nginx

# Fix file permissions
sudo find /var/www -type f -exec chmod 644 {} \; && sudo find /var/www -type d -exec chmod 755 {} \;

# Database quick fix
wp db repair && wp db optimize

# SSL certificate renewal
sudo certbot renew --force-renewal && sudo systemctl reload nginx

# Clear PHP OPcache
php -r "opcache_reset();" && sudo systemctl reload php8.4-fpm
```

## 📞 Getting Help

### **Information to Collect Before Seeking Support**
1. **System Information**:
   - OS version: `lsb_release -a`
   - SEB Stack version: `sudo seb-stack version`
   - Server specifications (CPU, RAM, disk)

2. **Error Details**:
   - Exact error messages
   - When the issue started
   - Steps to reproduce
   - What changed recently

3. **Log Files**:
   - Run diagnostic collection script
   - Include relevant log excerpts
   - Error timestamps

4. **Current Status**:
   - Service status: `sudo seb-stack status`
   - Recent changes made
   - Troubleshooting steps already tried

### **Support Channels**
- 💬 **Discord Community**: Real-time help from community
- 📧 **Email Support**: Technical support team
- 🐛 **GitHub Issues**: Bug reports and feature requests
- 📚 **Documentation**: Comprehensive guides and tutorials

### **Self-Help Resources**
```bash
# Built-in help commands
sudo seb-stack help
sudo seb-stack docs
sudo seb-stack troubleshoot --interactive

# Check system health
sudo seb-stack health-check --verbose

# Run built-in diagnostics
sudo seb-stack diagnose --full-report
```

---

**Next:** Check the [FAQ](../faq/) for answers to frequently asked questions.
