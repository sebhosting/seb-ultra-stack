
---
layout: default
title: WordPress Multisite Setup
description: Complete guide to WordPress multisite configuration with SEB Ultra Stack
---

# 🌐 WordPress Multisite Setup

Transform your WordPress installation into a powerful multisite network that can manage hundreds of sites from a single dashboard.

## 🚀 Multisite Overview

WordPress Multisite allows you to create a network of sites that share:
- **Single WordPress installation**
- **Shared plugins and themes**
- **Unified user management**
- **Centralized administration**
- **Optimized resource usage**

### **Multisite Architecture**
```
┌─────────────────────────────────────────┐
│  Network Admin Dashboard                │
├─────────────────────────────────────────┤
│  ├─ Site 1: main.example.com            │
│  ├─ Site 2: blog.example.com            │
│  ├─ Site 3: shop.example.com            │
│  ├─ Site 4: example.com/site4           │
│  └─ Site N: custom-domain.com           │
├─────────────────────────────────────────┤
│  Shared: Plugins, Themes, Users         │
├─────────────────────────────────────────┤
│  Single Database + File System          │
└─────────────────────────────────────────┘
```

## ⚡ Quick Multisite Setup

### **Enable Multisite (Fresh Installation)**
```bash
# Create multisite-enabled WordPress installation
sudo seb-stack create-multisite example.com --type=subdomain

# Or for subdirectory setup
sudo seb-stack create-multisite example.com --type=subdirectory

# Configure DNS and SSL
sudo seb-stack setup-multisite-dns example.com
```

### **Convert Existing Site to Multisite**
```bash
# Backup existing site first
sudo seb-stack backup example.com

# Convert to multisite
sudo seb-stack convert-multisite example.com --type=subdomain

# Update configuration
sudo seb-stack update-multisite-config example.com
```

## 🔧 Manual Multisite Configuration

### **Step 1: Enable Multisite in wp-config.php**
Add to `/var/www/example.com/wp-config.php` before `/* That's all, stop editing! */`:

```php
<?php
/* Multisite Configuration */
define('WP_ALLOW_MULTISITE', true);

// After network setup, add these:
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', true); // false for subdirectory
define('DOMAIN_CURRENT_SITE', 'example.com');
define('PATH_CURRENT_SITE', '/');
define('SITE_ID_CURRENT_SITE', 1);
define('BLOG_ID_CURRENT_SITE', 1);

// Cookie domain for subdomains
define('COOKIE_DOMAIN', '.example.com');

// Uploads directory
define('UPLOADS', 'wp-content/uploads');

// Optional: Custom table prefix for multisite
$table_prefix = 'wp_ms_';
```

### **Step 2: Update .htaccess Rules**
Replace `/var/www/example.com/.htaccess` content:

**For Subdomain Install:**
```apache
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]

# Add a trailing slash to /wp-admin
RewriteRule ^wp-admin$ wp-admin/ [R=301,L]

RewriteCond %{REQUEST_FILENAME} -f [OR]
RewriteCond %{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule ^(wp-(content|admin|includes).*) $1 [L]
RewriteRule ^(.*\.php)$ wp/$1 [L]
RewriteRule . index.php [L]
```

**For Subdirectory Install:**
```apache
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]

# Add a trailing slash to /wp-admin
RewriteRule ^([_0-9a-zA-Z-]+/)?wp-admin$ $1wp-admin/ [R=301,L]

RewriteCond %{REQUEST_FILENAME} -f [OR]
RewriteCond %{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule ^([_0-9a-zA-Z-]+/)?(wp-(content|admin|includes).*) $2 [L]
RewriteRule ^([_0-9a-zA-Z-]+/)?(.*\.php)$ $2 [L]
RewriteRule . index.php [L]
```

### **Step 3: Nginx Configuration for Multisite**

**For Subdomain Multisite:**
Create `/etc/nginx/sites-available/multisite-subdomains`:

```nginx
# Wildcard server block for subdomains
server {
    listen 80;
    listen [::]:80;
    server_name example.com *.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com *.example.com;
    
    root /var/www/example.com;
    index index.php index.html;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # Multisite files
    location ~ ^/files/(.*)$ {
        try_files /wp-content/blogs.dir/$blogid/files/$1 /wp-includes/ms-files.php?file=$1;
        access_log off;
        log_not_found off;
        expires max;
    }
    
    # Handle uploads for multisite
    location ~ ^/wp-content/uploads/sites/([0-9]+)/(.*)$ {
        try_files $uri $uri/ /index.php?$args;
        access_log off;
        log_not_found off;
        expires max;
    }
    
    # WordPress multisite rules
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    # PHP handling
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**For Subdirectory Multisite:**
Create `/etc/nginx/sites-available/multisite-subdirectories`:

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
    
    root /var/www/example.com;
    index index.php index.html;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # Multisite subdirectory rules
    location ~ ^(/[^/]+)?/wp-admin {
        try_files $uri $uri/ /wp-admin/index.php?$args;
    }
    
    location ~ ^(/[^/]+)?/(wp-(content|admin|includes).*) {
        try_files $uri /$2 /index.php?$args;
    }
    
    location ~ ^(/[^/]+)?/(.*.php)$ {
        try_files $uri /$2 /index.php?$args;
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
    }
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    # PHP handling
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
    }
}
```

## 🌐 DNS Configuration

### **Subdomain Multisite DNS**
Configure DNS records for wildcard subdomains:

```
Type: A
Name: example.com
Value: YOUR_SERVER_IP

Type: A  
Name: *.example.com
Value: YOUR_SERVER_IP

Type: CNAME
Name: www
Value: example.com
```

### **SSL Certificates for Subdomains**
```bash
# Generate wildcard SSL certificate
sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini -d example.com -d *.example.com

# Or add subdomains individually
sudo certbot certonly --nginx -d example.com -d www.example.com -d blog.example.com -d shop.example.com

# Auto-renewal setup
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🎛️ Network Administration

### **Network Setup Process**
1. **Visit WordPress Admin** → `/wp-admin/network.php`
2. **Choose Network Type**: Subdomains or Subdirectories
3. **Set Network Details**:
   - Network Title
   - Admin Email
   - Subdomain/Path structure
4. **Copy Generated Code** to wp-config.php and .htaccess
5. **Log back in** to access Network Admin

### **Network Admin Features**
```bash
# Access network admin
https://example.com/wp-admin/network/

# Key sections:
# - Sites: Manage all sites in network
# - Users: Network-wide user management  
# - Themes: Activate themes for network
# - Plugins: Install plugins network-wide
# - Settings: Network configuration
```

### **Managing Sites via WP-CLI**
```bash
# List all sites in network
wp site list

# Create new site
wp site create --slug=newsite --title="New Site" --email=admin@example.com

# Delete site
wp site delete 123 --yes

# Archive/unarchive site
wp site archive 123
wp site unarchive 123

# Get site info
wp site list --field=url --format=csv
```

## 🔧 Site Management

### **Adding New Sites**

**Via Network Admin:**
1. Navigate to **Network Admin** → **Sites** → **Add New**
2. Fill in site details:
   - Site Address (subdomain or subdirectory)
   - Site Title
   - Admin Email
3. Click **Add Site**

**Via WP-CLI:**
```bash
# Create subdomain site
wp site create --slug=blog --title="Blog Site" --email=admin@example.com

# Create subdirectory site  
wp site create --slug=shop --title="Shop Site" --email=admin@example.com --path=/shop/

# Clone existing site
wp site create --slug=newsite --title="New Site" --email=admin@example.com --clone=2
```

### **Site-Specific Operations**
```bash
# Switch to specific site
wp --url=blog.example.com option get home

# Install plugin on specific site
wp --url=blog.example.com plugin install woocommerce --activate

# Update specific site
wp --url=blog.example.com core update

# Backup specific site
sudo seb-stack backup blog.example.com

# Get site database info
wp --url=blog.example.com db size --human-readable
```

### **Bulk Operations**
```bash
# Update all sites
wp site list --field=url | xargs -I {} wp --url={} core update

# Install plugin on all sites
wp site list --field=url | xargs -I {} wp --url={} plugin install redis-cache --activate

# Clear cache on all sites
wp site list --field=url | xargs -I {} wp --url={} cache flush

# Get disk usage for all sites
wp site list --field=url | xargs -I {} sh -c 'echo "Site: {} Size: $(du -sh /var/www/$(echo {} | cut -d/ -f3)/wp-content/uploads)"'
```

## 🔧 Advanced Multisite Configuration

### **Custom Domain Mapping**
Enable custom domains for multisite:

**Install Domain Mapping Plugin:**
```bash
# Install via WP-CLI
wp plugin install wordpress-mu-domain-mapping --network-activate

# Or add to wp-config.php
define('SUNRISE', 'on');
```

**Configure Domain Mapping:**
```php
// Add to wp-config.php
define('DOMAIN_MAPPING', true);
define('COOKIE_DOMAIN', '.example.com');

// Database configuration for domain mapping
$wpdb->dmtable = $wpdb->base_prefix . 'domain_mapping';
```

### **Upload Directory Structure**
Multisite upload organization:

```
wp-content/uploads/
├── sites/
│   ├── 2/          # Site ID 2 uploads
│   │   ├── 2024/
│   │   └── 2023/
│   ├── 3/          # Site ID 3 uploads  
│   │   ├── 2024/
│   │   └── 2023/
│   └── 4/          # Site ID 4 uploads
├── 2024/           # Main site (ID 1) uploads
└── 2023/
```

### **Network-Wide Constants**
Add to `/var/www/example.com/wp-config.php`:

```php
<?php
// File upload limits
define('WP_MEMORY_LIMIT', '512M');
define('MAX_MEMORY_LIMIT', '1024M');

// Multisite upload space
define('BLOG_UPLOAD_SPACE', 1000); // MB per site
define('UPLOAD_SPACE_CHECK_DISABLED', false);

// Network settings
define('NOBLOGREDIRECT', 'https://example.com/');
define('REGISTRATION', 'all'); // 'all', 'user', 'blog', 'none'
define('SIGNUPBLOGURL', 'https://example.com/wp-signup.php');

// Network plugins directory
define('WP_PLUGIN_DIR', '/var/www/example.com/wp-content/plugins');
define('WPMU_PLUGIN_DIR', '/var/www/example.com/wp-content/mu-plugins');

// Email settings
define('RECOVERY_MODE_EMAIL', 'admin@example.com');
define('WP_MAIL_INTERVAL', 300);

// Security for multisite
define('DISALLOW_UNFILTERED_HTML', true);
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', true);
```

## 🚀 Performance Optimization for Multisite

### **Multisite-Specific Caching**
Configure Redis for multisite:

```php
// wp-config.php Redis configuration
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_DATABASE', 0);
define('WP_REDIS_PREFIX', 'wp_ms_');

// Site-specific cache groups
$redis_cache_groups = array(
    'blog-details',
    'blog-id-cache', 
    'blog-lookup',
    'global-posts',
    'networks',
    'rss',
    'site-details',
    'site-lookup',
    'site-options',
    'site-transient',
    'users',
    'useremail',
    'userlogins',
    'usermeta',
    'user_meta',
    'userslugs'
);
```

### **Database Optimization for Multisite**
```bash
# Optimize multisite database
wp db optimize

# Clean up multisite-specific tables
wp db query "DELETE FROM wp_blogs WHERE archived = '1' AND deleted = '1'"
wp db query "DELETE FROM wp_blog_versions WHERE blog_id NOT IN (SELECT blog_id FROM wp_blogs)"

# Remove spam/deleted sites data
wp site list --field=blog_id --archived=1 | xargs -I {} wp site delete {} --yes

# Optimize uploads directory
find /var/www/example.com/wp-content/uploads/sites/ -name "*.log" -delete
find /var/www/example.com/wp-content/uploads/sites/ -name "Thumbs.db" -delete
```

### **Nginx Caching for Multisite**
Create `/etc/nginx/conf.d/multisite-cache.conf`:

```nginx
# FastCGI cache for multisite
fastcgi_cache_path /var/cache/nginx/multisite
    levels=1:2
    keys_zone=MULTISITE:100m
    max_size=5g
    inactive=60m
    use_temp_path=off;

# Cache key for multisite
map $http_host $blogid {
    default 0;
    example.com 1;
    blog.example.com 2;
    shop.example.com 3;
}

# Multisite cache configuration
server {
    # Cache settings
    set $skip_cache 0;
    
    # Skip cache for specific conditions
    if ($request_method = POST) {
        set $skip_cache 1;
    }
    
    if ($query_string != "") {
        set $skip_cache 1;
    }
    
    if ($request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") {
        set $skip_cache 1;
    }
    
    if ($http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
        set $skip_cache 1;
    }
    
    location / {
        fastcgi_cache MULTISITE;
        fastcgi_cache_key "$scheme$request_method$http_host$request_uri$blogid";
        fastcgi_cache_bypass $skip_cache;
        fastcgi_no_cache $skip_cache;
        fastcgi_cache_valid 200 301 302 1m;
        fastcgi_cache_use_stale error timeout updating http_500 http_503;
        fastcgi_cache_min_uses 1;
        fastcgi_cache_lock on;
        add_header X-Cache-Status $upstream_cache_status;
        
        try_files $uri $uri/ /index.php?$args;
    }
}
```

## 👥 User Management in Multisite

### **User Roles and Capabilities**
```bash
# Network admin capabilities
wp user list --role=super-admin

# Add user to network
wp user create johndoe john@example.com --role=administrator

# Add existing user to site
wp user add-role johndoe administrator --url=blog.example.com

# Remove user from specific site
wp user remove-role johndoe administrator --url=blog.example.com

# List users across all sites
wp user list --network --format=table
```

### **Custom User Roles for Multisite**
Create `/var/www/example.com/wp-content/mu-plugins/multisite-roles.php`:

```php
<?php
/**
 * Custom multisite user roles
 */

// Add custom role for site managers
function add_multisite_roles() {
    if (is_multisite()) {
        add_role('site_manager', 'Site Manager', array(
            'read' => true,
            'edit_posts' => true,
            'edit_others_posts' => true,
            'edit_published_posts' => true,
            'publish_posts' => true,
            'delete_posts' => true,
            'delete_others_posts' => true,
            'delete_published_posts' => true,
            'edit_pages' => true,
            'edit_others_pages' => true,
            'edit_published_pages' => true,
            'publish_pages' => true,
            'delete_pages' => true,
            'delete_others_pages' => true,
            'delete_published_pages' => true,
            'manage_categories' => true,
            'manage_links' => true,
            'moderate_comments' => true,
            'upload_files' => true,
            'export' => true,
            'import' => true,
            'list_users' => true,
            'edit_theme_options' => true,
            'install_plugins' => false,
            'activate_plugins' => true,
            'edit_plugins' => false,
            'install_themes' => false,
            'switch_themes' => true,
            'edit_themes' => false
        ));
    }
}
add_action('init', 'add_multisite_roles');

// Restrict plugin/theme installation to super admins only
function restrict_multisite_capabilities() {
    if (is_multisite() && !is_super_admin()) {
        remove_submenu_page('plugins.php', 'plugin-install.php');
        remove_submenu_page('themes.php', 'theme-install.php');
        remove_submenu_page('themes.php', 'themes.php');
    }
}
add_action('admin_menu', 'restrict_multisite_capabilities', 999);
```

## 🔒 Multisite Security

### **Network Security Hardening**
```php
// Add to wp-config.php for enhanced multisite security
define('DISALLOW_UNFILTERED_HTML', true);
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', true);
define('FORCE_SSL_ADMIN', true);
define('WP_AUTO_UPDATE_CORE', 'minor');

// Restrict certain capabilities
define('EDIT_ANY_USER', false);
define('WP_ALLOW_REPAIR', false);

// Email verification for new sites
define('REGISTRATION', 'blog');
define('SIGNUPBLOGURL', 'https://example.com/wp-signup.php');
```

### **Site Isolation Security**
Create `/var/www/example.com/wp-content/mu-plugins/multisite-security.php`:

```php
<?php
/**
 * Multisite security enhancements
 */

// Prevent cross-site data access
function prevent_cross_site_access() {
    if (is_multisite()) {
        // Prevent users from accessing other sites' admin areas
        add_action('wp_loaded', function() {
            if (is_admin() && !is_network_admin()) {
                $current_user_sites = get_blogs_of_user(get_current_user_id());
                $current_site_id = get_current_blog_id();
                
                if (!array_key_exists($current_site_id, $current_user_sites)) {
                    wp_die('You do not have permission to access this site.');
                }
            }
        });
    }
}
add_action('init', 'prevent_cross_site_access');

// Sanitize uploaded filenames across network
function multisite_sanitize_filename($filename) {
    $filename = preg_replace('/[^a-zA-Z0-9._-]/', '', $filename);
    return $filename;
}
add_filter('sanitize_file_name', 'multisite_sanitize_filename');

// Block dangerous file uploads
function block_dangerous_uploads($file) {
    $dangerous_extensions = array('php', 'php3', 'php4', 'php5', 'phtml', 'exe', 'bat', 'com', 'scr', 'vbs', 'js');
    $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
    
    if (in_array(strtolower($ext), $dangerous_extensions)) {
        $file['error'] = 'File type not allowed for security reasons.';
    }
    
    return $file;
}
add_filter('wp_handle_upload_prefilter', 'block_dangerous_uploads');
```

## 📊 Monitoring and Analytics

### **Network Monitoring Commands**
```bash
# Monitor all sites performance
sudo seb-stack multisite-monitor --real-time

# Get network statistics
wp eval "
$sites = get_sites();
echo 'Total Sites: ' . count($sites) . PHP_EOL;
foreach ($sites as $site) {
    switch_to_blog($site->blog_id);
    echo 'Site ' . $site->blog_id . ' (' . home_url() . '): ' . wp_count_posts()->publish . ' posts' . PHP_EOL;
    restore_current_blog();
}
"

# Check disk usage per site
wp site list --field=url | while read site; do
    echo "Site: $site"
    du -sh /var/www/$(echo $site | cut -d/ -f3)/wp-content/uploads/sites/$(wp --url=$site eval "echo get_current_blog_id();")/ 2>/dev/null || echo "No uploads directory"
done

# Database usage per site
wp site list --format=csv --fields=blog_id,url | while IFS=, read blog_id url; do
    if [ "$blog_id" != "blog_id" ]; then
        echo "Site $blog_id ($url):"
        wp --url=$url db size --human-readable
    fi
done
```

### **Automated Network Health Checks**
Create `/usr/local/bin/multisite-health-check.sh`:

```bash
#!/bin/bash

LOGFILE="/var/log/seb-stack/multisite-health.log"
ALERT_EMAIL="admin@example.com"

echo "$(date): Starting multisite health check" >> $LOGFILE

# Check all sites are responding
wp site list --field=url | while read site_url; do
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "$site_url")
    if [ "$http_code" != "200" ]; then
        echo "$(date): Site $site_url returned HTTP $http_code" >> $LOGFILE
        echo "Alert: Site $site_url is not responding (HTTP $http_code)" | mail -s "Site Down Alert" $ALERT_EMAIL
    fi
done

# Check database connectivity for all sites
wp site list --field=url | while read site_url; do
    db_check=$(wp --url=$site_url db check 2>&1)
    if [[ $db_check == *"error"* ]]; then
        echo "$(date): Database issue for $site_url: $db_check" >> $LOGFILE
        echo "Alert: Database issue for $site_url" | mail -s "Database Alert" $ALERT_EMAIL
    fi
done

# Check disk usage
DISK_USAGE=$(df /var/www | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 85 ]; then
    echo "$(date): High disk usage: ${DISK_USAGE}%" >> $LOGFILE
    echo "Alert: High disk usage: ${DISK_USAGE}%" | mail -s "Disk Space Alert" $ALERT_EMAIL
fi

echo "$(date): Multisite health check completed" >> $LOGFILE
```

## 🔄 Backup and Recovery

### **Network-Wide Backup Strategy**
```bash
# Backup entire multisite network
sudo seb-stack backup-multisite example.com --include-uploads --include-database

# Backup specific site
sudo seb-stack backup blog.example.com

# Automated daily backups for all sites
sudo crontab -e
# Add: 0 2 * * * /usr/local/bin/seb-stack backup-multisite example.com --rotate=30

# Backup network database only
wp db export /var/backups/multisite-db-$(date +%Y%m%d).sql --all-tablespaces
```

### **Site-Specific Recovery**
```bash
# Restore specific site from backup
sudo seb-stack restore blog.example.com /var/backups/blog.example.com-20241125.tar.gz

# Clone site within network
wp site create --slug=staging-blog --title="Staging Blog" --email=admin@example.com
wp --url=staging-blog.example.com db import /var/backups/blog-database.sql

# Migration between networks
wp search-replace 'blog.oldnetwork.com' 'blog.newnetwork.com' --url=blog.newnetwork.com
```

## ✅ Multisite Best Practices

### **Planning Your Network**
- **Choose Structure Early**: Subdomain vs Subdirectory (difficult to change later)
- **Plan Domain Strategy**: Wildcard DNS and SSL certificates
- **Consider Scale**: Network performance impacts with 100+ sites
- **User Management**: Plan roles and capabilities structure
- **Plugin Strategy**: Network-wide vs site-specific plugins

### **Performance Considerations**
- **Database Optimization**: Regular cleanup of spam/deleted sites
- **Caching Strategy**: Site-specific cache keys and groups
- **Upload Management**: Monitor disk usage per site
- **Resource Limits**: Set appropriate per-site limits

### **Security Best Practices**
- **Regular Updates**: Keep core, themes, and plugins updated network-wide
- **User Permissions**: Restrict dangerous capabilities to super admins
- **File Upload Restrictions**: Block dangerous file types
- **Monitoring**: Implement network-wide security monitoring
- **Backup Strategy**: Regular automated backups with offsite storage

### **Maintenance Checklist**
**Daily:**
- [ ] Check network health status
- [ ] Monitor site performance metrics
- [ ] Review security logs

**Weekly:**
- [ ] Update plugins and themes network-wide
- [ ] Clean up spam sites and users
- [ ] Review disk usage per site
- [ ] Test backup restoration process

**Monthly:**
- [ ] Optimize database tables
- [ ] Review and update user roles
- [ ] Security audit of network
- [ ] Performance optimization review

---

**Next:** Optimize your multisite for [WooCommerce](../woocommerce/) if you're running e-commerce sites in your network.
