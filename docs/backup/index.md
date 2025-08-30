---
layout: default
title: Backup & Recovery
description: Comprehensive backup and disaster recovery guide for SEB Ultra Stack
---

# 🔄 Backup & Recovery

Protect your SEB Ultra Stack with enterprise-grade backup strategies and disaster recovery procedures.

## 🛡️ Backup Strategy Overview

### **3-2-1 Backup Rule Implementation**
```
┌─────────────────────────────────────────┐
│  3 Copies of Critical Data              │
├─────────────────────────────────────────┤
│  ├─ Production Data (Live)              │ ← Original
│  ├─ Local Backup (On-site)              │ ← Copy 1
│  └─ Remote Backup (Off-site)            │ ← Copy 2
├─────────────────────────────────────────┤
│  2 Different Storage Media Types        │
├─────────────────────────────────────────┤
│  ├─ Local SSD/NVMe Storage              │
│  └─ Cloud Storage (S3/Google/Azure)     │
├─────────────────────────────────────────┤
│  1 Off-site Backup Location             │
├─────────────────────────────────────────┤
│  └─ Geographically Separated            │
└─────────────────────────────────────────┘
```

### **Backup Components**
- **Database Dumps** - WordPress/WooCommerce data
- **File System** - WordPress files, uploads, themes, plugins
- **Configuration Files** - Nginx, PHP, MariaDB, Redis configs
- **SSL Certificates** - Let's Encrypt and custom certificates
- **Log Files** - System and application logs
- **Cache Data** - Redis dumps (optional)

## ⚡ Quick Backup Setup

### **Enable Automated Backups**
```bash
# Initialize backup system
sudo seb-stack backup-init

# Enable daily automated backups
sudo seb-stack backup-schedule --daily --time="02:00" --retain=30

# Configure remote backup storage
sudo seb-stack backup-configure-remote --provider=s3 --bucket=my-backups --region=us-east-1

# Test backup system
sudo seb-stack backup-test --full
```

### **Manual Backup Commands**
```bash
# Full stack backup
sudo seb-stack backup --full --encrypt

# Site-specific backup
sudo seb-stack backup example.com

# Database-only backup
sudo seb-stack backup-db --all-sites

# Configuration backup
sudo seb-stack backup-config

# Files-only backup (no database)
sudo seb-stack backup-files example.com
```

## 🗄️ Database Backup Strategies

### **Automated Database Backups**
Create `/usr/local/bin/database-backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR

#!/bin/bash

BACKUP_DIR="/var/backups/databases"
S3_BUCKET="your-backup-bucket"
MYSQL_USER="backup_user"
MYSQL_PASS="secure_backup_password"
ENCRYPTION_KEY="your_encryption_key"
RETENTION_DAYS=30
LOG_FILE="/var/log/seb-stack/backup.log"

# Create backup directory
mkdir -p $BACKUP_DIR

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Database backup function
backup_database() {
    local db_name=$1
    local backup_file="$BACKUP_DIR/${db_name}_$(date +%Y%m%d_%H%M%S).sql"
    
    log_message "Starting backup of database: $db_name"
    
    # Create database dump with compression
    mysqldump --user=$MYSQL_USER --password=$MYSQL_PASS \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --hex-blob \
        --opt \
        $db_name | gzip > "${backup_file}.gz"
    
    if [ $? -eq 0 ]; then
        log_message "Database dump completed: ${backup_file}.gz"
        
        # Encrypt backup
        if [ ! -z "$ENCRYPTION_KEY" ]; then
            openssl enc -aes-256-cbc -salt -in "${backup_file}.gz" -out "${backup_file}.gz.enc" -k "$ENCRYPTION_KEY"
            rm "${backup_file}.gz"
            backup_file="${backup_file}.gz.enc"
            log_message "Backup encrypted: $backup_file"
        else
            backup_file="${backup_file}.gz"
        fi
        
        # Upload to S3
        if [ ! -z "$S3_BUCKET" ]; then
            aws s3 cp "$backup_file" "s3://$S3_BUCKET/databases/$(basename $backup_file)"
            if [ $? -eq 0 ]; then
                log_message "Backup uploaded to S3: s3://$S3_BUCKET/databases/$(basename $backup_file)"
            else
                log_message "ERROR: Failed to upload backup to S3"
            fi
        fi
        
    else
        log_message "ERROR: Database backup failed for $db_name"
        exit 1
    fi
}

# Get list of databases (excluding system databases)
DATABASES=$(mysql --user=$MYSQL_USER --password=$MYSQL_PASS -e "SHOW DATABASES;" | grep -Ev "^(Database|information_schema|performance_schema|mysql|sys)$")

# Backup each database
for db in $DATABASES; do
    backup_database $db
done

# WordPress multisite backup (if applicable)
if wp core is-installed --network 2>/dev/null; then
    log_message "WordPress multisite detected, creating network backup"
    
    # Get all site databases
    SITE_DATABASES=$(wp site list --field=url | while read site; do
        wp --url=$site config get DB_NAME
    done | sort -u)
    
    for site_db in $SITE_DATABASES; do
        backup_database $site_db
    done
fi

# Clean up old local backups
find $BACKUP_DIR -name "*.sql.gz*" -mtime +$RETENTION_DAYS -delete
log_message "Cleaned up backups older than $RETENTION_DAYS days"

# Backup verification
LATEST_BACKUP=$(ls -t $BACKUP_DIR/*.sql.gz* | head -1)
if [ -f "$LATEST_BACKUP" ]; then
    BACKUP_SIZE=$(du -h "$LATEST_BACKUP" | cut -f1)
    log_message "Latest backup size: $BACKUP_SIZE"
    
    # Test backup integrity
    if [[ "$LATEST_BACKUP" == *.enc ]]; then
        # Test encrypted backup
        openssl enc -aes-256-cbc -d -in "$LATEST_BACKUP" -k "$ENCRYPTION_KEY" | gunzip -t
    else
        # Test unencrypted backup
        gunzip -t "$LATEST_BACKUP"
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Backup integrity verified successfully"
    else
        log_message "ERROR: Backup integrity check failed"
        echo "CRITICAL: Backup integrity check failed for $LATEST_BACKUP" | mail -s "Backup Alert" admin@example.com
    fi
fi

log_message "Database backup process completed"
```

### **Advanced Database Backup Configuration**
Create `/etc/mysql/mariadb.conf.d/99-backup.cnf`:

```ini
[mysqldump]
# Backup optimization settings
single-transaction
routines
triggers
events
hex-blob
opt
compress
quick
lock-tables=false

# Binary log settings for point-in-time recovery
[mysqld]
log_bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7
sync_binlog = 1
innodb_flush_log_at_trx_commit = 1

# Backup user privileges
# CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'secure_password';
# GRANT SELECT, SHOW VIEW, RELOAD, REPLICATION CLIENT ON *.* TO 'backup_user'@'localhost';
# FLUSH PRIVILEGES;
```

### **Point-in-Time Recovery Setup**
```bash
# Enable binary logging for point-in-time recovery
sudo mysql -e "SET GLOBAL log_bin = 'mysql-bin';"
sudo mysql -e "SET GLOBAL binlog_format = 'ROW';"

# Create point-in-time recovery script
cat > /usr/local/bin/mysql-pit-recovery.sh << 'EOF'
#!/bin/bash

BACKUP_FILE=$1
RECOVERY_TIME=$2
MYSQL_USER="root"
MYSQL_PASS="root_password"
BINLOG_DIR="/var/log/mysql"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <backup_file> <recovery_time>"
    echo "Example: $0 /var/backups/db_backup.sql '2024-01-15 14:30:00'"
    exit 1
fi

echo "Starting point-in-time recovery to: $RECOVERY_TIME"

# Restore from backup
mysql --user=$MYSQL_USER --password=$MYSQL_PASS < $BACKUP_FILE

# Apply binary logs up to specified time
for binlog in $(ls $BINLOG_DIR/mysql-bin.*); do
    mysqlbinlog --stop-datetime="$RECOVERY_TIME" $binlog | mysql --user=$MYSQL_USER --password=$MYSQL_PASS
done

echo "Point-in-time recovery completed"
EOF

chmod +x /usr/local/bin/mysql-pit-recovery.sh
```

## 📁 File System Backup

### **WordPress Files Backup**
Create `/usr/local/bin/wordpress-backup.sh`:

```bash
#!/bin/bash

SITE_DIR="/var/www"
BACKUP_DIR="/var/backups/files"
S3_BUCKET="your-backup-bucket"
ENCRYPTION_KEY="your_encryption_key"
RETENTION_DAYS=14
LOG_FILE="/var/log/seb-stack/file-backup.log"

# Create backup directory
mkdir -p $BACKUP_DIR

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

backup_site_files() {
    local site_name=$1
    local site_path="$SITE_DIR/$site_name"
    local backup_file="$BACKUP_DIR/${site_name}_files_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    if [ ! -d "$site_path" ]; then
        log_message "ERROR: Site directory does not exist: $site_path"
        return 1
    fi
    
    log_message "Starting file backup for site: $site_name"
    
    # Create compressed archive excluding cache and temporary files
    tar -czf "$backup_file" \
        -C "$site_path" \
        --exclude="wp-content/cache/*" \
        --exclude="wp-content/uploads/cache/*" \
        --exclude="wp-content/w3tc-cache/*" \
        --exclude="wp-content/backup-db/*" \
        --exclude="wp-content/updraft/*" \
        --exclude="*.log" \
        --exclude=".htaccess.bak" \
        --exclude="error_log" \
        --exclude="debug.log" \
        .
    
    if [ $? -eq 0 ]; then
        log_message "File backup completed: $backup_file"
        
        # Get backup size
        BACKUP_SIZE=$(du -h "$backup_file" | cut -f1)
        log_message "Backup size: $BACKUP_SIZE"
        
        # Encrypt backup if key provided
        if [ ! -z "$ENCRYPTION_KEY" ]; then
            openssl enc -aes-256-cbc -salt -in "$backup_file" -out "${backup_file}.enc" -k "$ENCRYPTION_KEY"
            rm "$backup_file"
            backup_file="${backup_file}.enc"
            log_message "Backup encrypted: $backup_file"
        fi
        
        # Upload to S3
        if [ ! -z "$S3_BUCKET" ]; then
            aws s3 cp "$backup_file" "s3://$S3_BUCKET/files/$(basename $backup_file)"
            if [ $? -eq 0 ]; then
                log_message "File backup uploaded to S3"
            else
                log_message "ERROR: Failed to upload file backup to S3"
            fi
        fi
        
        # Verify backup integrity
        if [[ "$backup_file" == *.enc ]]; then
            openssl enc -aes-256-cbc -d -in "$backup_file" -k "$ENCRYPTION_KEY" | tar -tzf - > /dev/null 2>&1
        else
            tar -tzf "$backup_file" > /dev/null 2>&1
        fi
        
        if [ $? -eq 0 ]; then
            log_message "File backup integrity verified"
        else
            log_message "ERROR: File backup integrity check failed"
        fi
        
    else
        log_message "ERROR: File backup failed for $site_name"
        return 1
    fi
}

# Backup all WordPress sites
for site_dir in $SITE_DIR/*/; do
    if [ -f "$site_dir/wp-config.php" ]; then
        site_name=$(basename "$site_dir")
        backup_site_files "$site_name"
    fi
done

# Clean up old backups
find $BACKUP_DIR -name "*_files_*.tar.gz*" -mtime +$RETENTION_DAYS -delete
log_message "Cleaned up file backups older than $RETENTION_DAYS days"

log_message "File backup process completed"
```

### **Incremental Backup with rsync**
```bash
# Set up incremental backup system
cat > /usr/local/bin/incremental-backup.sh << 'EOF'
#!/bin/bash

SOURCE_DIR="/var/www"
BACKUP_BASE="/var/backups/incremental"
CURRENT_DATE=$(date +%Y%m%d_%H%M%S)
CURRENT_BACKUP="$BACKUP_BASE/backup_$CURRENT_DATE"
LATEST_LINK="$BACKUP_BASE/latest"
LOG_FILE="/var/log/seb-stack/incremental-backup.log"

mkdir -p "$BACKUP_BASE"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Create incremental backup using hard links
if [ -d "$LATEST_LINK" ]; then
    # Incremental backup
    rsync -avH --delete --link-dest="$LATEST_LINK" "$SOURCE_DIR/" "$CURRENT_BACKUP/"
    log_message "Incremental backup completed: $CURRENT_BACKUP"
else
    # First full backup
    rsync -av "$SOURCE_DIR/" "$CURRENT_BACKUP/"
    log_message "Full backup completed: $CURRENT_BACKUP"
fi

# Update latest link
rm -f "$LATEST_LINK"
ln -s "$CURRENT_BACKUP" "$LATEST_LINK"

# Keep only last 7 days of incremental backups
find "$BACKUP_BASE" -maxdepth 1 -type d -name "backup_*" -mtime +7 -exec rm -rf {} \;

log_message "Incremental backup process completed"
EOF

chmod +x /usr/local/bin/incremental-backup.sh
```

## ☁️ Remote Backup Configuration

### **Amazon S3 Backup Setup**
```bash
# Install AWS CLI
sudo apt install awscli

# Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format

# Create S3 backup bucket
aws s3 mb s3://your-backup-bucket --region us-east-1

# Set up bucket lifecycle policy
cat > /tmp/lifecycle.json << 'EOF'
{
    "Rules": [
        {
            "ID": "BackupRetention",
            "Status": "Enabled",
            "Filter": {"Prefix": ""},
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 90,
                    "StorageClass": "GLACIER"
                },
                {
                    "Days": 365,
                    "StorageClass": "DEEP_ARCHIVE"
                }
            ],
            "Expiration": {
                "Days": 2555
            }
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration --bucket your-backup-bucket --lifecycle-configuration file:///tmp/lifecycle.json
```

### **Google Cloud Storage Backup**
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Create backup bucket
gsutil mb gs://your-backup-bucket

# Set up lifecycle policy
cat > /tmp/lifecycle.json << 'EOF'
{
  "rule": [
    {
      "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
      "condition": {"age": 30}
    },
    {
      "action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
      "condition": {"age": 90}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"age": 2555}
    }
  ]
}
EOF

gsutil lifecycle set /tmp/lifecycle.json gs://your-backup-bucket
```

### **Automated Remote Sync**
Create `/usr/local/bin/remote-sync.sh`:

```bash
#!/bin/bash

LOCAL_BACKUP_DIR="/var/backups"
S3_BUCKET="s3://your-backup-bucket"
GCS_BUCKET="gs://your-backup-bucket"
LOG_FILE="/var/log/seb-stack/remote-sync.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Sync to S3
log_message "Starting S3 sync"
aws s3 sync $LOCAL_BACKUP_DIR $S3_BUCKET --delete --storage-class STANDARD_IA
if [ $? -eq 0 ]; then
    log_message "S3 sync completed successfully"
else
    log_message "ERROR: S3 sync failed"
fi

# Sync to Google Cloud Storage (optional secondary)
log_message "Starting GCS sync"
gsutil -m rsync -r -d $LOCAL_BACKUP_DIR $GCS_BUCKET
if [ $? -eq 0 ]; then
    log_message "GCS sync completed successfully"
else
    log_message "ERROR: GCS sync failed"
fi

log_message "Remote sync process completed"
```

## 🔧 Configuration Backup

### **System Configuration Backup**
Create `/usr/local/bin/config-backup.sh`:

```bash
#!/bin/bash

CONFIG_BACKUP_DIR="/var/backups/config"
BACKUP_FILE="$CONFIG_BACKUP_DIR/config_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
LOG_FILE="/var/log/seb-stack/config-backup.log"

mkdir -p $CONFIG_BACKUP_DIR

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Starting configuration backup"

# Create temporary directory for config files
TEMP_DIR=$(mktemp -d)
CONFIG_DIR="$TEMP_DIR/seb-stack-config"
mkdir -p $CONFIG_DIR

# Backup system configurations
cp -r /etc/nginx $CONFIG_DIR/
cp -r /etc/php $CONFIG_DIR/
cp -r /etc/mysql $CONFIG_DIR/
cp -r /etc/redis $CONFIG_DIR/
cp -r /etc/ssl $CONFIG_DIR/
cp -r /etc/letsencrypt $CONFIG_DIR/
cp -r /etc/fail2ban $CONFIG_DIR/
cp -r /etc/ufw $CONFIG_DIR/
cp -r /etc/seb-stack $CONFIG_DIR/ 2>/dev/null || true

# Backup important system files
mkdir -p $CONFIG_DIR/system
cp /etc/hosts $CONFIG_DIR/system/
cp /etc/hostname $CONFIG_DIR/system/
cp /etc/fstab $CONFIG_DIR/system/
cp /etc/crontab $CONFIG_DIR/system/
cp /etc/ssh/sshd_config $CONFIG_DIR/system/

# Backup user crontabs
mkdir -p $CONFIG_DIR/cron
for user in $(ls /var/spool/cron/crontabs/ 2>/dev/null); do
    cp /var/spool/cron/crontabs/$user $CONFIG_DIR/cron/
done

# Create archive
tar -czf $BACKUP_FILE -C $TEMP_DIR seb-stack-config

# Clean up
rm -rf $TEMP_DIR

if [ -f $BACKUP_FILE ]; then
    BACKUP_SIZE=$(du -h $BACKUP_FILE | cut -f1)
    log_message "Configuration backup completed: $BACKUP_FILE ($BACKUP_SIZE)"
    
    # Upload to remote storage
    if command -v aws &> /dev/null; then
        aws s3 cp $BACKUP_FILE s3://your-backup-bucket/config/
        log_message "Configuration backup uploaded to S3"
    fi
    
else
    log_message "ERROR: Configuration backup failed"
fi

# Keep only last 30 days of config backups
find $CONFIG_BACKUP_DIR -name "config_backup_*.tar.gz" -mtime +30 -delete

log_message "Configuration backup process completed"
```

## 🔄 Disaster Recovery Procedures

### **Complete System Recovery Script**
Create `/usr/local/bin/disaster-recovery.sh`:

```bash
#!/bin/bash

BACKUP_SOURCE=$1
RECOVERY_TYPE=$2
LOG_FILE="/var/log/seb-stack/recovery.log"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <backup_source> <recovery_type>"
    echo "Recovery types: full, database-only, files-only, config-only"
    exit 1
fi

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Starting disaster recovery: $RECOVERY_TYPE from $BACKUP_SOURCE"

case $RECOVERY_TYPE in
    "full")
        log_message "Performing full system recovery"
        
        # Stop services
        systemctl stop nginx php8.4-fpm mariadb redis-server
        
        # Restore configuration
        if [ -f "$BACKUP_SOURCE/config_backup_latest.tar.gz" ]; then
            tar -xzf "$BACKUP_SOURCE/config_backup_latest.tar.gz" -C /
            log_message "Configuration restored"
        fi
        
        # Restore databases
        for db_backup in $BACKUP_SOURCE/databases/*.sql.gz; do
            if [ -f "$db_backup" ]; then
                db_name=$(basename "$db_backup" .sql.gz)
                mysql -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"
                gunzip -c "$db_backup" | mysql $db_name
                log_message "Database restored: $db_name"
            fi
        done
        
        # Restore files
        for file_backup in $BACKUP_SOURCE/files/*_files_*.tar.gz; do
            if [ -f "$file_backup" ]; then
                site_name=$(basename "$file_backup" | cut -d'_' -f1)
                mkdir -p "/var/www/$site_name"
                tar -xzf "$file_backup" -C "/var/www/$site_name"
                chown -R www-data:www-data "/var/www/$site_name"
                log_message "Files restored: $site_name"
            fi
        done
        
        # Restart services
        systemctl start mariadb redis-server php8.4-fpm nginx
        log_message "Services restarted"
        ;;
        
    "database-only")
        log_message "Performing database-only recovery"
        
        for db_backup in $BACKUP_SOURCE/databases/*.sql.gz; do
            if [ -f "$db_backup" ]; then
                db_name=$(basename "$db_backup" .sql.gz)
                read -p "Restore database $db_name? (y/N): " confirm
                if [ "$confirm" = "y" ]; then
                    mysql -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"
                    gunzip -c "$db_backup" | mysql $db_name
                    log_message "Database restored: $db_name"
                fi
            fi
        done
        ;;
        
    "files-only")
        log_message "Performing files-only recovery"
        
        for file_backup in $BACKUP_SOURCE/files/*_files_*.tar.gz; do
            if [ -f "$file_backup" ]; then
                site_name=$(basename "$file_backup" | cut -d'_' -f1)
                read -p "Restore files for site $site_name? (y/N): " confirm
                if [ "$confirm" = "y" ]; then
                    mkdir -p "/var/www/$site_name"
                    tar -xzf "$file_backup" -C "/var/www/$site_name"
                    chown -R www-data:www-data "/var/www/$site_name"
                    log_message "Files restored: $site_name"
                fi
            fi
        done
        ;;
        
    "config-only")
        log_message "Performing configuration-only recovery"
        
        if [ -f "$BACKUP_SOURCE/config_backup_latest.tar.gz" ]; then
            read -p "This will overwrite current configuration. Continue? (y/N): " confirm
            if [ "$confirm" = "y" ]; then
                systemctl stop nginx php8.4-fpm mariadb redis-server
                tar -xzf "$BACKUP_SOURCE/config_backup_latest.tar.gz" -C /
                systemctl start mariadb redis-server php8.4-fpm nginx
                log_message "Configuration restored and services restarted"
            fi
        fi
        ;;
        
    *)
        log_message "ERROR: Unknown recovery type: $RECOVERY_TYPE"
        exit 1
        ;;
esac

log_message "Disaster recovery completed: $RECOVERY_TYPE"
```

### **Recovery Testing Script**
Create `/usr/local/bin/recovery-test.sh`:

```bash
#!/bin/bash

TEST_ENV="/tmp/recovery-test"
BACKUP_DIR="/var/backups"
LOG_FILE="/var/log/seb-stack/recovery-test.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Starting recovery test"

# Create test environment
rm -rf $TEST_ENV
mkdir -p $TEST_ENV

# Test database backup integrity
log_message "Testing database backup integrity"
for db_backup in $BACKUP_DIR/databases/*.sql.gz; do
    if [ -f "$db_backup" ]; then
        if gunzip -t "$db_backup"; then
            log_message "✓ Database backup OK: $(basename $db_backup)"
        else
            log_message "✗ Database backup CORRUPTED: $(basename $db_backup)"
        fi
    fi
done

# Test file backup integrity
log_message "Testing file backup integrity"
for file_backup in $BACKUP_DIR/files/*.tar.gz; do
    if [ -f "$file_backup" ]; then
        if tar -tzf "$file_backup" > /dev/null 2>&1; then
            log_message "✓ File backup OK: $(basename $file_backup)"
        else
            log_message "✗ File backup CORRUPTED: $(basename $file_backup)"
        fi
    fi
done

# Test config backup integrity
log_message "Testing configuration backup integrity"
for config_backup in $BACKUP_DIR/config/*.tar.gz; do
    if [ -f "$config_backup" ]; then
        if tar -tzf "$config_backup" > /dev/null 2>&1; then
            log_message "✓ Config backup OK: $(basename $config_backup)"
        else
            log_message "✗ Config backup CORRUPTED: $(basename $config_backup)"
        fi
    fi
done

# Test remote backup connectivity
log_message "Testing remote backup connectivity"
if command -v aws &> /dev/null; then
    if aws s3 ls s3://your-backup-bucket > /dev/null 2>&1; then
        log_message "✓ S3 connectivity OK"
    else
        log_message "✗ S3 connectivity FAILED"
    fi
fi

if command -v gsutil &> /dev/null; then
    if gsutil ls gs://your-backup-bucket > /dev/null 2>&1; then
        log_message "✓ GCS connectivity OK"
    else
        log_message "✗ GCS connectivity FAILED"
    fi
fi

# Clean up
rm -rf $TEST_ENV

log_message "Recovery test completed"
```

## 📊 Backup Monitoring and Alerts

### **Backup Monitoring Script**
Create `/usr/local/bin/backup-monitor.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/var/backups"
ALERT_EMAIL="admin@example.com"
LOG_FILE="/var/log/seb-stack/backup-monitor.log"
MAX_AGE_HOURS=25  # Alert if latest backup is older than 25 hours

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

send_alert() {
    local subject=$1
    local message=$2
    echo "$message" | mail -s "$subject" $ALERT_EMAIL
    log_message "ALERT SENT: $subject"
}

log_message "Starting backup monitoring check"

# Check database backups
LATEST_DB_BACKUP=$(find $BACKUP_DIR/databases -name "*.sql.gz*" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
if [ -n "$LATEST_DB_BACKUP" ]; then
    DB_AGE_HOURS=$(echo "$(date +%s) - $(stat -c %Y "$LATEST_DB_BACKUP")" | bc | awk '{print int($1/3600)}')
    if [ $DB_AGE_HOURS -gt $MAX_AGE_HOURS ]; then
        send_alert "Database Backup Alert" "Latest database backup is $DB_AGE_HOURS hours old. File: $LATEST_DB_BACKUP"
    else
        log_message "Database backup OK: $DB_AGE_HOURS hours old"
    fi
else
    send_alert "Database Backup Alert" "No database backups found in $BACKUP_DIR/databases"
fi

# Check file backups
LATEST_FILE_BACKUP=$(find $BACKUP_DIR/files -name "*.tar.gz*" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
if [ -n "$LATEST_FILE_BACKUP" ]; then
    FILE_AGE_HOURS=$(echo "$(date +%s) - $(stat -c %Y "$LATEST_FILE_BACKUP")" | bc | awk '{print int($1/3600)}')
    if [ $FILE_AGE_HOURS -gt $MAX_AGE_HOURS ]; then
        send_alert "File Backup Alert" "Latest file backup is $FILE_AGE_HOURS hours old. File: $LATEST_FILE_BACKUP"
    else
        log_message "File backup OK: $FILE_AGE_HOURS hours old"
    fi
else
    send_alert "File Backup Alert" "No file backups found in $BACKUP_DIR/files"
fi

# Check backup disk usage
BACKUP_DISK_USAGE=$(df $BACKUP_DIR | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $BACKUP_DISK_USAGE -gt 85 ]; then
    send_alert "Backup Disk Space Alert" "Backup directory disk usage is ${BACKUP_DISK_USAGE}%. Please clean up old backups."
else
    log_message "Backup disk usage OK: ${BACKUP_DISK_USAGE}%"
fi

# Check remote backup sync status
if [ -f "/var/log/seb-stack/remote-sync.log" ]; then
    LAST_SYNC=$(grep "sync completed" /var/log/seb-stack/remote-sync.log | tail -1 | cut -d' ' -f1-2)
    if [ -n "$LAST_SYNC" ]; then
        SYNC_AGE_HOURS=$(echo "($(date +%s) - $(date -d "$LAST_SYNC" +%s)) / 3600" | bc)
        if [ $SYNC_AGE_HOURS -gt $MAX_AGE_HOURS ]; then
            send_alert "Remote Backup Sync Alert" "Last remote sync was $SYNC_AGE_HOURS hours ago."
        else
            log_message "Remote sync OK: $SYNC_AGE_HOURS hours ago"
        fi
    fi
fi

log_message "Backup monitoring check completed"
```

## ⚡ Automated Backup Scheduling

### **Complete Backup Cron Setup**
```bash
# Create master cron file for backups
sudo tee /etc/cron.d/seb-stack-backup << 'EOF'
# SEB Ultra Stack Backup Schedule
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Daily database backup at 2:00 AM
0 2 * * * root /usr/local/bin/database-backup.sh

# Daily file backup at 3:00 AM
0 3 * * * root /usr/local/bin/wordpress-backup.sh

# Configuration backup every Sunday at 1:00 AM
0 1 * * 0 root /usr/local/bin/config-backup---
layout: default
title: Backup & Recovery
description: Comprehensive backup and disaster recovery guide for SEB Ultra Stack
---

# 🔄 Backup & Recovery

Protect your SEB Ultra Stack with enterprise-grade backup strategies and disaster recovery procedures.

## 🛡️ Backup Strategy Overview

### **3-2-1 Backup Rule Implementation**
```
┌─────────────────────────────────────────┐
│  3 Copies of Critical Data              │
├─────────────────────────────────────────┤
│  ├─ Production Data (Live)              │ ← Original
│  ├─ Local Backup (On-site)              │ ← Copy 1
│  └─ Remote Backup (Off-site)            │ ← Copy 2
├─────────────────────────────────────────┤
│  2 Different Storage Media Types        │
├─────────────────────────────────────────┤
│  ├─ Local SSD/NVMe Storage              │
│  └─ Cloud Storage (S3/Google/Azure)     │
├─────────────────────────────────────────┤
│  1 Off-site Backup Location             │
├─────────────────────────────────────────┤
│  └─ Geographically Separated            │
└─────────────────────────────────────────┘
```

### **Backup Components**
- **Database Dumps** - WordPress/WooCommerce data
- **File System** - WordPress files, uploads, themes, plugins
- **Configuration Files** - Nginx, PHP, MariaDB, Redis configs
- **SSL Certificates** - Let's Encrypt and custom certificates
- **Log Files** - System and application logs
- **Cache Data** - Redis dumps (optional)

## ⚡ Quick Backup Setup

### **Enable Automated Backups**
```bash
# Initialize backup system
sudo seb-stack backup-init

# Enable daily automated backups
sudo seb-stack backup-schedule --daily --time="02:00" --retain=30

# Configure remote backup storage
sudo seb-stack backup-configure-remote --provider=s3 --bucket=my-backups --region=us-east-1

# Test backup system
sudo seb-stack backup-test --full
```

### **Manual Backup Commands**
```bash
# Full stack backup
sudo seb-stack backup --full --encrypt

# Site-specific backup
sudo seb-stack backup example.com

# Database-only backup
sudo seb-stack backup-db --all-sites

# Configuration backup
sudo seb-stack backup-config

# Files-only backup (no database)
sudo seb-stack backup-files example.com
```

## 🗄️ Database Backup Strategies

### **Automated Database Backups**
Create `/usr/local/bin/database-backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR

#!/bin/bash

BACKUP_DIR="/var/backups/databases"
S3_BUCKET="your-backup-bucket"
MYSQL_USER="backup_user"
MYSQL_PASS="secure_backup_password"
ENCRYPTION_KEY="your_encryption_key"
RETENTION_DAYS=30
LOG_FILE="/var/log/seb-stack/backup.log"

# Create backup directory
mkdir -p $BACKUP_DIR

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Database backup function
backup_database() {
    local db_name=$1
    local backup_file="$BACKUP_DIR/${db_name}_$(date +%Y%m%d_%H%M%S).sql"
    
    log_message "Starting backup of database: $db_name"
    
    # Create database dump with compression
    mysqldump --user=$MYSQL_USER --password=$MYSQL_PASS \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --hex-blob \
        --opt \
        $db_name | gzip > "${backup_file}.gz"
    
    if [ $? -eq 0 ]; then
        log_message "Database dump completed: ${backup_file}.gz"
        
        # Encrypt backup
        if [ ! -z "$ENCRYPTION_KEY" ]; then
            openssl enc -aes-256-cbc -salt -in "${backup_file}.gz" -out "${backup_file}.gz.enc" -k "$ENCRYPTION_KEY"
            rm "${backup_file}.gz"
            backup_file="${backup_file}.gz.enc"
            log_message "Backup encrypted: $backup_file"
        else
            backup_file="${backup_file}.gz"
        fi
        
        # Upload to S3
        if [ ! -z "$S3_BUCKET" ]; then
            aws s3 cp "$backup_file" "s3://$S3_BUCKET/databases/$(basename $backup_file)"
            if [ $? -eq 0 ]; then
                log_message "Backup uploaded to S3: s3://$S3_BUCKET/databases/$(basename $backup_file)"
            else
                log_message "ERROR: Failed to upload backup to S3"
            fi
        fi
        
    else
        log_message "ERROR: Database backup failed for $db_name"
        exit 1
    fi
}

# Get list of databases (excluding system databases)
DATABASES=$(mysql --user=$MYSQL_USER --password=$MYSQL_PASS -e "SHOW DATABASES;" | grep -Ev "^(Database|information_schema|performance_schema|mysql|sys)$")

# Backup each database
for db in $DATABASES; do
    backup_database $db
done

# WordPress multisite backup (if applicable)
if wp core is-installed --network 2>/dev/null; then
    log_message "WordPress multisite detected, creating network backup"
    
    # Get all site databases
    SITE_DATABASES=$(wp site list --field=url | while read site; do
        wp --url=$site config get DB_NAME
    done | sort -u)
    
    for site_db in $SITE_DATABASES; do
        backup_database $site_db
    done
fi

# Clean up old local backups
find $BACKUP_DIR -name "*.sql.gz*" -mtime +$RETENTION_DAYS -delete
log_message "Cleaned up backups older than $RETENTION_DAYS days"

# Backup verification
LATEST_BACKUP=$(ls -t $BACKUP_DIR/*.sql.gz* | head -1)
if [ -f "$LATEST_BACKUP" ]; then
    BACKUP_SIZE=$(du -h "$LATEST_BACKUP" | cut -f1)
    log_message "Latest backup size: $BACKUP_SIZE"
    
    # Test backup integrity
    if [[ "$LATEST_BACKUP" == *.enc ]]; then
        # Test encrypted backup
        openssl enc -aes-256-cbc -d -in "$LATEST_BACKUP" -k "$ENCRYPTION_KEY" | gunzip -t
    else
        # Test unencrypted backup
        gunzip -t "$LATEST_BACKUP"
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Backup integrity verified successfully"
    else
        log_message "ERROR: Backup integrity check failed"
        echo "CRITICAL: Backup integrity check failed for $LATEST_BACKUP" | mail -s "Backup Alert" admin@example.com
    fi
fi

log_message "Database backup process completed"
```

### **Advanced Database Backup Configuration**
Create `/etc/mysql/mariadb.conf.d/99-backup.cnf`:

```ini
[mysqldump]
# Backup optimization settings
single-transaction
routines
triggers
events
hex-blob
opt
compress
quick
lock-tables=false

# Binary log settings for point-in-time recovery
[mysqld]
log_bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7
sync_binlog = 1
innodb_flush_log_at_trx_commit = 1

# Backup user privileges
# CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'secure_password';
# GRANT SELECT, SHOW VIEW, RELOAD, REPLICATION CLIENT ON *.* TO 'backup_user'@'localhost';
# FLUSH PRIVILEGES;
```

### **Point-in-Time Recovery Setup**
```bash
# Enable binary logging for point-in-time recovery
sudo mysql -e "SET GLOBAL log_bin = 'mysql-bin';"
sudo mysql -e "SET GLOBAL binlog_format = 'ROW';"

# Create point-in-time recovery script
cat > /usr/local/bin/mysql-pit-recovery.sh << 'EOF'
#!/bin/bash

BACKUP_FILE=$1
RECOVERY_TIME=$2
MYSQL_USER="root"
MYSQL_PASS="root_password"
BINLOG_DIR="/var/log/mysql"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <backup_file> <recovery_time>"
    echo "Example: $0 /var/backups/db_backup.sql '2024-01-15 14:30:00'"
    exit 1
fi

echo "Starting point-in-time recovery to: $RECOVERY_TIME"

# Restore from backup
mysql --user=$MYSQL_USER --password=$MYSQL_PASS < $BACKUP_FILE

# Apply binary logs up to specified time
for binlog in $(ls $BINLOG_DIR/mysql-bin.*); do
    mysqlbinlog --stop-datetime="$RECOVERY_TIME" $binlog | mysql --user=$MYSQL_USER --password=$MYSQL_PASS
done

echo "Point-in-time recovery completed"
EOF

chmod +x /usr/local/bin/mysql-pit-recovery.sh
```

## 📁 File System Backup

### **WordPress Files Backup**
Create `/usr/local/bin/wordpress-backup.sh`:

```bash
#!/bin/bash

SITE_DIR="/var/www"
BACKUP_DIR="/var/backups/files"
S3_BUCKET="your-backup-bucket"
ENCRYPTION_KEY="your_encryption_key"
RETENTION_DAYS=14
LOG_FILE="/var/log/seb-stack/file-backup.log"

# Create backup directory
mkdir -p $BACKUP_DIR

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

backup_site_files() {
    local site_name=$1
    local site_path="$SITE_DIR/$site_name"
    local backup_file="$BACKUP_DIR/${site_name}_files_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    if [ ! -d "$site_path" ]; then
        log_message "ERROR: Site directory does not exist: $site_path"
        return 1
    fi
    
    log_message "Starting file backup for site: $site_name"
    
    # Create compressed archive excluding cache and temporary files
    tar -czf "$backup_file" \
        -C "$site_path" \
        --exclude="wp-content/cache/*" \
        --exclude="wp-content/uploads/cache/*" \
        --exclude="wp-content/w3tc-cache/*" \
        --exclude="wp-content/backup-db/*" \
        --exclude="wp-content/updraft/*" \
        --exclude="*.log" \
        --exclude=".htaccess.bak" \
        --exclude="error_log" \
        --exclude="debug.log" \
        .
    
    if [ $? -eq 0 ]; then
        log_message "File backup completed: $backup_file"
        
        # Get backup size
        BACKUP_SIZE=$(du -h "$backup_file" | cut -f1)
        log_message "Backup size: $BACKUP_SIZE"
        
        # Encrypt backup if key provided
        if [ ! -z "$ENCRYPTION_KEY" ]; then
            openssl enc -aes-256-cbc -salt -in "$backup_file" -out "${backup_file}.enc" -k "$ENCRYPTION_KEY"
            rm "$backup_file"
            backup_file="${backup_file}.enc"
            log_message "Backup encrypted: $backup_file"
        fi
        
        # Upload to S3
        if [ ! -z "$S3_BUCKET" ]; then
            aws s3 cp "$backup_file" "s3://$S3_BUCKET/files/$(basename $backup_file)"
            if [ $? -eq 0 ]; then
                log_message "File backup uploaded to S3"
            else
                log_message "ERROR: Failed to upload file backup to S3"
            fi
        fi
        
        # Verify backup integrity
        if [[ "$backup_file" == *.enc ]]; then
            openssl enc -aes-256-cbc -d -in "$backup_file" -k "$ENCRYPTION_KEY" | tar -tzf - > /dev/null 2>&1
        else
            tar -tzf "$backup_file" > /dev/null 2>&1
        fi
        
        if [ $? -eq 0 ]; then
            log_message "File backup integrity verified"
        else
            log_message "ERROR: File backup integrity check failed"
        fi
        
    else
        log_message "ERROR: File backup failed for $site_name"
        return 1
    fi
}

# Backup all WordPress sites
for site_dir in $SITE_DIR/*/; do
    if [ -f "$site_dir/wp-config.php" ]; then
        site_name=$(basename "$site_dir")
        backup_site_files "$site_name"
    fi
done

# Clean up old backups
find $BACKUP_DIR -name "*_files_*.tar.gz*" -mtime +$RETENTION_DAYS -delete
log_message "Cleaned up file backups older than $RETENTION_DAYS days"

log_message "File backup process completed"
```

### **Incremental Backup with rsync**
```bash
# Set up incremental backup system
cat > /usr/local/bin/incremental-backup.sh << 'EOF'
#!/bin/bash

SOURCE_DIR="/var/www"
BACKUP_BASE="/var/backups/incremental"
CURRENT_DATE=$(date +%Y%m%d_%H%M%S)
CURRENT_BACKUP="$BACKUP_BASE/backup_$CURRENT_DATE"
LATEST_LINK="$BACKUP_BASE/latest"
LOG_FILE="/var/log/seb-stack/incremental-backup.log"

mkdir -p "$BACKUP_BASE"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Create incremental backup using hard links
if [ -d "$LATEST_LINK" ]; then
    # Incremental backup
    rsync -avH --delete --link-dest="$LATEST_LINK" "$SOURCE_DIR/" "$CURRENT_BACKUP/"
    log_message "Incremental backup completed: $CURRENT_BACKUP"
else
    # First full backup
    rsync -av "$SOURCE_DIR/" "$CURRENT_BACKUP/"
    log_message "Full backup completed: $CURRENT_BACKUP"
fi

# Update latest link
rm -f "$LATEST_LINK"
ln -s "$CURRENT_BACKUP" "$LATEST_LINK"

# Keep only last 7 days of incremental backups
find "$BACKUP_BASE" -maxdepth 1 -type d -name "backup_*" -mtime +7 -exec rm -rf {} \;

log_message "Incremental backup process completed"
EOF

chmod +x /usr/local/bin/incremental-backup.sh
```

## ☁️ Remote Backup Configuration

### **Amazon S3 Backup Setup**
```bash
# Install AWS CLI
sudo apt install awscli

# Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format

# Create S3 backup bucket
aws s3 mb s3://your-backup-bucket --region us-east-1

# Set up bucket lifecycle policy
cat > /tmp/lifecycle.json << 'EOF'
{
    "Rules": [
        {
            "ID": "BackupRetention",
            "Status": "Enabled",
            "Filter": {"Prefix": ""},
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 90,
                    "StorageClass": "GLACIER"
                },
                {
                    "Days": 365,
                    "StorageClass": "DEEP_ARCHIVE"
                }
            ],
            "Expiration": {
                "Days": 2555
            }
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration --bucket your-backup-bucket --lifecycle-configuration file:///tmp/lifecycle.json
```

### **Google Cloud Storage Backup**
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Create backup bucket
gsutil mb gs://your-backup-bucket

# Set up lifecycle policy
cat > /tmp/lifecycle.json << 'EOF'
{
  "rule": [
    {
      "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
      "condition": {"age": 30}
    },
    {
      "action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
      "condition": {"age": 90}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"age": 2555}
    }
  ]
}
EOF

gsutil lifecycle set /tmp/lifecycle.json gs://your-backup-bucket
```

### **Automated Remote Sync**
Create `/usr/local/bin/remote-sync.sh`:

```bash
#!/bin/bash

LOCAL_BACKUP_DIR="/var/backups"
S3_BUCKET="s3://your-backup-bucket"
GCS_BUCKET="gs://your-backup-bucket"
LOG_FILE="/var/log/seb-stack/remote-sync.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Sync to S3
log_message "Starting S3 sync"
aws s3 sync $LOCAL_BACKUP_DIR $S3_BUCKET --delete --storage-class STANDARD_IA
if [ $? -eq 0 ]; then
    log_message "S3 sync completed successfully"
else
    log_message "ERROR: S3 sync failed"
fi

# Sync to Google Cloud Storage (optional secondary)
log_message "Starting GCS sync"
gsutil -m rsync -r -d $LOCAL_BACKUP_DIR $GCS_BUCKET
if [ $? -eq 0 ]; then
    log_message "GCS sync completed successfully"
else
    log_message "ERROR: GCS sync failed"
fi

log_message "Remote sync process completed"
```

## 🔧 Configuration Backup

### **System Configuration Backup**
Create `/usr/local/bin/config-backup.sh`:

```bash
#!/bin/bash

CONFIG_BACKUP_DIR="/var/backups/config"
BACKUP_FILE="$CONFIG_BACKUP_DIR/config_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
LOG_FILE="/var/log/seb-stack/config-backup.log"

mkdir -p $CONFIG_BACKUP_DIR

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Starting configuration backup"

# Create temporary directory for config files
TEMP_DIR=$(mktemp -d)
CONFIG_DIR="$TEMP_DIR/seb-stack-config"
mkdir -p $CONFIG_DIR

# Backup system configurations
cp -r /etc/nginx $CONFIG_DIR/
cp -r /etc/php $CONFIG_DIR/
cp -r /etc/mysql $CONFIG_DIR/
cp -r /etc/redis $CONFIG_DIR/
cp -r /etc/ssl $CONFIG_DIR/
cp -r /etc/letsencrypt $CONFIG_DIR/
cp -r /etc/fail2ban $CONFIG_DIR/
cp -r /etc/ufw $CONFIG_DIR/
cp -r /etc/seb-stack $CONFIG_DIR/ 2>/dev/null || true

# Backup important system files
mkdir -p $CONFIG_DIR/system
cp /etc/hosts $CONFIG_DIR/system/
cp /etc/hostname $CONFIG_DIR/system/
cp /etc/fstab $CONFIG_DIR/system/
cp /etc/crontab $CONFIG_DIR/system/
cp /etc/ssh/sshd_config $CONFIG_DIR/system/

# Backup user crontabs
mkdir -p $CONFIG_DIR/cron
for user in $(ls /var/spool/cron/crontabs/ 2>/dev/null); do
    cp /var/spool/cron/crontabs/$user $CONFIG_DIR/cron/
done

# Create archive
tar -czf $BACKUP_FILE -C $TEMP_DIR seb-stack-config

# Clean up
rm -rf $TEMP_DIR

if [ -f $BACKUP_FILE ]; then
    BACKUP_SIZE=$(du -h $BACKUP_FILE | cut -f1)
    log_message "Configuration backup completed: $BACKUP_FILE ($BACKUP_SIZE)"
    
    # Upload to remote storage
    if command -v aws &> /dev/null; then
        aws s3 cp $BACKUP_FILE s3://your-backup-bucket/config/
        log_message "Configuration backup uploaded to S3"
    fi
    
else
    log_message "ERROR: Configuration backup failed"
fi

# Keep only last 30 days of config backups
find $CONFIG_BACKUP_DIR -name "config_backup_*.tar.gz" -mtime +30 -delete

log_message "Configuration backup process completed"
```

## 🔄 Disaster Recovery Procedures

### **Complete System Recovery Script**
Create `/usr/local/bin/disaster-recovery.sh`:

```bash
#!/bin/bash

BACKUP_SOURCE=$1
RECOVERY_TYPE=$2
LOG_FILE="/var/log/seb-stack/recovery.log"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <backup_source> <recovery_type>"
    echo "Recovery types: full, database-only, files-only, config-only"
    exit 1
fi

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Starting disaster recovery: $RECOVERY_TYPE from $BACKUP_SOURCE"

case $RECOVERY_TYPE in
    "full")
        log_message "Performing full system recovery"
        
        # Stop services
        systemctl stop nginx php8.4-fpm mariadb redis-server
        
        # Restore configuration
        if [ -f "$BACKUP_SOURCE/config_backup_latest.tar.gz" ]; then
            tar -xzf "$BACKUP_SOURCE/config_backup_latest.tar.gz" -C /
            log_message "Configuration restored"
        fi
        
        # Restore databases
        for db_backup in $BACKUP_SOURCE/databases/*.sql.gz; do
            if [ -f "$db_backup" ]; then
                db_name=$(basename "$db_backup" .sql.gz)
                mysql -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"
                gunzip -c "$db_backup" | mysql $db_name
                log_message "Database restored: $db_name"
            fi
        done
        
        # Restore files
        for file_backup in $BACKUP_SOURCE/files/*_files_*.tar.gz; do
            if [ -f "$file_backup" ]; then
                site_name=$(basename "$file_backup" | cut -d'_' -f1)
                mkdir -p "/var/www/$site_name"
                tar -xzf "$file_backup" -C "/var/www/$site_name"
                chown -R www-data:www-data "/var/www/$site_name"
                log_message "Files restored: $site_name"
            fi
        done
        
        # Restart services
        systemctl start mariadb redis-server php8.4-fpm nginx
        log_message "Services restarted"
        ;;
        
    "database-only")
        log_message "Performing database-only recovery"
        
        for db_backup in $BACKUP_SOURCE/databases/*.sql.gz; do
            if [ -f "$db_backup" ]; then
                db_name=$(basename "$db_backup" .sql.gz)
                read -p "Restore database $db_name? (y/N): " confirm
                if [ "$confirm" = "y" ]; then
                    mysql -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"
                    gunzip -c "$db_backup" | mysql $db_name
                    log_message "Database restored: $db_name"
                fi
            fi
        done
        ;;
        
    "files-only")
        log_message "Performing files-only recovery"
        
        for file_backup in $BACKUP_SOURCE/files/*_files_*.tar.gz; do
            if [ -f "$file_backup" ]; then
                site_name=$(basename "$file_backup" | cut -d'_' -f1)
                read -p "Restore files for site $site_name? (y/N): " confirm
                if [ "$confirm" = "y" ]; then
                    mkdir -p "/var/www/$site_name"
                    tar -xzf "$file_backup" -C "/var/www/$site_name"
                    chown -R www-data:www-data "/var/www/$site_name"
                    log_message "Files restored: $site_name"
                fi
            fi
        done
        ;;
        
    "config-only")
        log_message "Performing configuration-only recovery"
        
        if [ -f "$BACKUP_SOURCE/config_backup_latest.tar.gz" ]; then
            read -p "This will overwrite current configuration. Continue? (y/N): " confirm
            if [ "$confirm" = "y" ]; then
                systemctl stop nginx php8.4-fpm mariadb redis-server
                tar -xzf "$BACKUP_SOURCE/config_backup_latest.tar.gz" -C /
                systemctl start mariadb redis-server php8.4-fpm nginx
                log_message "Configuration restored and services restarted"
            fi
        fi
        ;;
        
    *)
        log_message "ERROR: Unknown recovery type: $RECOVERY_TYPE"
        exit 1
        ;;
esac

log_message "Disaster recovery completed: $RECOVERY_TYPE"
```

### **Recovery Testing Script**
Create `/usr/local/bin/recovery-test.sh`:

```bash
#!/bin/bash

TEST_ENV="/tmp/recovery-test"
BACKUP_DIR="/var/backups"
LOG_FILE="/var/log/seb-stack/recovery-test.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Starting recovery test"

# Create test environment
rm -rf $TEST_ENV
mkdir -p $TEST_ENV

# Test database backup integrity
log_message "Testing database backup integrity"
for db_backup in $BACKUP_DIR/databases/*.sql.gz; do
    if [ -f "$db_backup" ]; then
        if gunzip -t "$db_backup"; then
            log_message "✓ Database backup OK: $(basename $db_backup)"
        else
            log_message "✗ Database backup CORRUPTED: $(basename $db_backup)"
        fi
    fi
done

# Test file backup integrity
log_message "Testing file backup integrity"
for file_backup in $BACKUP_DIR/files/*.tar.gz; do
    if [ -f "$file_backup" ]; then
        if tar -tzf "$file_backup" > /dev/null 2>&1; then
            log_message "✓ File backup OK: $(basename $file_backup)"
        else
            log_message "✗ File backup CORRUPTED: $(basename $file_backup)"
        fi
    fi
done

# Test config backup integrity
log_message "Testing configuration backup integrity"
for config_backup in $BACKUP_DIR/config/*.tar.gz; do
    if [ -f "$config_backup" ]; then
        if tar -tzf "$config_backup" > /dev/null 2>&1; then
            log_message "✓ Config backup OK: $(basename $config_backup)"
        else
            log_message "✗ Config backup CORRUPTED: $(basename $config_backup)"
        fi
    fi
done

# Test remote backup connectivity
log_message "Testing remote backup connectivity"
if command -v aws &> /dev/null; then
    if aws s3 ls s3://your-backup-bucket > /dev/null 2>&1; then
        log_message "✓ S3 connectivity OK"
    else
        log_message "✗ S3 connectivity FAILED"
    fi
fi

if command -v gsutil &> /dev/null; then
    if gsutil ls gs://your-backup-bucket > /dev/null 2>&1; then
        log_message "✓ GCS connectivity OK"
    else
        log_message "✗ GCS connectivity FAILED"
    fi
fi

# Clean up
rm -rf $TEST_ENV

log_message "Recovery test completed"
```

## 📊 Backup Monitoring and Alerts

### **Backup Monitoring Script**
Create `/usr/local/bin/backup-monitor.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/var/backups"
ALERT_EMAIL="admin@example.com"
LOG_FILE="/var/log/seb-stack/backup-monitor.log"
MAX_AGE_HOURS=25  # Alert if latest backup is older than 25 hours

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

send_alert() {
    local subject=$1
    local message=$2
    echo "$message" | mail -s "$subject" $ALERT_EMAIL
    log_message "ALERT SENT: $subject"
}

log_message "Starting backup monitoring check"

# Check database backups
LATEST_DB_BACKUP=$(find $BACKUP_DIR/databases -name "*.sql.gz*" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
if [ -n "$LATEST_DB_BACKUP" ]; then
    DB_AGE_HOURS=$(echo "$(date +%s) - $(stat -c %Y "$LATEST_DB_BACKUP")" | bc | awk '{print int($1/3600)}')
    if [ $DB_AGE_HOURS -gt $MAX_AGE_HOURS ]; then
        send_alert "Database Backup Alert" "Latest database backup is $DB_AGE_HOURS hours old. File: $LATEST_DB_BACKUP"
    else
        log_message "Database backup OK: $DB_AGE_HOURS hours old"
    fi
else
    send_alert "Database Backup Alert" "No database backups found in $BACKUP_DIR/databases"
fi

# Check file backups
LATEST_FILE_BACKUP=$(find $BACKUP_DIR/files -name "*.tar.gz*" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
if [ -n "$LATEST_FILE_BACKUP" ]; then
    FILE_AGE_HOURS=$(echo "$(date +%s) - $(stat -c %Y "$LATEST_FILE_BACKUP")" | bc | awk '{print int($1/3600)}')
    if [ $FILE_AGE_HOURS -gt $MAX_AGE_HOURS ]; then
        send_alert "File Backup Alert" "Latest file backup is $FILE_AGE_HOURS hours old. File: $LATEST_FILE_BACKUP"
    else
        log_message "File backup OK: $FILE_AGE_HOURS hours old"
    fi
else
    send_alert "File Backup Alert" "No file backups found in $BACKUP_DIR/files"
fi

# Check backup disk usage
BACKUP_DISK_USAGE=$(df $BACKUP_DIR | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $BACKUP_DISK_USAGE -gt 85 ]; then
    send_alert "Backup Disk Space Alert" "Backup directory disk usage is ${BACKUP_DISK_USAGE}%. Please clean up old backups."
else
    log_message "Backup disk usage OK: ${BACKUP_DISK_USAGE}%"
fi

# Check remote backup sync status
if [ -f "/var/log/seb-stack/remote-sync.log" ]; then
    LAST_SYNC=$(grep "sync completed" /var/log/seb-stack/remote-sync.log | tail -1 | cut -d' ' -f1-2)
    if [ -n "$LAST_SYNC" ]; then
        SYNC_AGE_HOURS=$(echo "($(date +%s) - $(date -d "$LAST_SYNC" +%s)) / 3600" | bc)
        if [ $SYNC_AGE_HOURS -gt $MAX_AGE_HOURS ]; then
            send_alert "Remote Backup Sync Alert" "Last remote sync was $SYNC_AGE_HOURS hours ago."
        else
            log_message "Remote sync OK: $SYNC_AGE_HOURS hours ago"
        fi
    fi
fi

log_message "Backup monitoring check completed"
```

## ⚡ Automated Backup Scheduling

### **Complete Backup Cron Setup**
```bash
# Create master cron file for backups
sudo tee /etc/cron.d/seb-stack-backup << 'EOF'
# SEB Ultra Stack Backup Schedule
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Daily database backup at 2:00 AM
0 2 * * * root /usr/local/bin/database-backup.sh

# Daily file backup at 3:00 AM
0 3 * * * root /usr/local/bin/wordpress-backup.sh

# Configuration backup every Sunday at 1:00 AM
0 1 * * 0 root /usr/local/bin/config-backup.sh

# Remote sync every 6 hours
0 */6 * * * root /usr/local/bin/remote-sync.sh

# Incremental backup every 4 hours
0 */4 * * * root /usr/local/bin/incremental-backup.sh

# Backup monitoring check every hour
0 * * * * root /usr/local/bin/backup-monitor.sh

# Recovery test weekly on Saturday at 4:00 AM
0 4 * * 6 root /usr/local/bin/recovery-test.sh

# Clean up old log files monthly
0 5 1 * * root find /var/log/seb-stack -name "*.log" -mtime +90 -delete
EOF
```

### **Backup Status Dashboard**
Create `/usr/local/bin/backup-status.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/var/backups"
REMOTE_BUCKET="s3://your-backup-bucket"

echo "========================================"
echo "    SEB ULTRA STACK BACKUP STATUS      "
echo "========================================"
echo "Generated: $(date)"
echo ""

# Local backup status
echo "LOCAL BACKUP STATUS:"
echo "----------------------------------------"

# Database backups
DB_COUNT=$(find $BACKUP_DIR/databases -name "*.sql.gz*" -type f 2>/dev/null | wc -l)
if [ $DB_COUNT -gt 0 ]; then
    LATEST_DB=$(find $BACKUP_DIR/databases -name "*.sql.gz*" -type f -exec stat -c '%Y %n' {} \; 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    DB_AGE=$(echo "($(date +%s) - $(stat -c %Y "$LATEST_DB" 2>/dev/null || echo 0)) / 3600" | bc 2>/dev/null || echo "N/A")
    DB_SIZE=$(du -sh $BACKUP_DIR/databases 2>/dev/null | cut -f1 || echo "N/A")
    echo "✓ Database Backups: $DB_COUNT files, Latest: ${DB_AGE}h ago, Size: $DB_SIZE"
else
    echo "✗ Database Backups: No backups found"
fi

# File backups
FILE_COUNT=$(find $BACKUP_DIR/files -name "*.tar.gz*" -type f 2>/dev/null | wc -l)
if [ $FILE_COUNT -gt 0 ]; then
    LATEST_FILE=$(find $BACKUP_DIR/files -name "*.tar.gz*" -type f -exec stat -c '%Y %n' {} \; 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    FILE_AGE=$(echo "($(date +%s) - $(stat -c %Y "$LATEST_FILE" 2>/dev/null || echo 0)) / 3600" | bc 2>/dev/null || echo "N/A")
    FILE_SIZE=$(du -sh $BACKUP_DIR/files 2>/dev/null | cut -f1 || echo "N/A")
    echo "✓ File Backups: $FILE_COUNT files, Latest: ${FILE_AGE}h ago, Size: $FILE_SIZE"
else
    echo "✗ File Backups: No backups found"
fi

# Configuration backups
CONFIG_COUNT=$(find $BACKUP_DIR/config -name "*.tar.gz*" -type f 2>/dev/null | wc -l)
if [ $CONFIG_COUNT -gt 0 ]; then
    LATEST_CONFIG=$(find $BACKUP_DIR/config -name "*.tar.gz*" -type f -exec stat -c '%Y %n' {} \; 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    CONFIG_AGE=$(echo "($(date +%s) - $(stat -c %Y "$LATEST_CONFIG" 2>/dev/null || echo 0)) / 3600" | bc 2>/dev/null || echo "N/A")
    CONFIG_SIZE=$(du -sh $BACKUP_DIR/config 2>/dev/null | cut -f1 || echo "N/A")
    echo "✓ Config Backups: $CONFIG_COUNT files, Latest: ${CONFIG_AGE}h ago, Size: $CONFIG_SIZE"
else
    echo "✗ Config Backups: No backups found"
fi

echo ""

# Disk usage
echo "STORAGE USAGE:"
echo "----------------------------------------"
TOTAL_BACKUP_SIZE=$(du -sh $BACKUP_DIR 2>/dev/null | cut -f1 || echo "N/A")
DISK_USAGE=$(df $BACKUP_DIR 2>/dev/null | tail -1 | awk '{print $5}' || echo "N/A")
DISK_FREE=$(df -h $BACKUP_DIR 2>/dev/null | tail -1 | awk '{print $4}' || echo "N/A")
echo "Total Backup Size: $TOTAL_BACKUP_SIZE"
echo "Disk Usage: $DISK_USAGE"
echo "Free Space: $DISK_FREE"

echo ""

# Remote backup status
echo "REMOTE BACKUP STATUS:"
echo "----------------------------------------"

if command -v aws &> /dev/null && aws s3 ls $REMOTE_BUCKET > /dev/null 2>&1; then
    REMOTE_SIZE=$(aws s3 ls $REMOTE_BUCKET --recursive --human-readable --summarize 2>/dev/null | grep "Total Size:" | awk '{print $3 " " $4}' || echo "N/A")
    REMOTE_COUNT=$(aws s3 ls $REMOTE_BUCKET --recursive 2>/dev/null | wc -l || echo "N/A")
    echo "✓ S3 Remote: $REMOTE_COUNT files, Total: $REMOTE_SIZE"
else
    echo "✗ S3 Remote: Not accessible or not configured"
fi

if command -v gsutil &> /dev/null && gsutil ls gs://your-backup-bucket > /dev/null 2>&1; then
    GCS_SIZE=$(gsutil du -sh gs://your-backup-bucket 2>/dev/null | awk '{print $1}' || echo "N/A")
    echo "✓ GCS Remote: Size: $GCS_SIZE"
else
    echo "✗ GCS Remote: Not accessible or not configured"
fi

echo ""

# Recent backup activity
echo "RECENT BACKUP ACTIVITY:"
echo "----------------------------------------"
if [ -f "/var/log/seb-stack/backup.log" ]; then
    echo "Last 5 backup events:"
    tail -5 /var/log/seb-stack/backup.log | while read line; do
        echo "  $line"
    done
else
    echo "No backup log found"
fi

echo ""

# Backup health check
echo "BACKUP HEALTH CHECK:"
echo "----------------------------------------"

HEALTH_SCORE=0
TOTAL_CHECKS=7

# Check 1: Recent database backup
if [ $DB_COUNT -gt 0 ] && [ "$DB_AGE" != "N/A" ] && [ $DB_AGE -lt 25 ]; then
    echo "✓ Database backup recent"
    HEALTH_SCORE=$((HEALTH_SCORE + 1))
else
    echo "✗ Database backup outdated or missing"
fi

# Check 2: Recent file backup
if [ $FILE_COUNT -gt 0 ] && [ "$FILE_AGE" != "N/A" ] && [ $FILE_AGE -lt 25 ]; then
    echo "✓ File backup recent"
    HEALTH_SCORE=$((HEALTH_SCORE + 1))
else
    echo "✗ File backup outdated or missing"
fi

# Check 3: Recent config backup
if [ $CONFIG_COUNT -gt 0 ] && [ "$CONFIG_AGE" != "N/A" ] && [ $CONFIG_AGE -lt 168 ]; then  # 1 week
    echo "✓ Config backup recent"
    HEALTH_SCORE=$((HEALTH_SCORE + 1))
else
    echo "✗ Config backup outdated or missing"
fi

# Check 4: Disk space available
if [ "$DISK_USAGE" != "N/A" ] && [ ${DISK_USAGE%\%} -lt 85 ]; then
    echo "✓ Sufficient disk space"
    HEALTH_SCORE=$((HEALTH_SCORE + 1))
else
    echo "✗ Low disk space"
fi

# Check 5: Remote backup accessible
if command -v aws &> /dev/null && aws s3 ls $REMOTE_BUCKET > /dev/null 2>&1; then
    echo "✓ Remote backup accessible"
    HEALTH_SCORE=$((HEALTH_SCORE + 1))
else
    echo "✗ Remote backup not accessible"
fi

# Check 6: Backup processes running
if pgrep -f "database-backup.sh\|wordpress-backup.sh\|remote-sync.sh" > /dev/null; then
    echo "✓ Backup processes active"
    HEALTH_SCORE=$((HEALTH_SCORE + 1))
else
    echo "✓ No backup processes currently running (normal)"
    HEALTH_SCORE=$((HEALTH_SCORE + 1))
fi

# Check 7: Cron jobs configured
if crontab -l | grep -q "backup"; then
    echo "✓ Backup cron jobs configured"
    HEALTH_SCORE=$((HEALTH_SCORE + 1))
else
    echo "✗ Backup cron jobs missing"
fi

HEALTH_PERCENTAGE=$(echo "scale=0; $HEALTH_SCORE * 100 / $TOTAL_CHECKS" | bc)
echo ""
echo "OVERALL BACKUP HEALTH: $HEALTH_SCORE/$TOTAL_CHECKS ($HEALTH_PERCENTAGE%)"

if [ $HEALTH_PERCENTAGE -ge 85 ]; then
    echo "Status: ✓ EXCELLENT"
elif [ $HEALTH_PERCENTAGE -ge 70 ]; then
    echo "Status: ⚠ GOOD (Some issues need attention)"
elif [ $HEALTH_PERCENTAGE -ge 50 ]; then
    echo "Status: ⚠ POOR (Multiple issues need immediate attention)"
else
    echo "Status: ✗ CRITICAL (Backup system needs immediate repair)"
fi

echo ""
echo "========================================"
```

## ✅ Backup & Recovery Best Practices

### **Security Best Practices**
- **Encrypt all backups** with strong encryption keys
- **Store encryption keys separately** from backup data
- **Use secure transfer protocols** (SFTP, HTTPS, SSL/TLS)
- **Implement access controls** for backup storage
- **Audit backup access** and maintain logs
- **Test backup restoration** regularly in isolated environment

### **Performance Optimization**
- **Schedule backups during low-traffic hours** (2-4 AM typically)
- **Use incremental backups** for large file systems
- **Implement compression** to reduce storage requirements
- **Parallel backup processes** for multiple sites
- **Monitor backup resource usage** and adjust accordingly

### **Retention Policies**
```bash
# Recommended retention schedule
Daily backups:    Keep for 7 days
Weekly backups:   Keep for 4 weeks  
Monthly backups:  Keep for 12 months
Yearly backups:   Keep for 7 years (compliance)

# Implement with find commands:
# Delete daily backups older than 7 days
find /var/backups -name "*daily*" -mtime +7 -delete

# Keep weekly backups for 4 weeks
find /var/backups -name "*weekly*" -mtime +28 -delete

# Keep monthly backups for 12 months
find /var/backups -name "*monthly*" -mtime +365 -delete
```

### **Testing and Validation**
- **Weekly automated backup integrity checks**
- **Monthly recovery testing** in staging environment
- **Quarterly full disaster recovery drills**
- **Annual backup strategy review** and updates
- **Document all recovery procedures** and update regularly

### **Monitoring and Alerting**
- **Real-time backup failure alerts**
- **Daily backup completion reports**
- **Weekly backup health summaries**
- **Monthly capacity planning reports**
- **Integration with monitoring systems** (Nagios, Zabbix, etc.)

## 🚨 Emergency Recovery Procedures

### **Critical System Failure Recovery**
```bash
# Emergency boot from rescue system
# 1. Boot from rescue disk/USB
# 2. Mount the damaged system

mkdir /mnt/recovery
mount /dev/sda1 /mnt/recovery

# 3. Restore critical configuration
cd /mnt/recovery
tar -xzf /path/to/config_backup.tar.gz

# 4. Restore essential services configuration
cp -r seb-stack-config/nginx/* /mnt/recovery/etc/nginx/
cp -r seb-stack-config/mysql/* /mnt/recovery/etc/mysql/

# 5. Chroot and restart services
chroot /mnt/recovery
systemctl start mysql nginx php8.4-fpm

# 6. Restore databases from backup
mysql < /path/to/database_backup.sql
```

### **Ransomware Recovery Protocol**
```bash
# 1. Immediate isolation
iptables -A INPUT -j DROP
iptables -A OUTPUT -j DROP
iptables -A FORWARD -j DROP

# 2. Assess damage
find / -name "*.encrypted" -o -name "*.locked" -o -name "*ransomware*" 2>/dev/null

# 3. Restore from clean backup (verified before ransomware date)
# Use offline backup or air-gapped storage
/usr/local/bin/disaster-recovery.sh /mnt/offline-backup full

# 4. Security scan after recovery
clamscan -r /var/www/
rkhunter --check
```

---

**Next:** Learn comprehensive [Troubleshooting](../troubleshooting/) techniques for diagnosing and resolving issues.---
layout: default
title: Backup & Recovery
description: Comprehensive backup and disaster recovery guide for SEB Ultra Stack
---

# 🔄 Backup & Recovery

Protect your SEB Ultra Stack with enterprise-grade backup strategies and disaster recovery procedures.

## 🛡️ Backup Strategy Overview

### **3-2-1 Backup Rule Implementation**
```
┌─────────────────────────────────────────┐
│  3 Copies of Critical Data              │
├─────────────────────────────────────────┤
│  ├─ Production Data (Live)              │ ← Original
│  ├─ Local Backup (On-site)              │ ← Copy 1
│  └─ Remote Backup (Off-site)            │ ← Copy 2
├─────────────────────────────────────────┤
│  2 Different Storage Media Types        │
├─────────────────────────────────────────┤
│  ├─ Local SSD/NVMe Storage              │
│  └─ Cloud Storage (S3/Google/Azure)     │
├─────────────────────────────────────────┤
│  1 Off-site Backup Location             │
├─────────────────────────────────────────┤
│  └─ Geographically Separated            │
└─────────────────────────────────────────┘
```

### **Backup Components**
- **Database Dumps** - WordPress/WooCommerce data
- **File System** - WordPress files, uploads, themes, plugins
- **Configuration Files** - Nginx, PHP, MariaDB, Redis configs
- **SSL Certificates** - Let's Encrypt and custom certificates
- **Log Files** - System and application logs
- **Cache Data** - Redis dumps (optional)

## ⚡ Quick Backup Setup

### **Enable Automated Backups**
```bash
# Initialize backup system
sudo seb-stack backup-init

# Enable daily automated backups
sudo seb-stack backup-schedule --daily --time="02:00" --retain=30

# Configure remote backup storage
sudo seb-stack backup-configure-remote --provider=s3 --bucket=my-backups --region=us-east-1

# Test backup system
sudo seb-stack backup-test --full
```

### **Manual Backup Commands**
```bash
# Full stack backup
sudo seb-stack backup --full --encrypt

# Site-specific backup
sudo seb-stack backup example.com

# Database-only backup
sudo seb-stack backup-db --all-sites

# Configuration backup
sudo seb-stack backup-config

# Files-only backup (no database)
sudo seb-stack backup-files example.com
```

## 🗄️ Database Backup Strategies

### **Automated Database Backups**
Create `/usr/local/bin/database-backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR
