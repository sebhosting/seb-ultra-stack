<p align="center">
  <img src="SEBUltraStack.svg" alt="SEB Ultra Stack" width="900"/>
</p>

<h1 align="center">🔥 SEB Ultra Stack — Ultimate Production Repo</h1>

<p align="center">
  <a href="https://github.com/sebhosting/seb-ultra-stack/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/sebhosting/seb-ultra-stack/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/sebhosting/seb-ultra-stack/actions/workflows/deploy.yml"><img alt="Docs Deploy" src="https://github.com/sebhosting/seb-ultra-stack/actions/workflows/deploy.yml/badge.svg"></a>
  <a href="https://github.com/sebhosting/seb-ultra-stack/releases"><img alt="Release" src="https://img.shields.io/github/v/release/sebhosting/seb-ultra-stack?sort=semver"></a>
  <img alt="PHP" src="https://img.shields.io/badge/PHP-8.3-777bb3?logo=php">
  <img alt="Nginx" src="https://img.shields.io/badge/Nginx-1.27-green?logo=nginx">
  <img alt="MariaDB" src="https://img.shields.io/badge/MariaDB-11-003545?logo=mariadb">
  <img alt="Redis" src="https://img.shields.io/badge/Redis-7-red?logo=redis">
  <img alt="WordPress" src="https://img.shields.io/badge/WordPress-Multisite-21759b?logo=wordpress">
  <img alt="WooCommerce" src="https://img.shields.io/badge/WooCommerce-Ready-96588a?logo=woocommerce">
  <a href="https://www.paypal.com/ncp/payment/Z5ZWDLX6BW9NQ"><img alt="Sponsor" src="https://img.shields.io/badge/Sponsor-PayPal-blue?logo=paypal&style=for-the-badge"></a>
</p>

> ⚡ <strong>High-performance WordPress Multisite (subdomains)</strong> for Ubuntu 24.04 LTS — Nginx + PHP 8.3 + MariaDB + Redis + Cloudflare/Let's Encrypt, hardened and automated.  
> Use <strong>Bare-Metal</strong> installer or <strong>Docker</strong> — your choice.

---

## 🚀 One-Click Install (Bare-Metal)
```bash
chmod +x first-run.sh
./first-run.sh
```
- Prompts for <strong>domain, email, DB</strong>, optional <strong>Cloudflare</strong> (wildcard SSL) & <strong>PayPal API</strong> (client id/secret).  
- Installs WordPress, converts to Multisite (subdomains), pre-installs: WooCommerce, Jetpack, FluentSMTP, Redis Object Cache, Really Simple SSL.

## 🐳 Docker (Included)
```bash
cp .env.example .env
# edit .env
docker compose up -d --build
make wp
# (optional HTTP-01 cert) 
make ssl-http DOMAIN=example.com EMAIL=admin@example.com
```

## 🛡️ Security
- TLS 1.2/1.3, HSTS, strict headers
- Fail2Ban + UFW (bare-metal)
- Redis socket/password, `DISALLOW_FILE_EDIT`
- Secrets in `.env`, salts auto-generated

## 📚 Docs
- Auto-deployed to **https://docs.sebhosting.com** via GitHub Pages (workflow included).

## 🧩 CI/CD
- **CI**: ShellCheck
- **Release**: semantic-release → GitHub Release + CHANGELOG
- **Docs**: Actions → Pages + CNAME

## 🤝 Sponsor
Keep it blazing fast → <a href="https://www.paypal.com/ncp/payment/Z5ZWDLX6BW9NQ">PayPal</a>.
