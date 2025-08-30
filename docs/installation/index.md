---
layout: default
title: Installation Guide
description: Complete step-by-step installation guide for SEB Ultra Stack
---

# 🚀 Installation Guide

Get SEB Ultra Stack up and running in minutes with our automated installation process.

## 📋 Prerequisites

### **System Requirements**

#### **Minimum Requirements**
- **OS**: Ubuntu 20.04+ LTS (fresh installation recommended)
- **RAM**: 2GB (4GB recommended)
- **Storage**: 20GB SSD
- **CPU**: 2 vCPU cores
- **Network**: Stable internet connection

#### **Recommended for Production**
- **OS**: Ubuntu 22.04+ LTS
- **RAM**: 8GB+
- **Storage**: 50GB+ NVMe SSD
- **CPU**: 4+ vCPU cores
- **Network**: 1Gbps connection

### **Access Requirements**
- Root or sudo access to your server
- SSH access to your server
- Domain name pointed to your server IP (optional, can be configured later)

## ⚡ One-Click Installation

### **Quick Install**
```bash
curl -sSL https://sebhosting.com/install.sh | bash
```

That's it! The installation script will automatically:
- Update your system packages
- Install and configure all stack components
- Set up security hardening
- Configure optimal performance settings
- Create initial WordPress installation

### **Installation with Custom Options**
```bash
# Download installer first
wget https://sebhosting.com/install.sh

# Make executable
chmod +x install.sh

# Run with options
sudo ./install.sh --domain=example.com --email=admin@example.com
```

## 🔧 Step-by-Step Installation

### **Step 1: Server Preparation**
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required dependencies
sudo apt install -y curl wget git unzip software-properties-common
```

### **Step 2: Download and Run Installer**
```bash
# Download the installer
curl -sSL https://sebhosting.com/install.sh -o install.sh

# Review the script (recommended)
less install.sh

# Make executable and run
chmod +x install.sh
sudo ./install.sh
```

### **Step 3: Follow Interactive Setup**
The installer will guide you through:

1. **Domain Configuration**
   - Primary domain name
   - SSL certificate setup
   - Cloudflare integration (optional)

2. **Database Setup**
   - MySQL root password
   - WordPress database credentials
   - Database optimization settings

3. **WordPress Configuration**
   - Admin username and password
   - Site title and description
   - Multisite network setup

4. **Security Settings**
   - Firewall rules
   - Fail2Ban configuration
   - SSH key setup (recommended)

## 📊 Installation Process

### **What Gets Installed**

#### **Web Server Stack**
- **Nginx 1.24+** - High-performance web server
- **PHP 8.4** - Latest PHP with FPM and OpCache
- **MariaDB 10.11+** - Optimized database server
- **Redis 7+** - In-memory caching system

#### **WordPress Ecosystem**
- **WordPress 6.6+** - Latest WordPress core
- **WP-CLI** - Command-line WordPress management
- **Essential plugins** - Caching, security, optimization

#### **Security Components**
- **UFW Firewall** - Uncomplicated Firewall
- **Fail2Ban** - Intrusion prevention system
- **SSL/TLS Certificates** - Let's Encrypt integration
- **Security headers** - HSTS, CSP, and more

#### **Management Tools**
- **PHPMyAdmin** - Database management interface
- **Composer** - PHP dependency manager
- **Git** - Version control system
- **SEB Stack CLI** - Custom management commands

### **Installation Timeline**
| Step | Duration | Description |
|------|----------|-------------|
| System Update | 2-5 min | Package updates and dependencies |
| Stack Installation | 5-10 min | Core components installation |
| Configuration | 3-5 min | Optimization and security setup |
| WordPress Setup | 2-3 min | WordPress installation and configuration |
| **Total** | **12-23 min** | Complete stack ready |

## ✅ Post-Installation Verification

### **Test Web Server**
```bash
# Check Nginx status
sudo systemctl status nginx

# Test configuration
sudo nginx -t

# Check if site loads
curl -I http://your-domain.com
```

### **Test Database**
```bash
# Check MariaDB status
sudo systemctl status mariadb

# Test connection
mysql -u root -p -e "SHOW DATABASES;"
```

### **Test PHP**
```bash
# Check PHP-FPM status
sudo systemctl status php8.4-fpm

# Test PHP functionality
php -v
php -m | grep -E "(redis|opcache|mysql)"
```

### **Test Cache**
```bash
# Check Redis status
sudo systemctl status redis-server

# Test Redis connection
redis-cli ping
```

## 🌐 Domain Configuration

### **Add Your First Domain**
```bash
# Add domain to stack
sudo seb-stack add-domain example.com

# Enable SSL
sudo seb-stack enable-ssl example.com

# Verify SSL certificate
sudo seb-stack check-ssl example.com
```

### **Configure DNS**
Point your domain's A record to your server IP:
```
Type: A
Name: @
Value: YOUR_SERVER_IP
TTL: 300
```

For www subdomain:
```
Type: CNAME
Name: www
Value: example.com
TTL: 300
```

## 🔧 Custom Installation Options

### **Environment Variables**
```bash
# Set before installation
export SEB_DOMAIN="example.com"
export SEB_EMAIL="admin@example.com"
export SEB_DB_PASSWORD="secure_password"
export SEB_WP_ADMIN="admin_user"
export SEB_WP_PASSWORD="secure_wp_password"

# Run installer
curl -sSL https://sebhosting.com/install.sh | bash
```

### **Configuration File**
Create `/tmp/seb-config.conf`:
```ini
[general]
domain=example.com
email=admin@example.com

[database]
root_password=secure_db_password
wp_db_name=wordpress
wp_db_user=wp_user
wp_db_password=wp_password

[wordpress]
admin_user=admin
admin_password=secure_wp_password
site_title=My Awesome Site

[security]
enable_fail2ban=true
enable_firewall=true
ssh_port=22
```

Run with config:
```bash
sudo ./install.sh --config=/tmp/seb-config.conf
```

## 🚨 Troubleshooting Installation

### **Common Issues**

#### **Installation Fails**
```bash
# Check installer logs
tail -f /var/log/seb-stack/install.log

# Re-run specific components
sudo seb-stack install --component=nginx
sudo seb-stack install --component=php
```

#### **Permission Errors**
```bash
# Fix web directory permissions
sudo chown -R www-data:www-data /var/www/
sudo find /var/www/ -type d -exec chmod 755 {} \;
sudo find /var/www/ -type f -exec chmod 644 {} \;
```

#### **Database Connection Issues**
```bash
# Reset database passwords
sudo seb-stack reset-db-password

# Test database connection
mysql -u wp_user -p wordpress -e "SELECT 1;"
```

#### **SSL Certificate Problems**
```bash
# Force SSL certificate renewal
sudo certbot renew --force-renewal

# Check certificate status
sudo certbot certificates
```

### **Getting Help**
If you encounter issues:

1. **Check logs**: `sudo seb-stack logs`
2. **Run diagnostics**: `sudo seb-stack diagnose`
3. **Contact support**: [support@sebhosting.com](mailto:support@sebhosting.com)
4. **Community help**: [Discord](https://discord.gg/sebhosting)

## 🎯 Next Steps

After successful installation:

1. **[Configure your stack](../configuration/)** - Customize settings
2. **[Set up domains](../domain-setup/)** - Add additional domains
3. **[Optimize performance](../performance/)** - Fine-tune for speed
4. **[Harden security](../security/)** - Additional security measures
5. **[Set up backups](../backup/)** - Protect your data

---

**🎉 Congratulations!** Your SEB Ultra Stack is now ready. Visit your domain to see your new WordPress site!
