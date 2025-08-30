---
layout: default
title: Security Hardening
description: Comprehensive security guide for SEB Ultra Stack
---

# 🛡️ Security Hardening

Secure your SEB Ultra Stack with enterprise-grade security measures that protect against modern threats.

## 🚨 Security Overview

SEB Ultra Stack implements defense-in-depth security with multiple layers of protection:

```
┌─────────────────────────────────────────┐
│  Cloudflare WAF + DDoS Protection      │ ← Layer 7
├─────────────────────────────────────────┤
│  SSL/TLS 1.3 + Security Headers        │ ← Layer 6
├─────────────────────────────────────────┤
│  Nginx Security + Rate Limiting        │ ← Layer 5
├─────────────────────────────────────────┤
│  UFW Firewall + Port Restrictions      │ ← Layer 4
├─────────────────────────────────────────┤
│  Fail2Ban + Intrusion Detection        │ ← Layer 3
├─────────────────────────────────────────┤
│  WordPress Hardening + File Perms      │ ← Layer 2
├─────────────────────────────────────────┤
│  OS Hardening + User Management        │ ← Layer 1
└─────────────────────────────────────────┘
```

## 🔒 Quick Security Setup

### **Enable All Security Features**
```bash
# Run comprehensive security hardening
sudo seb-stack harden-security --all

# Check security status
sudo seb-stack security-status

# Run security audit
sudo seb-stack security-audit
```

### **Immediate Security Actions**
```bash
# Change default SSH port
sudo seb-stack change-ssh-port 2222

# Enable automatic security updates
sudo seb-stack enable-auto-updates

# Set up intrusion detection
sudo seb-stack enable-ids

# Configure backup encryption
sudo seb-stack enable-backup-encryption
```

## 🔐 SSL/TLS Configuration

### **Advanced SSL Settings**
Edit `/etc/nginx/conf.d/ssl.conf`:

```nginx
# SSL Configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
ssl_ecdh_curve secp384r1;
ssl_prefer_server_ciphers off;

# SSL Performance
ssl_session_timeout 10m;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;

# SSL Security
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
resolver 1.1.1.1 1.0.0.1 valid=300s;
resolver_timeout 5s;

# Security Headers
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' *.googleapis.com *.gstatic.com; style-src 'self' 'unsafe-inline' *.googleapis.com; img-src 'self' data: *.gravatar.com *.wp.com; font-src 'self' *.googleapis.com *.gstatic.com; connect-src 'self'; frame-src 'self' *.youtube.com *.vimeo.com; object-src 'none'; base-uri 'self'; form-action 'self';" always;

# Hide server information
server_tokens off;
more_set_headers "Server: SEB-Stack";
```

### **SSL Certificate Management**
```bash
# Auto-renew SSL certificates
sudo seb-stack ssl-auto-renew

# Check SSL certificate status
sudo seb-stack ssl-status example.com

# Test SSL configuration
sudo seb-stack ssl-test example.com

# Generate strong DH parameters
sudo openssl dhparam -out /etc/nginx/dhparam.pem 4096
```

## 🔥 Firewall Configuration

### **Advanced UFW Rules**
```bash
# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny forward

# Allow essential services
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Rate limit SSH connections
sudo ufw limit ssh/tcp

# Allow specific IP ranges (office network)
sudo ufw allow from 203.0.113.0/24 to any port 22

# Block known bad IPs
sudo ufw deny from 198.51.100.0/24

# Log dropped packets
sudo ufw logging on

# Enable firewall
sudo ufw enable
```

### **Advanced Firewall Rules**
Create `/etc/ufw/before.rules` additions:

```bash
# Drop invalid packets
-A ufw-before-input -m conntrack --ctstate INVALID -j ufw-logging-deny
-A ufw-before-input -m conntrack --ctstate INVALID -j DROP

# Allow ping
-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT

# Allow DHCP client
-A ufw-before-input -p udp --sport 67 --dport 68 -j ACCEPT

# Drop packets with suspicious flags
-A ufw-before-input -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
-A ufw-before-input -p tcp --tcp-flags ALL ALL -j DROP
-A ufw-before-input -p tcp --tcp-flags ALL NONE -j DROP
-A ufw-before-input -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
-A ufw-before-input -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

# Rate limit connections
-A ufw-before-input -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
-A ufw-before-input -p tcp --dport 443 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
```

## 🚫 Fail2Ban Configuration

### **Advanced Fail2Ban Setup**
Edit `/etc/fail2ban/jail.local`:

```ini
[DEFAULT]
# Ban settings
bantime = 86400
findtime = 3600
maxretry = 3
backend = systemd

# Notification settings
destemail = security@example.com
sender = fail2ban@example.com
mta = sendmail
action = %(action_mwl)s

# Ignore trusted IPs
ignoreip = 127.0.0.1/8 ::1 203.0.113.0/24

[sshd]
enabled = true
port = 2222
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 6

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noproxy]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-nohome]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2

[php-url-fopen]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 1

[wordpress]
enabled = true
port = http,https
logpath = /var/log/auth.log
maxretry = 3

[wordpress-hard]
enabled = true
port = http,https
logpath = /var/log/auth.log
maxretry = 1
findtime = 300
bantime = 86400
```

### **Custom Fail2Ban Filters**
Create `/etc/fail2ban/filter.d/wordpress.conf`:

```ini
[Definition]
failregex = ^<HOST> .* "POST /wp-login.php
            ^<HOST> .* "POST /wp-admin
            ^<HOST> .* "GET /wp-admin.*
            ^<HOST> .* "POST /xmlrpc.php

ignoreregex = ^<HOST> .* "POST /wp-admin/admin-ajax.php
              ^<HOST> .* "GET /wp-admin/admin-ajax.php
```

Create `/etc/fail2ban/filter.d/wordpress-hard.conf`:

```ini
[Definition]
failregex = ^<HOST> .* "(GET|POST) .*/wp-.*\.php.*" (403|404)
            ^<HOST> .* "(GET|POST) .*/administrator.*" (403|404)
            ^<HOST> .* "(GET|POST) .*/(admin|login|wp-login).*" (403|404)

ignoreregex =
```

## 🔒 WordPress Security Hardening

### **WordPress Configuration Security**
Add to `/var/www/example.com/wp-config.php`:

```php
<?php
// Security keys (generate new ones)
define('AUTH_KEY',         'put-unique-phrase-here');
define('SECURE_AUTH_KEY',  'put-unique-phrase-here');
define('LOGGED_IN_KEY',    'put-unique-phrase-here');
define('NONCE_KEY',        'put-unique-phrase-here');
define('AUTH_SALT',        'put-unique-phrase-here');
define('SECURE_AUTH_SALT', 'put-unique-phrase-here');
define('LOGGED_IN_SALT',   'put-unique-phrase-here');
define('NONCE_SALT',       'put-unique-phrase-here');

// Security hardening
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', true);
define('WP_DISALLOW_FILE_MODS', true);
define('AUTOMATIC_UPDATER_DISABLED', true);

// Hide WordPress version
remove_action('wp_head', 'wp_generator');

// Disable XML-RPC
add_filter('xmlrpc_enabled', '__return_false');

// Remove WordPress version from RSS feeds
function remove_wp_version_rss() {
    return '';
}
add_filter('the_generator', 'remove_wp_version_rss');

// Disable theme/plugin editor
define('DISALLOW_FILE_EDIT', true);

// Force SSL for admin
define('FORCE_SSL_ADMIN', true);

// Limit login attempts (if not using plugin)
define('WP_LOGIN_ATTEMPTS', 3);

// Database security
$table_prefix = 'wp_' . substr(md5(uniqid(rand(), true)), 0, 5) . '_';

// Session security
ini_set('session.cookie_httponly', true);
ini_set('session.cookie_secure', true);
ini_set('session.use_only_cookies', true);
```

### **File Permissions Hardening**
```bash
# Set correct WordPress file permissions
sudo find /var/www/example.com/ -type d -exec chmod 755 {} \;
sudo find /var/www/example.com/ -type f -exec chmod 644 {} \;

# Secure wp-config.php
sudo chmod 600 /var/www/example.com/wp-config.php
sudo chown root:root /var/www/example.com/wp-config.php

# Secure .htaccess
sudo chmod 644 /var/www/example.com/.htaccess
sudo chown www-data:www-data /var/www/example.com/.htaccess

# Make wp-content writable for updates
sudo chmod 755 /var/www/example.com/wp-content
sudo chmod 755 /var/www/example.com/wp-content/themes
sudo chmod 755 /var/www/example.com/wp-content/plugins

# Secure uploads directory
sudo chmod 755 /var/www/example.com/wp-content/uploads
```

### **WordPress Security via .htaccess**
Create `/var/www/example.com/.htaccess`:

```apache
# Block access to wp-config.php
<Files wp-config.php>
    Require all denied
</Files>

# Block access to error logs
<Files error_log>
    Require all denied
</Files>

# Block access to .htaccess itself
<Files .htaccess>
    Require all denied
</Files>

# Disable directory browsing
Options -Indexes

# Block WordPress includes
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^wp-admin/includes/ - [F,L]
RewriteRule !^wp-includes/ - [S=3]
RewriteRule ^wp-includes/[^/]+\.php$ - [F,L]
RewriteRule ^wp-includes/js/tinymce/langs/.+\.php - [F,L]
RewriteRule ^wp-includes/theme-compat/ - [F,L]
</IfModule>

# Block access to sensitive files
<FilesMatch "\.(htaccess|htpasswd|ini|phps|fla|psd|log|sh)$">
    Require all denied
</FilesMatch>

# Protect uploads directory
<Directory "/var/www/example.com/wp-content/uploads">
    <FilesMatch "\.php$">
        Require all denied
    </FilesMatch>
</Directory>

# Limit file upload types
<FilesMatch "\.(php|php\.)">
    Require all denied
</FilesMatch>

# Block suspicious requests
<IfModule mod_rewrite.c>
RewriteCond %{QUERY_STRING} \.\.\/ [NC,OR]
RewriteCond %{QUERY_STRING} boot\.ini [NC,OR]
RewriteCond %{QUERY_STRING} tag\= [NC,OR]
RewriteCond %{QUERY_STRING} ftp\: [NC,OR]
RewriteCond %{QUERY_STRING} http\: [NC,OR]
RewriteCond %{QUERY_STRING} https\: [NC,OR]
RewriteCond %{QUERY_STRING} (\<|%3C).*script.*(\>|%3E) [NC,OR]
RewriteCond %{QUERY_STRING} mosConfig_[a-zA-Z_]{1,21}(=|\%3D) [NC,OR]
RewriteCond %{QUERY_STRING} base64_encode.*\(.*\) [NC,OR]
RewriteCond %{QUERY_STRING} ^.*(\[|\]|\(|\)|<|>|ê|"|;|\?|\*|=$).* [NC,OR]
RewriteCond %{QUERY_STRING} ^.*("|'|<|>|\|{|\||`).* [NC,OR]
RewriteCond %{QUERY_STRING} ^.*(%24&x).* [NC,OR]
RewriteCond %{QUERY_STRING} ^.*(%0|%A|%B|%C|%D|%E|%F|127\.0).* [NC,OR]
RewriteCond %{QUERY_STRING} ^.*(globals|encode|localhost|loopback).* [NC,OR]
RewriteCond %{QUERY_STRING} ^.*(request|insert|union|declare|drop).* [NC]
RewriteRule ^(.*)$ - [F,L]
</IfModule>

# Rate limiting
<IfModule mod_evasive24.c>
    DOSHashTableSize    2048
    DOSPageCount        5
    DOSPageInterval     1
    DOSSiteCount        50
    DOSSiteInterval     1
    DOSBlockingPeriod   600
</IfModule>
```

## 👤 User and Access Security

### **System User Hardening**
```bash
# Create dedicated web user
sudo adduser --system --group --home /var/www --shell /bin/false webuser

# Lock unnecessary users
sudo usermod -L daemon
sudo usermod -L bin
sudo usermod -L sys
sudo usermod -L games

# Set password policies
sudo nano /etc/login.defs
# PASS_MAX_DAYS   90
# PASS_MIN_DAYS   7
# PASS_WARN_AGE   14
# PASS_MIN_LEN    12

# Configure PAM for strong passwords
sudo nano /etc/pam.d/common-password
# Add: password requisite pam_pwquality.so retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
```

### **SSH Hardening**
Edit `/etc/ssh/sshd_config`:

```bash
# SSH Security Configuration
Port 2222
Protocol 2

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Security settings
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
MaxAuthTries 3
MaxSessions 2
MaxStartups 10:30:60

# Restrict users/groups
AllowUsers your_username
DenyUsers root guest

# Network settings
AddressFamily inet
ListenAddress 0.0.0.0

# Logging
SyslogFacility AUTHPRIV
LogLevel INFO

# Disable unused features
AllowAgentForwarding no
AllowTcpForwarding no
GatewayPorts no
X11Forwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
Compression no
```

### **SSH Key Management**
```bash
# Generate strong SSH key pair
ssh-keygen -t ed25519 -b 4096 -C "your_email@example.com"

# Add public key to server
mkdir -p ~/.ssh
echo "your_public_key_here" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Disable password authentication after key setup
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## 🛡️ Database Security

### **MariaDB Security Hardening**
```bash
# Run MySQL secure installation
sudo mysql_secure_installation

# Create database user with limited privileges
mysql -u root -p << EOF
CREATE DATABASE wordpress_db;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'strong_password_here';
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON wordpress_db.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
EXIT
EOF
```

### **Database Configuration Security**
Edit `/etc/mysql/mariadb.conf.d/99-security.cnf`:

```ini
[mysqld]
# Network security
bind-address = 127.0.0.1
skip-networking = false
skip-name-resolve

# Disable dangerous features
local-infile = 0
skip-show-database
safe-user-create = 1

# Logging
general_log = 0
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log

# Security settings
secure_auth = 1
sql_mode = STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION

# Connection limits
max_connections = 100
max_user_connections = 50
max_connect_errors = 100000

# Query limits
max_allowed_packet = 64M
```

### **Database Backup Security**
```bash
# Create encrypted database backup
sudo seb-stack backup-db --encrypt --password="backup_password"

# Set up automated encrypted backups
sudo crontab -e
# Add: 0 2 * * * /usr/local/bin/seb-stack backup-db --encrypt --password="backup_password" --rotate=30
```

## 🔍 Security Monitoring

### **Intrusion Detection System**
```bash
# Install and configure AIDE
sudo apt install aide
sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Set up daily AIDE checks
echo "0 3 * * * root /usr/bin/aide --check" | sudo tee -a /etc/crontab

# Install rkhunter for rootkit detection
sudo apt install rkhunter
sudo rkhunter --update
sudo rkhunter --check --skip-keypress
```

### **Log Monitoring Setup**
Create `/etc/rsyslog.d/99-seb-stack.conf`:

```bash
# Security log monitoring
auth,authpriv.*                 /var/log/auth.log
mail.*                          /var/log/mail.log
daemon.*                        /var/log/daemon.log
kern.*                          /var/log/kern.log
user.*                          /var/log/user.log
mail.info                       /var/log/mail.info
mail.warn                       /var/log/mail.warn
mail.err                        /var/log/mail.err
*.=debug                        /var/log/debug
*.=info;*.=notice;*.=warn;\
        auth,authpriv.none;\
        cron,daemon.none;\
        mail,news.none          /var/log/messages

# Remote logging (optional)
# *.* @@logserver.example.com:514
```

### **Security Alerting**
Create `/usr/local/bin/security-monitor.sh`:

```bash
#!/bin/bash

LOG_FILE="/var/log/seb-stack/security-alerts.log"
ADMIN_EMAIL="security@example.com"

# Check for failed login attempts
FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | tail -100 | wc -l)
if [ $FAILED_LOGINS -gt 10 ]; then
    echo "$(date): High number of failed logins detected: $FAILED_LOGINS" >> $LOG_FILE
    echo "Security Alert: $FAILED_LOGINS failed login attempts detected" | mail -s "Security Alert" $ADMIN_EMAIL
fi

# Check for root login attempts
ROOT_ATTEMPTS=$(grep "root" /var/log/auth.log | grep "Failed" | tail -50 | wc -l)
if [ $ROOT_ATTEMPTS -gt 0 ]; then
    echo "$(date): Root login attempts detected: $ROOT_ATTEMPTS" >> $LOG_FILE
    echo "Security Alert: Root login attempts detected" | mail -s "Critical Security Alert" $ADMIN_EMAIL
fi

# Check for unusual network activity
CONNECTIONS=$(netstat -tn | grep :80 | wc -l)
if [ $CONNECTIONS -gt 100 ]; then
    echo "$(date): High number of connections detected: $CONNECTIONS" >> $LOG_FILE
fi

# Check disk usage
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "$(date): Disk usage critical: ${DISK_USAGE}%" >> $LOG_FILE
    echo "Alert: Disk usage is ${DISK_USAGE}%" | mail -s "Disk Space Alert" $ADMIN_EMAIL
fi
```

### **Automated Security Updates**
```bash
# Enable automatic security updates
sudo apt install unattended-upgrades

# Configure automatic updates
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades

# Update configuration
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "admin@example.com";
```

## 🔒 Advanced Security Measures

### **Web Application Firewall (WAF)**
Install ModSecurity for Nginx:

```bash
# Install ModSecurity
sudo apt install libmodsecurity3 libnginx-mod-http-modsecurity

# Download OWASP rules
sudo git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /etc/modsecurity/
sudo cp /etc/modsecurity/owasp-modsecurity-crs/crs-setup.conf.example /etc/modsecurity/crs-setup.conf

# Configure ModSecurity
sudo nano /etc/modsecurity/modsecurity.conf
# Set: SecRuleEngine On
```

### **DDoS Protection**
Configure rate limiting in Nginx:

```nginx
# Rate limiting configuration
http {
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/m;
    limit_req_zone $binary_remote_addr zone=search:10m rate=5r/m;
    limit_req_zone $binary_remote_addr zone=global:10m rate=10r/s;
    
    # Connection limiting
    limit_conn_zone $binary_remote_addr zone=perip:10m;
    limit_conn_zone $server_name zone=perserver:10m;
    
    server {
        # Apply limits
        limit_req zone=global burst=20 nodelay;
        limit_conn perip 10;
        limit_conn perserver 100;
        
        location = /wp-login.php {
            limit_req zone=login burst=2 nodelay;
        }
        
        location ~ /wp-json/wp/v2/search {
            limit_req zone=search burst=3 nodelay;
        }
    }
}
```

### **File Integrity Monitoring**
Set up OSSEC for comprehensive monitoring:

```bash
# Install OSSEC
wget -q -O - https://updates.atomicorp.com/installers/atomic | sudo bash
sudo apt install ossec-hids-server

# Configure OSSEC
sudo nano /var/ossec/etc/ossec.conf

# Add file integrity monitoring
<syscheck>
    <frequency>7200</frequency>
    <directories check_all="yes">/etc,/usr/bin,/usr/sbin</directories>
    <directories check_all="yes">/bin,/sbin</directories>
    <directories check_all="yes">/var/www</directories>
</syscheck>
```

## 🚨 Incident Response

### **Security Incident Checklist**
```bash
# Immediate response script
#!/bin/bash
# /usr/local/bin/incident-response.sh

echo "=== SECURITY INCIDENT RESPONSE ==="
echo "Timestamp: $(date)"

# 1. Document current system state
ps aux > /tmp/incident-processes.txt
netstat -tulnp > /tmp/incident-connections.txt
df -h > /tmp/incident-disk-usage.txt

# 2. Check for unauthorized users
cut -d: -f1 /etc/passwd > /tmp/incident-users.txt

# 3. Check recent logins
last -n 50 > /tmp/incident-logins.txt

# 4. Check running processes
lsof -i > /tmp/incident-open-files.txt

# 5. Backup critical logs
cp /var/log/auth.log /tmp/incident-auth-log-backup.txt
cp /var/log/syslog /tmp/incident-syslog-backup.txt

# 6. Check file modifications (last 24 hours)
find /var/www -type f -mtime -1 > /tmp/incident-modified-files.txt

echo "Incident response data collected in /tmp/incident-*"
echo "Consider isolating the system and contacting security team"
```

### **Emergency Security Commands**
```bash
# Block all traffic except SSH (emergency mode)
sudo iptables -F
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -j DROP

# Kill all web services
sudo systemctl stop nginx php8.4-fpm

# Enable emergency maintenance mode
echo "maintenance" | sudo tee /var/www/html/maintenance.flag

# Check for compromised accounts
sudo grep -E "su|sudo" /var/log/auth.log | tail -20
```

## ✅ Security Audit Checklist

### **Daily Security Tasks**
- [ ] Review failed login attempts
- [ ] Check Fail2Ban status and banned IPs
- [ ] Monitor unusual network connections
- [ ] Review security logs for anomalies
- [ ] Verify backup completion and integrity

### **Weekly Security Tasks**
- [ ] Run full security scan
- [ ] Update security signatures and rules
- [ ] Review user access and permissions
- [ ] Check SSL certificate expiration dates
- [ ] Audit file permission changes

### **Monthly Security Tasks**
- [ ] Review and update security configurations
- [ ] Penetration testing (automated)
- [ ] Security awareness training review
- [ ] Incident response plan testing
- [ ] Comprehensive vulnerability scan

### **Security Monitoring Commands**
```bash
# Comprehensive security check
sudo seb-stack security-audit --full

# Check for security updates
sudo seb-stack security-updates

# Review security logs
sudo seb-stack security-logs --last-24h

# Test security configurations
sudo seb-stack security-test --all
```

---

**Next:** Set up [Backup & Recovery](../backup/) systems to protect your secured infrastructure.
