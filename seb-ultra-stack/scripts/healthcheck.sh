#!/usr/bin/env bash
set -euo pipefail
echo "=== SEB Ultra Stack — Healthcheck ==="
for svc in nginx php8.3-fpm mariadb redis-server fail2ban ufw; do
  systemctl is-active --quiet "$svc" && echo "✔ $svc running" || echo "✖ $svc NOT running"
done
echo "UFW status:"
ufw status || true
echo "Nginx test:"
nginx -t || true
