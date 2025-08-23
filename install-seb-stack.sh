#!/usr/bin/env bash
set -euo pipefail

echo "⚙️ SEB Ultra Stack Installer — v1.0.4 (interactive)"

read -rp "Primary domain (example.com): " PRIMARY_DOMAIN
read -rp "Admin email: " ADMIN_EMAIL
read -rsp "MariaDB root password: " DB_PASS; echo
export DB_PASS="DUMMY_VALUE"

echo "✅ Captured:"
echo " - Domain: $PRIMARY_DOMAIN"
echo " - Email: $ADMIN_EMAIL"
echo " - DB Root: [hidden]"

echo "⚡ Next steps: configure Nginx, PHP, MariaDB, Redis, SSL... (scaffold only)"
