
<p align="center">
  <img src="docs/SEBUltraStack.png" alt="SEB Ultra Stack Banner" width="100%" />
</p>

<p align="center">
  <a href="https://www.php.net/"><img src="https://img.shields.io/badge/PHP-8.3-blue?logo=php&logoColor=white" /></a>
  <a href="https://nginx.org/"><img src="https://img.shields.io/badge/Nginx-Latest-green?logo=nginx&logoColor=white" /></a>
  <a href="https://redis.io/"><img src="https://img.shields.io/badge/Redis-Cache-red?logo=redis&logoColor=white" /></a>
  <a href="https://wordpress.org/"><img src="https://img.shields.io/badge/WordPress-Multisite-21759B?logo=wordpress&logoColor=white" /></a>
  <a href="https://woocommerce.com/"><img src="https://img.shields.io/badge/WooCommerce-Ready-96588A?logo=woocommerce&logoColor=white" /></a>
  <a href="https://docs.sebhosting.com"><img src="https://img.shields.io/badge/docs-live-blue?logo=github" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" /></a>
  <a href="https://github.com/sebhosting/seb-ultra-stack/releases"><img src="https://img.shields.io/github/v/release/sebhosting/seb-ultra-stack?label=Release&logo=github" /></a>
</p>

---

# ⚡ SEB Ultra Stack
🚀 The Ultimate WordPress Multisite + WooCommerce stack — Automated, Hardened, and Fast.

## ✨ Highlights
- One‑click interactive installer (prompts for domain/email/DB; optional Cloudflare + PayPal)
- WordPress Multisite (subdomains) + WooCommerce‑ready
- Nginx + PHP‑FPM + Redis + MariaDB
- Auto HTTPS via Let's Encrypt (HTTP‑01 or DNS‑01 with Cloudflare API)
- Production Docker Compose with `nginx-proxy` + `acme-companion`
- CI (lint), Release (auto tags), Docs (auto‑deploy to GitHub Pages)
- Security‑first defaults; secrets live in `.env` (see `.env.example`)

## 🚀 Quick Start
```bash
cp .env.example .env
./install.sh                # answer prompts; safe to re‑run
docker compose up -d
```

## 🧩 Recommended Plugins
WooCommerce • Jetpack • FluentSMTP • Wordfence • Redis Object Cache • UpdraftPlus • Really Simple SSL

## 📚 Docs
Full documentation auto‑published: https://docs.sebhosting.com

---

## 🛡 Security
No secrets in repo. Keep private values in `.env` only.

## 🤝 Contributing
See CONTRIBUTING.md — PRs welcome!

## 📄 License
MIT
