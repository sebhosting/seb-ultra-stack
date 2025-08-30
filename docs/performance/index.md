---
layout: default
title: Performance Tuning
description: Optimize SEB Ultra Stack for maximum speed and performance
---

# 🚀 Performance Tuning

Transform your SEB Ultra Stack into a speed demon with these comprehensive performance optimization techniques.

## 📊 Performance Baseline

Before optimization, establish baseline metrics:

```bash
# Run performance diagnostics
sudo seb-stack performance-report

# Check current page load times
curl -w "@curl-format.txt" -o /dev/null -s https://example.com

# Monitor resource usage
sudo seb-stack monitor --duration=300
```

### **Target Performance Metrics**
| Metric | Target | Excellent |
|--------|---------|-----------|
| TTFB (Time to First Byte) | < 200ms | < 100ms |
| Page Load Time | < 1.0s | < 0.5s |
| Core Web Vitals LCP | < 2.5s | < 1.5s |
| Database Query Time | < 50ms | < 20ms |
| Cache Hit Rate | > 90% | > 95% |

## ⚡ Quick Performance Wins

### **Enable All Caching**
```bash
# Enable full caching stack
sudo seb-stack enable-cache --all

# Verify cache status
sudo seb-stack cache-status
```

### **Optimize Database**
```bash
# Run database optimization
sudo seb-stack optimize-db --full

# Enable query cache
sudo seb-stack enable-query-cache

# Index optimization
sudo seb-stack optimize-indexes
```

### **Enable Compression**
```bash
# Enable Gzip and Brotli
sudo seb-stack enable-compression

# Test compression
curl -H "Accept-Encoding: gzip" -I https://example.com
```

## 🔥 Nginx Performance Optimization

### **Advanced Nginx Configuration**
Edit `/etc/nginx/conf.d/performance.conf`:

```nginx
# Worker optimization
worker_processes auto;
worker_rlimit_nofile 100000;
worker_connections 4096;

# Enable efficient file serving
sendfile on;
tcp_nopush on;
tcp_nodelay on;

# Optimize keepalive
keepalive_timeout 30s;
keepalive_requests 1000;

# Buffer optimization
client_body_buffer_size 256k;
client_header_buffer_size 3m;
large_client_header_buffers 4 256k;
output_buffers 1 32k;
postpone_output 1460;

# Static file caching
location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt|tar|gz)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary Accept-Encoding;
    access_log off;
    
    # Enable zero-copy for large files
    sendfile on;
    tcp_nopush on;
    tcp_nodelay off;
}

# Enable microcaching for dynamic content
location / {
    set $skip_cache 0;
    
    # Skip cache for POST requests
    if ($request_method = POST) {
        set $skip_cache 1;
    }
    
    # Skip cache for URLs with query strings
    if ($query_string != "") {
        set $skip_cache 1;
    }
    
    # Skip cache for WordPress admin/login
    if ($request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") {
        set $skip_cache 1;
    }
    
    # Skip cache for logged in users
    if ($http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
        set $skip_cache 1;
    }
    
    fastcgi_cache_bypass $skip_cache;
    fastcgi_no_cache $skip_cache;
    fastcgi_cache WORDPRESS;
    fastcgi_cache_valid 200 301 302 1m;
    fastcgi_cache_use_stale error timeout updating http_500 http_503;
    fastcgi_cache_min_uses 1;
    fastcgi_cache_lock on;
    add_header X-Cache-Status $upstream_cache_status;
}
```

### **FastCGI Cache Setup**
Create `/etc/nginx/conf.d/fastcgi-cache.conf`:

```nginx
# FastCGI cache configuration
fastcgi_cache_path /var/cache/nginx/fastcgi 
    levels=1:2 
    keys_zone=WORDPRESS:100m 
    max_size=5g 
    inactive=60m 
    use_temp_path=off;

fastcgi_cache_key "$scheme$request_method$host$request_uri";
fastcgi_cache_methods GET HEAD;
fastcgi_ignore_headers Cache-Control Expires Set-Cookie;
```

### **Rate Limiting**
Add to `/etc/nginx/conf.d/rate-limit.conf`:

```nginx
# Rate limiting zones
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=search:10m rate=3r/s;

# Apply rate limits
location = /wp-login.php {
    limit_req zone=login burst=2 nodelay;
    include fastcgi_params;
    fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
}

location ~ /wp-json/ {
    limit_req zone=api burst=5 nodelay;
    include fastcgi_params;
    fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
}
```

## 🐘 PHP Performance Tuning

### **Advanced PHP-FPM Configuration**
Edit `/etc/php/8.4/fpm/pool.d/www.conf`:

```ini
[www]
# Process management optimization
pm = dynamic
pm.max_children = 100
pm.start_servers = 20
pm.min_spare_servers = 10
pm.max_spare_servers = 30
pm.process_idle_timeout = 10s
pm.max_requests = 1000

# Performance settings
request_terminate_timeout = 120
request_slowlog_timeout = 5s
rlimit_files = 65536
rlimit_core = 0

# Status and monitoring
pm.status_path = /fpm-status
ping.path = /fpm-ping
ping.response = pong

# Security and logging
catch_workers_output = yes
decorate_workers_output = no
```

### **OPcache Optimization**
Edit `/etc/php/8.4/mods-available/opcache.ini`:

```ini
; OPcache settings for maximum performance
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=512
opcache.interned_strings_buffer=64
opcache.max_accelerated_files=32531
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=0
opcache.revalidate_freq=0
opcache.save_comments=1
opcache.enable_file_override=0
opcache.optimization_level=0x7FFFBFFF
opcache.dups_fix=0
opcache.blacklist_filename=""

; JIT configuration for PHP 8.4
opcache.jit_buffer_size=256M
opcache.jit=1255
opcache.jit_hot_loop=64
opcache.jit_hot_func=16
opcache.jit_hot_return=8
opcache.jit_hot_side_exit=8
```

### **PHP Memory and Resource Limits**
Edit `/etc/php/8.4/fpm/php.ini`:

```ini
; Memory settings
memory_limit = 1024M
max_execution_time = 300
max_input_time = 300
max_input_vars = 3000

; File upload optimization
upload_max_filesize = 512M
post_max_size = 512M
max_file_uploads = 50

; Session optimization
session.save_handler = redis
session.save_path = "tcp://127.0.0.1:6379?weight=1&timeout=2.5&database=0"
session.gc_maxlifetime = 7200
session.cookie_lifetime = 0

; Realpath cache optimization
realpath_cache_size = 4M
realpath_cache_ttl = 600
```

## 🗄️ MariaDB Performance Optimization

### **Advanced MariaDB Tuning**
Edit `/etc/mysql/mariadb.conf.d/99-performance.cnf`:

```ini
[mysqld]
# InnoDB Performance
innodb_buffer_pool_size = 4G
innodb_buffer_pool_instances = 4
innodb_log_file_size = 1G
innodb_log_buffer_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
innodb_file_per_table = 1
innodb_io_capacity = 1000
innodb_io_capacity_max = 2000
innodb_read_io_threads = 8
innodb_write_io_threads = 8
innodb_thread_concurrency = 0
innodb_lock_wait_timeout = 50

# Query optimization
tmp_table_size = 512M
max_heap_table_size = 512M
join_buffer_size = 4M
sort_buffer_size = 4M
read_buffer_size = 2M
read_rnd_buffer_size = 4M

# Connection optimization
max_connections = 500
max_connect_errors = 100000
connect_timeout = 5
wait_timeout = 600
interactive_timeout = 600
net_read_timeout = 30
net_write_timeout = 30

# Cache settings
table_open_cache = 16384
table_definition_cache = 8192
thread_cache_size = 64

# Binary logging (disable if not needed)
#log_bin = /var/log/mysql/mysql-bin.log
#binlog_format = ROW
#expire_logs_days = 7

# Slow query optimization
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 1
log_queries_not_using_indexes = 0
min_examined_row_limit = 1000
```

### **Database Optimization Commands**
```bash
# Comprehensive database optimization
sudo seb-stack optimize-db --aggressive

# Analyze and repair tables
sudo seb-stack analyze-tables
sudo seb-stack repair-tables

# Optimize specific database
sudo mysqlcheck -o wordpress --auto-repair

# Monitor database performance
sudo seb-stack db-monitor --real-time
```

## 🔴 Redis Performance Optimization

### **Advanced Redis Configuration**
Edit `/etc/redis/redis.conf`:

```ini
# Memory optimization
maxmemory 2gb
maxmemory-policy allkeys-lru
maxmemory-samples 10

# Persistence optimization
save 900 1
save 300 10
save 60 10000
rdbcompression yes
rdbchecksum yes

# AOF optimization
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite yes
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Network optimization
tcp-keepalive 300
tcp-backlog 511
timeout 0

# Performance tuning
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64

# Latency monitoring
latency-monitor-threshold 100
```

### **Redis Optimization Commands**
```bash
# Monitor Redis performance
redis-cli --latency-history -i 1

# Check Redis memory usage
redis-cli info memory

# Optimize Redis memory
redis-cli memory usage keyname

# Clear expired keys
redis-cli eval "return redis.call('del', unpack(redis.call('keys', ARGV[1])))" 0 "expired:*"
```

## 🌐 WordPress-Specific Optimizations

### **WordPress Constants for Performance**
Add to `/var/www/example.com/wp-config.php`:

```php
<?php
// Redis object cache
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_DATABASE', 0);

// Performance optimizations
define('WP_CACHE', true);
define('CONCATENATE_SCRIPTS', true);
define('COMPRESS_SCRIPTS', true);
define('COMPRESS_CSS', true);
define('ENFORCE_GZIP', true);

// Database optimization
define('WP_ALLOW_REPAIR', true);
define('AUTOMATIC_UPDATER_DISABLED', true);
define('WP_AUTO_UPDATE_CORE', false);

// Memory optimization
define('WP_MEMORY_LIMIT', '512M');
define('WP_MAX_MEMORY_LIMIT', '1024M');

// Disable unnecessary features
define('WP_POST_REVISIONS', 3);
define('AUTOSAVE_INTERVAL', 300);
define('WP_CRON_LOCK_TIMEOUT', 60);
define('EMPTY_TRASH_DAYS', 7);

// Debug settings (disable in production)
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
```

### **Essential Performance Plugins**
```bash
# Install performance plugins via WP-CLI
wp plugin install redis-cache --activate
wp plugin install w3-total-cache --activate
wp plugin install wp-optimize --activate
wp plugin install imagify --activate

# Configure Redis cache
wp redis enable

# Configure W3 Total Cache
wp w3-total-cache import /etc/seb-stack/w3tc-config.json
```

### **Database Cleanup Automation**
Create `/etc/cron.d/wordpress-cleanup`:

```bash
# WordPress database cleanup (runs daily at 2 AM)
0 2 * * * www-data /usr/local/bin/wp db optimize --path=/var/www/example.com
15 2 * * * www-data /usr/local/bin/wp transient delete --expired --path=/var/www/example.com
30 2 * * * www-data /usr/local/bin/wp post delete $(wp post list --post_status=trash --format=ids --path=/var/www/example.com) --force --path=/var/www/example.com
```

## 📊 Performance Monitoring

### **Real-Time Performance Monitoring**
```bash
# Monitor system performance
sudo seb-stack monitor --real-time

# Check specific metrics
sudo seb-stack metrics --cpu --memory --disk

# Generate performance report
sudo seb-stack performance-report --detailed > /tmp/performance-report.txt
```

### **Automated Performance Testing**
Create `/usr/local/bin/performance-test.sh`:

```bash
#!/bin/bash

DOMAIN="example.com"
RESULTS_FILE="/var/log/seb-stack/performance-$(date +%Y%m%d).log"

# Test page load time
LOAD_TIME=$(curl -w '%{time_total}' -o /dev/null -s https://$DOMAIN)
echo "$(date): Page Load Time: ${LOAD_TIME}s" >> $RESULTS_FILE

# Test TTFB
TTFB=$(curl -w '%{time_starttransfer}' -o /dev/null -s https://$DOMAIN)
echo "$(date): TTFB: ${TTFB}s" >> $RESULTS_FILE

# Test cache hit rate
CACHE_STATUS=$(curl -I -s https://$DOMAIN | grep -i "x-cache-status" | awk '{print $2}')
echo "$(date): Cache Status: $CACHE_STATUS" >> $RESULTS_FILE

# Alert if performance degrades
if (( $(echo "$LOAD_TIME > 2.0" | bc -l) )); then
    echo "ALERT: Page load time exceeded 2 seconds: ${LOAD_TIME}s" | mail -s "Performance Alert" admin@example.com
fi
```

### **Performance Dashboard Setup**
```bash
# Install monitoring tools
sudo seb-stack install-monitoring

# Configure Grafana dashboard
sudo seb-stack setup-dashboard

# Access dashboard
echo "Dashboard available at: https://example.com:3000"
echo "Default login: admin/admin"
```

## 🔧 Advanced Optimizations

### **CPU Governor Optimization**
```bash
# Set CPU governor for performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Make permanent
echo 'GOVERNOR="performance"' | sudo tee -a /etc/default/cpufrequtils
```

### **Network Stack Tuning**
Add to `/etc/sysctl.conf`:

```bash
# Network performance optimization
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.route.flush = 1
```

### **File System Optimization**
```bash
# Optimize file system mount options
sudo nano /etc/fstab

# Add noatime,nodiratime options
# /dev/sda1 / ext4 defaults,noatime,nodiratime 0 1

# Remount with optimizations
sudo mount -o remount /
```

## 📈 Performance Testing Tools

### **Built-in Testing Commands**
```bash
# Comprehensive performance test
sudo seb-stack test-performance --full

# Load testing
sudo seb-stack load-test --concurrent=50 --duration=300

# Database performance test
sudo seb-stack test-db-performance

# Cache effectiveness test
sudo seb-stack test-cache-performance
```

### **External Testing Tools**
```bash
# Install testing tools
sudo apt install apache2-utils wrk

# Simple load test with ab
ab -n 1000 -c 10 https://example.com/

# Advanced load test with wrk
wrk -t12 -c100 -d30s --latency https://example.com/

# Test with real browser simulation
sudo seb-stack install-lighthouse
lighthouse https://example.com --output=json --output-path=/tmp/lighthouse-report.json
```

## 🚀 Performance Optimization Checklist

### **Daily Tasks**
- [ ] Check performance metrics dashboard
- [ ] Review slow query log
- [ ] Monitor cache hit rates
- [ ] Check disk usage and cleanup if needed

### **Weekly Tasks**
- [ ] Run comprehensive performance test
- [ ] Optimize database tables
- [ ] Clear expired cache entries
- [ ] Review and analyze performance reports

### **Monthly Tasks**
- [ ] Update performance configurations
- [ ] Benchmark against previous month
- [ ] Review and optimize WordPress plugins
- [ ] Update caching strategies based on usage patterns

---

**Next:** Implement [Security Hardening](../security/) to protect your optimized stack.
