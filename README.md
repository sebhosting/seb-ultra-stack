# ⚡ SEB Ultra Stack
### The Ultimate WordPress Multisite + WooCommerce Stack
> **Nginx • PHP 8.4 • Redis • MariaDB • Cloudflare SSL • UFW • Fail2Ban**  
> *Secure. Scalable. Blazing Fast.*

[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](https://github.com/sebhosting/seb-ultra-stack/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/ubuntu-20.04%20|%2022.04%20|%2024.04-orange.svg)](https://ubuntu.com/)
[![PHP](https://img.shields.io/badge/php-8.4-purple.svg)](https://www.php.net/)
[![WordPress](https://img.shields.io/badge/wordpress-6.6+-blue.svg)](https://wordpress.org/)

---

## 🚀 One-Click Installation

```bash
curl -sSL https://sebhosting.com/install.sh | bash
```

**That's it.** Seriously. Grab a coffee while we handle the rest.

---

## 🎯 What You Get

### ⚡ **Performance Beast**
- **Nginx** - High-performance web server
- **PHP 8.4** - Latest PHP with JIT compiler & 4-year support cycle
- **Redis** - In-memory caching for lightning-fast page loads
- **MariaDB 10.11+** - Optimized database with advanced features
- **OpCache** - PHP bytecode caching for maximum speed

### 🛡️ **Fort Knox Security**
- **Cloudflare SSL** - Enterprise-grade encryption
- **UFW Firewall** - Intelligent traffic filtering
- **Fail2Ban** - Intrusion prevention & brute force protection
- **Security Headers** - HSTS, CSP, X-Frame-Options, and more
- **WordPress Hardening** - wp-config.php security, file permissions
- **Automatic Security Updates** - Keep your stack bulletproof

### 🌐 **WordPress Multisite Ready**
- **Pre-configured Multisite** - Subdomain & subdirectory support
- **WooCommerce Optimized** - E-commerce performance tuning
- **Automatic Backups** - Daily database & file backups
- **Staging Environment** - Safe testing before going live
- **SSL for All Sites** - Automatic certificate management

### 🔧 **Developer Paradise**
- **WP-CLI** - Command-line WordPress management
- **Composer** - PHP dependency management
- **Git Integration** - Version control ready
- **Custom php.ini** - Optimized for WordPress & WooCommerce
- **Error Logging** - Comprehensive debugging tools
- **PHPMyAdmin** - Database management interface

---

## 📊 Performance Metrics

| Metric | Before SEB Stack | After SEB Stack | Improvement |
|--------|------------------|-----------------|-------------|
| Page Load Time | 3.2s | 0.8s | **75% faster** |
| TTFB | 1.1s | 0.2s | **82% faster** |
| Database Queries | 45 | 12 | **73% reduction** |
| Server Response | 800ms | 150ms | **81% faster** |

*Results based on a typical WordPress + WooCommerce site with 10k products*

---

## 🏗️ System Requirements

### **Minimum Requirements**
- **OS**: Ubuntu 20.04+ LTS
- **RAM**: 2GB (4GB recommended)
- **Storage**: 20GB SSD
- **CPU**: 2 vCPU cores

### **Recommended for Production**
- **OS**: Ubuntu 22.04+ LTS
- **RAM**: 8GB+
- **Storage**: 50GB+ NVMe SSD
- **CPU**: 4+ vCPU cores
- **Network**: 1Gbps connection

---

## ⚙️ Tech Stack Details

### **Web Server Stack**
```
┌─────────────────────────────────────────┐
│  Cloudflare CDN + SSL                   │
├─────────────────────────────────────────┤
│  Nginx 1.24+ (HTTP/2, Gzip, Brotli)    │
├─────────────────────────────────────────┤
│  PHP 8.4 (FPM, OpCache, JIT)           │
├─────────────────────────────────────────┤
│  WordPress 6.6+ Multisite              │
├─────────────────────────────────────────┤
│  MariaDB 10.11+ (InnoDB, Query Cache)  │
├─────────────────────────────────────────┤
│  Redis 7+ (Object & Page Caching)      │
└─────────────────────────────────────────┘
```

### **Security Layer**
```
┌─────────────────────────────────────────┐
│  Cloudflare WAF + DDoS Protection      │
├─────────────────────────────────────────┤
│  UFW Firewall (Ports 22, 80, 443)      │
├─────────────────────────────────────────┤
│  Fail2Ban (SSH, WordPress, Nginx)      │
├─────────────────────────────────────────┤
│  SSL/TLS 1.3 + HSTS + Security Headers │
├─────────────────────────────────────────┤
│  WordPress Security Hardening          │
└─────────────────────────────────────────┘
```

---

## 🚀 Quick Start Guide

### 1. **Fresh Server Setup**
```bash
# Update your server
sudo apt update && sudo apt upgrade -y

# Install SEB Ultra Stack
curl -sSL https://sebhosting.com/install.sh | bash
```

### 2. **Domain Configuration**
```bash
# Add your domain
sudo seb-stack add-domain example.com

# Enable SSL
sudo seb-stack enable-ssl example.com
```

### 3. **WordPress Multisite Setup**
```bash
# Create new site
sudo seb-stack create-site blog.example.com

# Install WooCommerce
sudo seb-stack install-woocommerce example.com
```

### 4. **Performance Optimization**
```bash
# Enable all caching
sudo seb-stack enable-cache

# Optimize database
sudo seb-stack optimize-db
```

---

## 📋 Post-Installation Checklist

- [ ] **Domain DNS** - Point A record to your server IP
- [ ] **Cloudflare Setup** - Configure CDN and security settings
- [ ] **WordPress Admin** - Complete initial setup at `/wp-admin`
- [ ] **SSL Verification** - Confirm HTTPS is working
- [ ] **Backup Test** - Verify automated backups are running
- [ ] **Performance Test** - Run speed tests (GTmetrix, PageSpeed Insights)
- [ ] **Security Scan** - Test with security scanners

---

## 🛠️ Management Commands

### **Stack Management**
```bash
# Check stack status
sudo seb-stack status

# Update all components
sudo seb-stack update

# Restart services
sudo seb-stack restart

# View logs
sudo seb-stack logs [nginx|php|mysql|redis]
```

### **Site Management**
```bash
# List all sites
sudo seb-stack list-sites

# Backup specific site
sudo seb-stack backup example.com

# Restore from backup
sudo seb-stack restore example.com backup-file.tar.gz

# Clone site
sudo seb-stack clone-site source.com target.com
```

### **Performance Tools**
```bash
# Clear all caches
sudo seb-stack clear-cache

# Database optimization
sudo seb-stack optimize-db

# Performance report
sudo seb-stack performance-report
```

---

## 🔧 Configuration Files

### **Key Locations**
```
/etc/nginx/sites-available/     # Nginx virtual hosts
/etc/php/8.4/fpm/pool.d/       # PHP-FPM pools
/var/www/                       # Website root directory
/etc/seb-stack/                 # SEB Stack configuration
/var/log/seb-stack/             # Stack logs
```

### **Important Files**
- **Nginx Config**: `/etc/nginx/nginx.conf`
- **PHP Config**: `/etc/php/8.4/fpm/php.ini`
- **MariaDB Config**: `/etc/mysql/mariadb.conf.d/50-server.cnf`
- **Redis Config**: `/etc/redis/redis.conf`

---

## 🚨 Troubleshooting

### **Common Issues**

#### **Site Not Loading**
```bash
# Check Nginx status
sudo systemctl status nginx

# Test Nginx configuration
sudo nginx -t

# Check error logs
sudo seb-stack logs nginx
```

#### **PHP Errors**
```bash
# Check PHP-FPM status
sudo systemctl status php8.4-fpm

# View PHP error logs
sudo seb-stack logs php

# Test PHP configuration
php -m | grep -i cache
```

#### **Database Issues**
```bash
# Check MariaDB status
sudo systemctl status mariadb

# Test database connection
mysql -u root -p -e "SHOW DATABASES;"

# Optimize all databases
sudo seb-stack optimize-db --all
```

#### **Cache Problems**
```bash
# Restart Redis
sudo systemctl restart redis-server

# Clear all caches
sudo seb-stack clear-cache

# Test Redis connection
redis-cli ping
```

---

## 🔐 Security Best Practices

### **Implemented by Default**
✅ **Strong Passwords** - Auto-generated secure passwords  
✅ **Firewall Rules** - UFW with minimal open ports  
✅ **Fail2Ban** - Intrusion detection and prevention  
✅ **SSL Encryption** - TLS 1.3 with perfect forward secrecy  
✅ **Security Headers** - HSTS, CSP, X-Frame-Options  
✅ **WordPress Hardening** - Secure file permissions, hidden wp-config.php  

### **Additional Recommendations**
🔸 **Regular Updates** - Keep all components updated  
🔸 **Strong Admin Passwords** - Use password managers  
🔸 **Two-Factor Authentication** - Enable for all admin accounts  
🔸 **Regular Backups** - Test restore procedures  
🔸 **Monitor Logs** - Set up log monitoring and alerts  

---

## 📈 Performance Optimization

### **Built-in Optimizations**
- **Nginx Caching** - Static file caching with proper headers
- **PHP OpCache** - Bytecode caching for faster execution
- **Redis Object Cache** - Database query result caching
- **Gzip/Brotli Compression** - Reduced bandwidth usage
- **HTTP/2 Support** - Improved connection multiplexing
- **Database Optimization** - Tuned MariaDB configuration

### **WordPress-Specific**
- **W3 Total Cache** - Pre-configured caching plugin
- **Image Optimization** - WebP conversion and compression
- **Database Cleanup** - Automatic cleanup of spam, revisions
- **Query Optimization** - Slow query detection and optimization
- **CDN Integration** - Cloudflare CDN pre-configured

---

## 🌍 Multisite Features

### **Network Setup**
- **Subdomain Support** - `site1.example.com`, `site2.example.com`
- **Subdirectory Support** - `example.com/site1`, `example.com/site2`
- **Custom Domains** - Map any domain to any site
- **SSL for All Sites** - Automatic certificate management

### **Management Tools**
- **Bulk Operations** - Manage multiple sites simultaneously
- **Plugin Management** - Network-wide plugin control
- **Theme Management** - Centralized theme distribution
- **User Management** - Cross-site user access control

---

## 🛒 WooCommerce Optimization

### **Performance Tuning**
- **Session Handling** - Redis-based session storage
- **Cart Caching** - Optimized cart and checkout performance
- **Product Caching** - Intelligent product data caching
- **Database Optimization** - WooCommerce-specific DB tuning

### **Security Enhancements**
- **Payment Security** - PCI DSS compliance ready
- **Order Protection** - Encrypted order data
- **User Data Security** - GDPR compliance features
- **SSL for Checkout** - Enforced HTTPS for sensitive pages

---

## 📚 Documentation

- 📖 **[Installation Guide](https://sebhosting.github.io/seb-ultra-stack/installation/)**
- 🔧 **[Configuration Manual](https://sebhosting.github.io/seb-ultra-stack/configuration/)**
- 🚀 **[Performance Tuning](https://sebhosting.github.io/seb-ultra-stack/performance/)**
- 🛡️ **[Security Hardening](https://sebhosting.github.io/seb-ultra-stack/security/)**
- 🌐 **[Multisite Setup](https://sebhosting.github.io/seb-ultra-stack/multisite/)**
- 🛒 **[WooCommerce Guide](https://sebhosting.github.io/seb-ultra-stack/woocommerce/)**
- 🔄 **[Backup & Recovery](https://sebhosting.github.io/seb-ultra-stack/backup/)**
- 🚨 **[Troubleshooting](https://sebhosting.github.io/seb-ultra-stack/troubleshooting/)**

---

## 🤝 Support & Community

### **Get Help**
- 💬 **[Discord Community](https://discord.gg/sebhosting)** - Real-time chat support
- 📧 **[Email Support](mailto:support@sebhosting.com)** - Direct technical support
- 🐛 **[Issue Tracker](https://github.com/sebhosting/seb-ultra-stack/issues)** - Bug reports and feature requests
- 📚 **[Knowledge Base](https://sebhosting.com/docs)** - Comprehensive documentation

### **Contributing**
We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting pull requests.

### **Sponsors**
Support this project by [becoming a sponsor](https://github.com/sponsors/sebhosting). Your logo will appear here with a link to your website.

---

## 📊 Changelog

### **v3.0.0** (Latest)
- ✨ **PHP 8.4 Support** - Latest PHP with JIT compiler
- 🚀 **Performance Improvements** - 25% faster page loads
- 🛡️ **Enhanced Security** - Updated Fail2Ban rules
- 📱 **Mobile Optimization** - Improved mobile caching
- 🔧 **New Management Tools** - Enhanced CLI commands

### **v2.5.0**
- ✨ **MariaDB 10.11** - Latest stable database version
- 🔄 **Automated Backups** - Scheduled backup system
- 🌐 **Cloudflare Integration** - Seamless CDN setup
- 🛒 **WooCommerce Optimization** - E-commerce performance boost

[View full changelog](CHANGELOG.md)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=sebhosting/seb-ultra-stack&type=Date)](https://star-history.com/#sebhosting/seb-ultra-stack&Date)

---

<div align="center">

### Made with ❤️ by the SEB Hosting Team

**[Website](https://sebhosting.com)** • **[Twitter](https://twitter.com/sebhosting)** • **[LinkedIn](https://linkedin.com/company/sebhosting)**

*Empowering developers to build faster, more secure WordPress sites.*

</div>

---

> **Need custom hosting solutions?** Contact us at [hello@sebhosting.com](mailto:hello@sebhosting.com)
