---
layout: default
---

![SEB Ultra Stack Banner](/docs/assets/banner.png)

# ⚡ SEB Ultra Stack Documentation
Bad to the Bone WordPress Hosting  
The Ultimate WordPress Multisite + WooCommerce Stack  
Nginx • PHP 8.3 • Redis • MariaDB • Cloudflare SSL • UFW • Fail2Ban  
Secure. Scalable. Blazing Fast. 💀

---

## 🚀 Quick Start

```bash
curl -sSL https://sebhosting.com/install.sh | bash
```

**Installation takes less than 10 minutes!**

---

## 📖 Table of Contents

- [🎯 Overview](#-overview)
- [⚙️ System Requirements](#️-system-requirements)
- [🚀 Installation Guide](#-installation-guide)
- [🎯 WordPress Configuration](#-wordpress-configuration)
- [🛒 WooCommerce Setup](#-woocommerce-setup)
- [⚡ Performance Optimization](#-performance-optimization)
- [🔒 Security Configuration](#-security-configuration)
- [📈 Scaling Your Stack](#-scaling-your-stack)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [❓ FAQ](#-faq)
- [💪 Support & Contributing](#-support--contributing)

---

## 🎯 Overview

The **SEB Ultra Stack** is the most badass WordPress hosting solution ever created. This isn't just another LAMP stack - this is a **weapon of mass performance**.

### ⚡ What Makes It Ultra?

| Component | Why It's Badass |
|-----------|----------------|
| **🚀 Nginx** | Crushes Apache with superior performance |
| **🔥 PHP 8.3** | JIT compilation delivers blazing speed |
| **⚡ Redis** | In-memory caching for instant page loads |
| **🗄️ MariaDB** | Optimized database that leaves MySQL behind |
| **🌐 Cloudflare** | Global CDN + free SSL certificates |
| **🛡️ Security** | UFW + Fail2Ban = Fort Knox protection |

### 🏆 Key Features

- ✅ **WordPress Multisite** - Manage unlimited sites from one dashboard
- ✅ **WooCommerce Ready** - Complete e-commerce solution out of the box
- ✅ **One-Click Install** - Deploy in minutes, not hours
- ✅ **Auto-Scaling** - Handles traffic spikes like a boss
- ✅ **Security Hardened** - Military-grade protection included
- ✅ **Performance Optimized** - Sub-second page loads guaranteed

> **💀 Fair Warning:** This stack is so fast, your competitors might cry.

---

## ⚙️ System Requirements

### Minimum Specs (For the Brave)
- **OS:** Ubuntu 20.04 LTS or 22.04 LTS
- **RAM:** 2GB (4GB+ recommended for high traffic)
- **CPU:** 2 cores (4+ cores for enterprise sites)
- **Storage:** 20GB SSD minimum
- **Network:** 1Gbps connection preferred

### 🔥 Recommended Hosting Providers

| Provider | Why We Love Them | Starting Price |
|----------|------------------|---------------|
| **DigitalOcean** | Perfect droplet performance | $10/month |
| **AWS EC2** | Infinite scalability | $5/month |
| **Vultr** | Excellent price/performance | $6/month |
| **Linode** | Developer-friendly | $5/month |

⚠️ **Warning:** This stack requires root access and will modify core server configurations. Only install on a fresh server!

---

## 🚀 Installation Guide

### Step 1: Connect to Your Server

```bash
ssh root@your-server-ip
```

### Step 2: Run the Magic Command

```bash
curl -sSL https://sebhosting.com/install.sh | bash
```

### Step 3: Grab a Coffee ☕

The installation is fully automated and takes 5-10 minutes. Here's what happens:

1. **System Hardening** - Security updates and configurations
2. **Nginx Installation** - Web server setup and optimization
3. **PHP 8.3 Setup** - Latest PHP with performance extensions
4. **Database Configuration** - MariaDB with optimized settings
5. **Redis Installation** - Object caching configuration
6. **WordPress Deployment** - Multisite network setup
7. **SSL Certificate** - Free Cloudflare SSL integration
8. **Security Setup** - UFW firewall and Fail2Ban configuration

### Post-Installation Output

```bash
🔥 SEB ULTRA STACK INSTALLATION COMPLETE! 🔥

📊 Your Stack Details:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 WordPress Admin: https://yourdomain.com/wp-admin
👤 Username: admin
🔑 Password: [randomly generated secure password]

💾 Database Access:
🏠 Host: localhost
👤 Username: wordpress
🔑 Password: [secure database password]

🚀 Your site is now BLAZING FAST and SECURE!
💀 Welcome to the Ultra Stack family!

📖 Documentation: https://docs.sebhosting.com
💬 Support: https://discord.gg/sebhosting
```

---

## 🎯 WordPress Configuration

### Multisite Network Management

Your WordPress installation comes pre-configured with Multisite enabled. Here's how to manage it:

#### Adding New Sites

1. Go to **My Sites** → **Network Admin** → **Sites**
2. Click **"Add New"**
3. Fill in site details:
   - **Site Address:** subdomain or subdirectory
   - **Site Title:** Your site name
   - **Admin Email:** Site administrator email
4. Click **"Add Site"**

#### Network Settings

```php
// Network settings are pre-configured in wp-config.php
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', true);
define('DOMAIN_CURRENT_SITE', 'yourdomain.com');
define('PATH_CURRENT_SITE', '/');
define('SITE_ID_CURRENT_SITE', 1);
define('BLOG_ID_CURRENT_SITE', 1);
```

### Essential Plugins (Pre-Installed)

| Plugin | Purpose | Status |
|--------|---------|--------|
| **Redis Object Cache** | Lightning-fast caching | ✅ Active |
| **Wordfence Security** | Premium security protection | ✅ Active |
| **WP Super Cache** | Page caching | ✅ Active |
| **Yoast SEO** | Search engine optimization | ✅ Active |

> ⚠️ **Critical:** Never deactivate Redis Object Cache - it's essential for performance!

---

## 🛒 WooCommerce Setup

WooCommerce is pre-installed and optimized for the Ultra Stack.

### Initial Configuration

1. **Navigate to:** WooCommerce → Setup Wizard
2. **Store Details:** Configure your store information
3. **Payment Gateways:** Enable PayPal, Stripe, etc.
4. **Shipping:** Configure shipping zones and methods
5. **Tax Settings:** Set up tax calculations

### Performance Optimizations

```php
// Pre-configured WooCommerce optimizations
define('WC_SESSION_CACHE_GROUP', 'wc_session_id');
define('WC_USE_TRANSACTIONS', false);

// Redis object cache for WooCommerce
wp_cache_add_global_groups(['wc_session_id']);
```

### Recommended Extensions

- **WooCommerce Subscriptions** - Recurring payments
- **WooCommerce Bookings** - Appointment scheduling  
- **WooCommerce Memberships** - Membership sites
- **WooCommerce PDF Invoices** - Professional invoicing

---

## ⚡ Performance Optimization

### Built-in Performance Features

The Ultra Stack comes pre-optimized, but here are the key performance features:

#### Nginx Configuration
```nginx
# High-performance Nginx config (pre-configured)
server {
    listen 80;
    listen [::]:80;
    server_name yourdomain.com;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    
    # Browser caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

#### PHP 8.3 Optimizations
```ini
; Pre-configured PHP settings
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.validate_timestamps=0
```

#### Redis Configuration
```bash
# Redis memory optimization (pre-configured)
maxmemory 1gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
```

### Performance Monitoring

Monitor your stack performance:

```bash
# Check Redis status
redis-cli info memory

# Monitor Nginx
sudo nginx -t && sudo systemctl status nginx

# PHP-FPM status
sudo systemctl status php8.3-fpm

# Database performance
sudo mysqladmin -u root -p status
```

---

## 🔒 Security Configuration

Security is baked into every layer of the Ultra Stack:

### UFW Firewall Rules

```bash
# Pre-configured firewall rules
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### Fail2Ban Protection

```ini
# Fail2Ban WordPress protection (pre-configured)
[wordpress]
enabled = true
port = http,https
filter = wordpress
logpath = /var/log/nginx/access.log
maxretry = 3
bantime = 3600
```

### SSL/TLS Configuration

```nginx
# Cloudflare SSL configuration (automated)
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
add_header Strict-Transport-Security "max-age=63072000" always;
```

### WordPress Security Hardening

```php
// Security configurations (pre-applied)
define('DISALLOW_FILE_EDIT', true);
define('WP_DEBUG', false);
define('AUTOMATIC_UPDATER_DISABLED', true);

// Hide WordPress version
remove_action('wp_head', 'wp_generator');
```

---

## 📈 Scaling Your Stack

### Vertical Scaling (More Power)

**Upgrade your server specs:**
- **RAM:** 8GB+ for high-traffic sites
- **CPU:** 8+ cores for enterprise applications
- **Storage:** NVMe SSD for maximum I/O performance

### Horizontal Scaling (More Servers)

**Load Balancing Setup:**
```nginx
# Nginx load balancer configuration
upstream backend {
    server 192.168.1.10:80;
    server 192.168.1.11:80;
    server 192.168.1.12:80;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

### Database Scaling

**Master-Slave Replication:**
```bash
# Master server configuration
sudo mysql -u root -p
CREATE USER 'replica'@'%' IDENTIFIED BY 'strong_password';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
FLUSH PRIVILEGES;
```

### CDN Integration

**Cloudflare Configuration:**
1. **Add your domain** to Cloudflare
2. **Update nameservers** to Cloudflare's
3. **Enable caching** and optimization features
4. **Configure SSL** to "Full (Strict)"

---

## 🛠️ Troubleshooting

### Common Issues & Solutions

#### Site Not Loading
```bash
# Check Nginx status
sudo systemctl status nginx

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Restart services
sudo systemctl restart nginx php8.3-fpm
```

#### Database Connection Error
```bash
# Check MariaDB status
sudo systemctl status mariadb

# Test database connection
mysql -u wordpress -p wordpress_db

# Check WordPress config
sudo nano /var/www/html/wp-config.php
```

#### Redis Connection Issues
```bash
# Check Redis status
redis-cli ping

# Restart Redis
sudo systemctl restart redis-server

# Check Redis logs
sudo tail -f /var/log/redis/redis-server.log
```

#### SSL Certificate Problems
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew --dry-run

# Update Cloudflare settings
# Ensure SSL mode is "Full (Strict)"
```

### Performance Troubleshooting

#### Slow Page Loads
1. **Check Redis:** Ensure object caching is active
2. **Monitor CPU:** Use `htop` to check server resources
3. **Database Queries:** Install Query Monitor plugin
4. **Image Optimization:** Compress and optimize images

#### High Memory Usage
```bash
# Check memory usage
free -h

# Identify memory hogs
ps aux --sort=-%mem | head

# Optimize PHP memory
sudo nano /etc/php/8.3/fpm/php.ini
# Adjust memory_limit and max_execution_time
```

---

## ❓ FAQ

### General Questions

**Q: Can I install this on a shared hosting account?**  
A: No, the Ultra Stack requires root access and VPS/dedicated server.

**Q: Does this work with existing WordPress sites?**  
A: It's designed for fresh installations. Migration tools coming soon!

**Q: What's the minimum traffic this can handle?**  
A: The base configuration handles 100,000+ monthly visitors easily.

**Q: Is support included?**  
A: Community support is free. Premium support available for $29/month.

### Technical Questions

**Q: Can I customize the Nginx configuration?**  
A: Yes! All configs are in `/etc/nginx/sites-available/`

**Q: How do I backup my sites?**  
A: Automated backups are included. Manual backups via WP-CLI:
```bash
wp db export backup.sql
tar -czf site-backup.tar.gz /var/www/html
```

**Q: Can I add more PHP extensions?**  
A: Absolutely! Use: `sudo apt install php8.3-extension-name`

**Q: How do I enable debugging?**  
A: Edit wp-config.php:
```php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
```

---

## 💪 Support & Contributing

### 🆘 Get Support

| Support Level | What's Included | Price |
|---------------|----------------|-------|
| **Community** | GitHub Issues, Discord | Free |
| **Premium** | Direct email support, priority fixes | $29/month |
| **Enterprise** | Phone support, custom setup | $199/month |

### 📞 Contact Options

- **📧 Email:** support@sebhosting.com
- **💬 Discord:** [Join our server](https://discord.gg/sebhosting)
- **📱 Twitter:** [@sebhosting](https://twitter.com/sebhosting)
- **🐛 Issues:** [GitHub Issues](https://github.com/sebhosting/seb-ultra-stack/issues)

### 💝 Support This Project

Help keep the Ultra Stack free and badass:

**💳 [Donate via PayPal](https://www.paypal.com/donate/?business=YOUR_PAYPAL_EMAIL)**

**⭐ [Star us on GitHub](https://github.com/sebhosting/seb-ultra-stack)**

**🐦 [Share on Twitter](https://twitter.com/intent/tweet?text=Just%20deployed%20the%20SEB%20Ultra%20Stack%20-%20the%20most%20badass%20WordPress%20hosting%20solution!%20%F0%9F%94%A5&url=https://github.com/sebhosting/seb-ultra-stack)**

### 🤝 Contributing

Want to make the Ultra Stack even more badass?

1. **Fork the repository**
2. **Create a feature branch:** `git checkout -b badass-feature`
3. **Commit your changes:** `git commit -am 'Add badass feature'`
4. **Push to branch:** `git push origin badass-feature`
5. **Create Pull Request**

#### Contribution Guidelines

- ✅ Follow existing code style
- ✅ Add tests for new features
- ✅ Update documentation
- ✅ Keep it badass but stable

---

## 🏆 Credits

**Created with 💀 by SEB Hosting**

- **Lead Developer:** SEB
- **Security Consultant:** The Community
- **Performance Expert:** Redis Gods
- **Documentation:** Coffee & Late Nights

### Special Thanks

- **Nginx Team** - For the beast of a web server
- **PHP Team** - For continuous performance improvements  
- **Redis Team** - For making caching sexy
- **WordPress Community** - For the foundation
- **All Contributors** - For making this stack legendary

---

## 📄 License

MIT License - Use it, abuse it, make it more badass.

**Copyright © 2025 SEB Hosting**

---

> **💀 Remember:** With great power comes great responsibility.  
> Use the Ultra Stack wisely and may your sites be forever fast!

**⚡ SEB Ultra Stack - Bad to the Bone since 2025 ⚡**
