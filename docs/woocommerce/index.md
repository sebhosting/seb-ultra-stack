---
layout: default
title: WooCommerce Guide
description: Complete WooCommerce optimization guide for SEB Ultra Stack
---

# 🛒 WooCommerce Guide

Optimize your WooCommerce store for maximum performance, security, and scalability with SEB Ultra Stack.

## 🚀 WooCommerce Quick Setup

### **One-Click WooCommerce Installation**
```bash
# Install WooCommerce on existing site
sudo seb-stack install-woocommerce example.com

# Create new WooCommerce site
sudo seb-stack create-woocommerce-site shop.example.com

# Enable WooCommerce optimizations
sudo seb-stack optimize-woocommerce shop.example.com
```

### **WooCommerce Stack Architecture**
```
┌─────────────────────────────────────────┐
│  Cloudflare CDN + E-commerce Protection │ ← Global CDN
├─────────────────────────────────────────┤
│  Nginx + SSL + Security Headers         │ ← Web Server
├─────────────────────────────────────────┤
│  PHP 8.4 + OPcache + Session Redis      │ ← Application Layer
├─────────────────────────────────────────┤
│  WooCommerce + Performance Plugins      │ ← E-commerce Platform
├─────────────────────────────────────────┤
│  Redis Object Cache + Product Cache     │ ← Caching Layer
├─────────────────────────────────────────┤
│  MariaDB + E-commerce Optimization      │ ← Database Layer
└─────────────────────────────────────────┘
```

## ⚡ WooCommerce Performance Optimization

### **Database Optimization for WooCommerce**
Edit `/etc/mysql/mariadb.conf.d/99-woocommerce.cnf`:

```ini
[mysqld]
# WooCommerce-specific optimizations
innodb_buffer_pool_size = 2G
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Query optimization for product catalogs
tmp_table_size = 256M
max_heap_table_size = 256M
join_buffer_size = 8M
sort_buffer_size = 8M

# Connection settings for high traffic
max_connections = 200
max_user_connections = 150
thread_cache_size = 16

# WooCommerce session handling
table_open_cache = 4096
table_definition_cache = 2048

# Binary logging for replication
log_bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7
sync_binlog = 1
```

### **PHP Configuration for WooCommerce**
Edit `/etc/php/8.4/fpm/conf.d/99-woocommerce.ini`:

```ini
[PHP]
# Memory settings for large catalogs
memory_limit = 1024M
max_execution_time = 300
max_input_time = 300
max_input_vars = 10000

# File upload for product images
upload_max_filesize = 100M
post_max_size = 100M
max_file_uploads = 100

# Session handling with Redis
session.save_handler = redis
session.save_path = "tcp://127.0.0.1:6379?database=1&prefix=wc_sess:"
session.gc_maxlifetime = 86400
session.cookie_lifetime = 0
session.cookie_secure = 1
session.cookie_httponly = 1

# OPcache for WooCommerce
opcache.memory_consumption = 512
opcache.max_accelerated_files = 20000
opcache.revalidate_freq = 0
opcache.validate_timestamps = 0

# Error handling
display_errors = Off
log_errors = On
error_log = /var/log/php/woocommerce-error.log
```

### **Redis Configuration for WooCommerce**
Edit `/etc/redis/woocommerce.conf`:

```ini
# WooCommerce-specific Redis instance
port 6380
pidfile /var/run/redis/redis-woocommerce.pid
logfile /var/log/redis/redis-woocommerce.log
dir /var/lib/redis-woocommerce/

# Memory settings
maxmemory 1gb
maxmemory-policy allkeys-lru

# Persistence for cart data
save 900 1
save 300 10
save 60 10000

appendonly yes
appendfsync everysec

# Security
requirepass woocommerce_redis_password
rename-command FLUSHDB ""
rename-command FLUSHALL ""

# Performance tuning
tcp-keepalive 300
timeout 0
tcp-backlog 511
```

### **WooCommerce-Optimized Nginx Configuration**
Create `/etc/nginx/conf.d/woocommerce.conf`:

```nginx
# WooCommerce performance optimization
location ~* /wp-content/.*\.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary Accept-Encoding;
    access_log off;
}

# WooCommerce API endpoints
location ~ ^/wp-json/wc/ {
    try_files $uri $uri/ /index.php?$args;
    
    # Rate limiting for API
    limit_req zone=wc_api burst=10 nodelay;
    
    # CORS headers for checkout
    add_header Access-Control-Allow-Origin "https://shop.example.com" always;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
}

# Checkout and cart pages - no caching
location ~ ^/(checkout|cart|my-account|shop) {
    set $skip_cache 1;
    try_files $uri $uri/ /index.php?$args;
    
    # Security headers for checkout
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}

# WooCommerce uploads protection
location ~* ^/wp-content/uploads/woocommerce_uploads/ {
    deny all;
    return 403;
}

# Product images optimization
location ~* ^/wp-content/uploads/.*\.(jpg|jpeg|png|gif|webp)$ {
    expires 30d;
    add_header Cache-Control "public, no-transform";
    add_header Vary Accept-Encoding;
    
    # Try WebP first, fallback to original
    location ~* \.(jpg|jpeg|png)$ {
        add_header Vary Accept;
        try_files $uri.webp $uri =404;
    }
}

# WooCommerce customer downloads
location ~* ^/wp-content/uploads/woocommerce_uploads/.*$ {
    location ~ \.php$ {
        return 444;
    }
}
```

## 🔒 WooCommerce Security

### **E-commerce Security Headers**
Add to your site's Nginx configuration:

```nginx
# Enhanced security for e-commerce
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' *.stripe.com *.paypal.com *.googleapis.com; style-src 'self' 'unsafe-inline' *.googleapis.com; img-src 'self' data: *.gravatar.com *.stripe.com *.paypal.com; connect-src 'self' *.stripe.com *.paypal.com; frame-src 'self' *.stripe.com *.paypal.com; font-src 'self' *.googleapis.com *.gstatic.com;" always;

add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;

# Force HTTPS for checkout
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

### **WooCommerce Security Configuration**
Add to `/var/www/example.com/wp-config.php`:

```php
<?php
// WooCommerce security settings
define('FORCE_SSL_ADMIN', true);
define('WC_LOG_HANDLER', 'WC_Log_Handler_File');

// Enhanced session security
define('COOKIEHASH', 'your_unique_hash_here');
define('COOKIE_DOMAIN', '.example.com');

// Disable file editing in WooCommerce
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', true);

// Database security
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', 'utf8mb4_unicode_ci');

// API security
define('JWT_AUTH_SECRET_KEY', 'your-secret-key-here');
define('JWT_AUTH_CORS_ENABLE', true);

// Payment security
define('WC_HTTPS_FORCE_CHECKOUT', true);
define('WC_REMOVE_ALL_DATA', false);
```

### **Payment Gateway Security**
```bash
# Install SSL certificate for payment processing
sudo certbot certonly --nginx -d shop.example.com

# Verify SSL configuration for PCI compliance
sudo seb-stack test-ssl-pci shop.example.com

# Enable payment gateway logs monitoring
sudo seb-stack enable-payment-monitoring shop.example.com

# Set up payment fraud detection
sudo seb-stack configure-fraud-detection shop.example.com
```

## 🛍️ WooCommerce Store Setup

### **Store Configuration via WP-CLI**
```bash
# Install WooCommerce
wp plugin install woocommerce --activate

# Run WooCommerce setup wizard programmatically
wp wc tool run install_pages
wp wc tool run create_default_tax_rates

# Configure basic store settings
wp option update woocommerce_store_address "123 Commerce St"
wp option update woocommerce_store_address_2 "Suite 100"
wp option update woocommerce_store_city "Commerce City"
wp option update woocommerce_default_country "US:CA"
wp option update woocommerce_store_postcode "90210"
wp option update woocommerce_currency "USD"

# Configure tax settings
wp option update woocommerce_calc_taxes "yes"
wp option update woocommerce_prices_include_tax "no"
wp option update woocommerce_tax_based_on "billing"

# Configure shipping
wp option update woocommerce_ship_to_countries ""
wp option update woocommerce_shipping_cost_requires_address "yes"

# Set up payment methods
wp wc payment_gateway update stripe --enabled=true
wp wc payment_gateway update paypal --enabled=true
```

### **Essential WooCommerce Plugins**
```bash
# Performance plugins
wp plugin install redis-cache --activate
wp plugin install w3-total-cache --activate

# Security plugins
wp plugin install wordfence --activate
wp plugin install woocommerce-gateway-stripe --activate

# SEO and marketing
wp plugin install yoast-seo --activate
wp plugin install mailchimp-for-woocommerce --activate

# Customer experience
wp plugin install woocommerce-gateway-paypal-express-checkout --activate
wp plugin install woocommerce-services --activate

# Analytics and reporting
wp plugin install google-analytics-for-wordpress --activate
wp plugin install woocommerce-google-analytics-integration --activate
```

### **Sample Product Import**
```bash
# Create sample products via WP-CLI
wp wc product create --name="Premium T-Shirt" --type="simple" --regular_price="29.99" --description="High-quality cotton t-shirt" --short_description="Comfortable premium t-shirt" --status="publish"

wp wc product create --name="Wireless Headphones" --type="simple" --regular_price="199.99" --sale_price="149.99" --description="Premium wireless headphones with noise cancellation" --short_description="Crystal clear sound quality" --status="publish" --featured=true

# Import products from CSV
wp wc product import products.csv --user=admin

# Set up product categories
wp wc product_cat create --name="Electronics" --slug="electronics" --description="Electronic gadgets and accessories"
wp wc product_cat create --name="Clothing" --slug="clothing" --description="Fashion and apparel"
```

## 📊 WooCommerce Analytics and Reporting

### **Sales Reporting Setup**
```bash
# Generate sales report
wp wc report sales --start_date="2024-01-01" --end_date="2024-12-31"

# Customer analytics
wp wc customer list --per_page=100 --orderby="date_registered" --order="desc"

# Product performance
wp eval "
$products = wc_get_products(array('limit' => -1));
foreach ($products as $product) {
    $sales = get_post_meta($product->get_id(), 'total_sales', true);
    echo $product->get_name() . ': ' . $sales . ' sales' . PHP_EOL;
}
"

# Revenue by period
wp wc report sales --period="month" --format=table
```

### **Performance Monitoring for WooCommerce**
Create `/usr/local/bin/woocommerce-monitor.sh`:

```bash
#!/bin/bash

DOMAIN="shop.example.com"
LOG_FILE="/var/log/seb-stack/woocommerce-performance.log"
ALERT_EMAIL="admin@example.com"

# Check checkout page performance
CHECKOUT_TIME=$(curl -w '%{time_total}' -o /dev/null -s https://$DOMAIN/checkout/)
echo "$(date): Checkout Page Load Time: ${CHECKOUT_TIME}s" >> $LOG_FILE

if (( $(echo "$CHECKOUT_TIME > 3.0" | bc -l) )); then
    echo "ALERT: Checkout page slow: ${CHECKOUT_TIME}s" | mail -s "WooCommerce Performance Alert" $ALERT_EMAIL
fi

# Check database performance
DB_QUERIES=$(wp db query "SELECT COUNT(*) FROM wp_woocommerce_order_items;" --skip-column-names)
echo "$(date): Total Order Items: $DB_QUERIES" >> $LOG_FILE

# Check Redis cache hit rate
REDIS_HITS=$(redis-cli info stats | grep keyspace_hits | cut -d: -f2)
REDIS_MISSES=$(redis-cli info stats | grep keyspace_misses | cut -d: -f2)
HIT_RATE=$(echo "scale=2; $REDIS_HITS / ($REDIS_HITS + $REDIS_MISSES) * 100" | bc)
echo "$(date): Redis Cache Hit Rate: ${HIT_RATE}%" >> $LOG_FILE

# Check cart abandonment (simplified)
ACTIVE_CARTS=$(wp db query "SELECT COUNT(*) FROM wp_woocommerce_sessions WHERE session_expiry > UNIX_TIMESTAMP();" --skip-column-names)
echo "$(date): Active Shopping Carts: $ACTIVE_CARTS" >> $LOG_FILE

# Monitor order processing time
AVG_ORDER_TIME=$(wp db query "
    SELECT AVG(TIMESTAMPDIFF(SECOND, post_date, post_modified)) as avg_time 
    FROM wp_posts 
    WHERE post_type = 'shop_order' 
    AND post_status IN ('wc-processing', 'wc-completed') 
    AND DATE(post_date) = CURDATE()
" --skip-column-names)

echo "$(date): Average Order Processing Time: ${AVG_ORDER_TIME}s" >> $LOG_FILE
```

## 🎯 WooCommerce Optimization Strategies

### **Database Optimization for Large Catalogs**
```bash
# Optimize WooCommerce tables
wp db query "OPTIMIZE TABLE wp_woocommerce_order_items, wp_woocommerce_order_itemmeta, wp_posts, wp_postmeta;"

# Clean up old sessions
wp db query "DELETE FROM wp_woocommerce_sessions WHERE session_expiry < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 1 WEEK));"

# Remove old cart contents
wp transient delete-expired

# Optimize product lookup tables
wp wc tool run clear_expired_transients
wp wc tool run recount_terms

# Database maintenance script
cat > /usr/local/bin/woocommerce-db-maintenance.sh << 'EOF'
#!/bin/bash

# Clean up old order notes
wp db query "DELETE FROM wp_comments WHERE comment_type = 'order_note' AND comment_date < DATE_SUB(NOW(), INTERVAL 6 MONTH);"

# Remove abandoned carts older than 1 week
wp db query "DELETE FROM wp_usermeta WHERE meta_key = '_woocommerce_persistent_cart_1' AND meta_value LIKE '%\"cart_expiry\";i:%' AND FROM_UNIXTIME(SUBSTRING_INDEX(SUBSTRING_INDEX(meta_value, 'cart_expiry\";i:', -1), ';', 1)) < DATE_SUB(NOW(), INTERVAL 1 WEEK);"

# Clean up old product views
wp db query "DELETE FROM wp_postmeta WHERE meta_key = '_wc_average_rating' AND post_id NOT IN (SELECT ID FROM wp_posts WHERE post_type = 'product');"

# Optimize tables
wp db optimize
EOF

chmod +x /usr/local/bin/woocommerce-db-maintenance.sh
```

### **Caching Strategy for WooCommerce**
Create `/var/www/example.com/wp-content/mu-plugins/woocommerce-cache.php`:

```php
<?php
/**
 * WooCommerce caching optimizations
 */

// Exclude WooCommerce pages from caching
function exclude_woocommerce_from_cache($excluded) {
    if (function_exists('is_woocommerce')) {
        if (is_woocommerce() || is_cart() || is_checkout() || is_account_page()) {
            return true;
        }
    }
    return $excluded;
}
add_filter('w3tc_can_cache', 'exclude_woocommerce_from_cache');

// Fragment caching for product blocks
function cache_product_fragments() {
    if (is_admin()) return;
    
    // Cache expensive queries
    if (!wp_cache_get('bestselling_products', 'woocommerce')) {
        $bestselling_products = wc_get_products(array(
            'meta_key' => 'total_sales',
            'orderby' => 'meta_value_num',
            'order' => 'DESC',
            'limit' => 8,
        ));
        wp_cache_set('bestselling_products', $bestselling_products, 'woocommerce', 3600);
    }
    
    // Cache product categories
    if (!wp_cache_get('product_categories', 'woocommerce')) {
        $categories = get_terms(array(
            'taxonomy' => 'product_cat',
            'hide_empty' => true,
            'number' => 20,
        ));
        wp_cache_set('product_categories', $categories, 'woocommerce', 1800);
    }
}
add_action('init', 'cache_product_fragments');

// Optimize WooCommerce scripts loading
function optimize_woocommerce_scripts() {
    // Remove WooCommerce scripts on non-shop pages
    if (!is_woocommerce() && !is_cart() && !is_checkout() && !is_account_page()) {
        wp_dequeue_style('woocommerce-general');
        wp_dequeue_style('woocommerce-layout');
        wp_dequeue_style('woocommerce-smallscreen');
        wp_dequeue_script('wc-cart-fragments');
        wp_dequeue_script('woocommerce');
        wp_dequeue_script('wc-add-to-cart');
    }
}
add_action('wp_enqueue_scripts', 'optimize_woocommerce_scripts', 99);

// Optimize cart fragments
function optimize_cart_fragments() {
    // Reduce cart fragments AJAX calls frequency
    wp_localize_script('wc-cart-fragments', 'wc_cart_fragments_params', array(
        'ajax_url' => admin_url('admin-ajax.php'),
        'wc_ajax_url' => WC_AJAX::get_endpoint('%%endpoint%%'),
        'cart_hash_key' => apply_filters('woocommerce_cart_hash_key', 'wc_cart_hash_'.md5(get_current_blog_id().'_'.get_site_url(get_current_blog_id(), '/').'_')),
        'fragment_name' => apply_filters('woocommerce_cart_fragment_name', 'wc_fragments_'.md5(get_current_blog_id().'_'.get_site_url(get_current_blog_id(), '/').'_')),
        'request_timeout' => 5000
    ));
}
add_action('wp_enqueue_scripts', 'optimize_cart_fragments', 100);
```

### **Image Optimization for Products**
```bash
# Install WebP conversion tools
sudo apt install webp imagemagick

# Create image optimization script
cat > /usr/local/bin/optimize-product-images.sh << 'EOF'
#!/bin/bash

UPLOAD_DIR="/var/www/example.com/wp-content/uploads"
QUALITY=85

# Convert images to WebP
find "$UPLOAD_DIR" -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" | while read img; do
    webp_file="${img%.*}.webp"
    if [ ! -f "$webp_file" ]; then
        cwebp -q $QUALITY "$img" -o "$webp_file"
        echo "Converted: $img -> $webp_file"
    fi
done

# Optimize existing images
find "$UPLOAD_DIR" -name "*.jpg" -o -name "*.jpeg" | while read img; do
    jpegoptim --max=$QUALITY --strip-all "$img"
done

find "$UPLOAD_DIR" -name "*.png" | while read img; do
    optipng -o2 "$img"
done

echo "Image optimization completed"
EOF

chmod +x /usr/local/bin/optimize-product-images.sh

# Run optimization
sudo /usr/local/bin/optimize-product-images.sh

# Set up automated optimization
echo "0 3 * * 0 /usr/local/bin/optimize-product-images.sh" | sudo crontab -
```

## 💳 Payment Gateway Configuration

### **Stripe Integration**
```bash
# Install Stripe plugin
wp plugin install woocommerce-gateway-stripe --activate

# Configure Stripe settings
wp option update woocommerce_stripe_settings '{
    "enabled": "yes",
    "title": "Credit Card",
    "description": "Pay securely with your credit card",
    "testmode": "no",
    "publishable_key": "pk_live_your_key_here",
    "secret_key": "sk_live_your_key_here",
    "webhook_secret": "whsec_your_webhook_secret_here",
    "capture": "yes",
    "payment_request": "yes",
    "saved_cards": "yes"
}'

# Set up Stripe webhooks
wp wc webhook create --name="Stripe Order Updates" --topic="order.updated" --delivery_url="https://shop.example.com/?wc-api=wc_stripe"
```

### **PayPal Configuration**
```bash
# Configure PayPal Express Checkout
wp option update woocommerce_ppec_paypal_settings '{
    "enabled": "yes",
    "title": "PayPal",
    "description": "Pay via PayPal; you can pay with your credit card if you dont have a PayPal account",
    "environment": "live",
    "api_username": "your_api_username",
    "api_password": "your_api_password",
    "api_signature": "your_api_signature",
    "invoice_prefix": "WC-",
    "send_shipping": "yes"
}'
```

## 🔄 Inventory Management

### **Automated Inventory Tracking**
Create `/usr/local/bin/inventory-monitor.sh`:

```bash
#!/bin/bash

LOW_STOCK_THRESHOLD=5
OUT_OF_STOCK_ALERT="admin@example.com"

# Check low stock items
LOW_STOCK=$(wp wc product list --stock_status="instock" --format=csv --fields=id,name,stock_quantity | awk -F, -v threshold=$LOW_STOCK_THRESHOLD '$3 != "" && $3 <= threshold {print $2 " (ID: " $1 ", Stock: " $3 ")"}')

if [ ! -z "$LOW_STOCK" ]; then
    echo "Low Stock Alert - $(date)" > /tmp/low_stock_alert.txt
    echo "The following products are low on stock:" >> /tmp/low_stock_alert.txt
    echo "$LOW_STOCK" >> /tmp/low_stock_alert.txt
    mail -s "Low Stock Alert" $OUT_OF_STOCK_ALERT < /tmp/low_stock_alert.txt
fi

# Check out of stock items
OUT_OF_STOCK=$(wp wc product list --stock_status="outofstock" --format=csv --fields=id,name | tail -n +2)

if [ ! -z "$OUT_OF_STOCK" ]; then
    echo "Out of Stock Alert - $(date)" > /tmp/out_of_stock_alert.txt
    echo "The following products are out of stock:" >> /tmp/out_of_stock_alert.txt
    echo "$OUT_OF_STOCK" >> /tmp/out_of_stock_alert.txt
    mail -s "Out of Stock Alert" $OUT_OF_STOCK_ALERT < /tmp/out_of_stock_alert.txt
fi

# Log inventory status
echo "$(date): Inventory check completed. Low stock: $(echo "$LOW_STOCK" | wc -l), Out of stock: $(echo "$OUT_OF_STOCK" | wc -l)" >> /var/log/seb-stack/inventory.log
```

### **Bulk Inventory Updates**
```bash
# Update inventory via CSV import
wp wc product import inventory-update.csv --user=admin

# Bulk price updates
wp wc product update --ids=$(wp wc product list --format=ids --category="electronics") --regular_price="+10%"

# Bulk stock management
wp eval "
\$products = wc_get_products(array('category' => array('clothing'), 'limit' => -1));
foreach (\$products as \$product) {
    if (\$product->get_stock_quantity() < 5) {
        \$product->set_stock_status('outofstock');
        \$product->save();
        echo 'Updated: ' . \$product->get_name() . PHP_EOL;
    }
}
"
```

## ✅ WooCommerce Maintenance Checklist

### **Daily Tasks**
- [ ] Check payment gateway status
- [ ] Monitor checkout page performance
- [ ] Review failed orders and payment errors
- [ ] Check inventory levels for bestselling products
- [ ] Verify SSL certificate status

### **Weekly Tasks**
- [ ] Review sales reports and analytics
- [ ] Clean up abandoned carts
- [ ] Update product information and prices
- [ ] Test checkout process across different browsers
- [ ] Review customer feedback and support tickets

### **Monthly Tasks**
- [ ] Optimize database and clean old data
- [ ] Update WooCommerce and extensions
- [ ] Review and optimize site performance
- [ ] Analyze conversion rates and customer behavior
- [ ] Update payment gateway configurations
- [ ] Review and update tax rates and shipping zones

### **Security Maintenance**
- [ ] Update all WooCommerce plugins
- [ ] Review payment logs for suspicious activity
- [ ] Test PCI compliance and security scans
- [ ] Monitor failed login attempts
- [ ] Review customer data access logs

---

**Next:** Set up comprehensive [Backup & Recovery](../backup/) systems to protect your e-commerce data.
