# Changelog

## v1.0.5 — Ultimate Installer + Docker
- Interactive ANSI installer (`first-run.sh`) for Ubuntu 24.04
- PayPal Client ID/Secret support (no PEM certs)
- Cloudflare DNS-01 wildcard SSL (optional) + HTTP-01 fallback
- Pre-install (inactive): WooCommerce, Jetpack, FluentSMTP, Redis Object Cache, Really Simple SSL
- Harden server: Fail2Ban, ufw, TLS 1.2/1.3, security headers
- **Dockerized stack** with Nginx, PHP 8.3, MariaDB 11, Redis 7, Certbot
- Pro README with banner + badges; Docs + CI/CD + CodeQL + Dependabot
