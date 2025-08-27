
# 🔥 SEB Ultra Stack — v1.3.6

<p align="center">
  <img src="assets/banner-dark.png" alt="SEB Ultra Stack Banner" width="100%" />
</p>

<p align="center">
  <a href="https://github.com/sebhosting/seb-ultra-stack/actions"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/sebhosting/seb-ultra-stack/ci.yml?label=CI"></a>
  <img alt="PHP" src="https://img.shields.io/badge/PHP-8.3-777bb3?logo=php">
  <img alt="Nginx" src="https://img.shields.io/badge/Nginx-Production-009639?logo=nginx&logoColor=white">
  <img alt="Redis" src="https://img.shields.io/badge/Redis-Object%20Cache-dc382d?logo=redis&logoColor=white">
  <img alt="WordPress" src="https://img.shields.io/badge/WordPress-Multisite-21759b?logo=wordpress&logoColor=white">
  <img alt="WooCommerce" src="https://img.shields.io/badge/WooCommerce-Ready-96588a?logo=woocommerce&logoColor=white">
  <a href="https://sebhosting.github.io/seb-ultra-stack/"><img alt="Docs" src="https://img.shields.io/badge/Docs-Live-0ea5e9?logo=githubpages&logoColor=white"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/License-MIT-0891b2"></a>
  <a href="https://www.paypal.com/ncp/payment/Z5ZWDLX6BW9NQ"><img alt="Sponsor" src="https://img.shields.io/badge/Sponsor-PayPal-00457C?logo=paypal&logoColor=white"></a>
</p>

**Ultimate production WordPress Multisite + WooCommerce** for **Ubuntu 24.04 LTS** with **Redis**, **Nginx**, **PHP 8.3**, **MariaDB**, **Fail2Ban/UFW**, **Cloudflare DNS** + **Wildcard Let's Encrypt**, **auto dark docs**, **Conventional Commits autobump**, and **health monitoring starter (Prometheus + Grafana)**.

---

## 🚀 One-Command Install
```bash
chmod +x install-seb-stack.sh
sudo ./install-seb-stack.sh
```
- Prompts for domain, email, DB root, optional Cloudflare token, optional PayPal Client ID/Secret.
- Provisions full stack + WP Multisite (subdomains) + SSL.
- If PayPal creds are provided, they are saved in `.env`, mirrored into `wp-config.php`, and a **mu‑plugin** initializes WooCommerce PayPal settings.

---

## 🔁 Releases & Auto Version Bump
- **Conventional Commits** enforced locally via `commit-msg` hook.
- **release-please** workflow creates releases + changelog on merge to `main`.
- Tagging still works (`git tag vX.Y.Z && git push --tags`).

---

## 📊 Monitoring Starter
- `monitoring/docker-compose.yml` to spin up **Prometheus** + **Grafana** quickly.
- Optional; not installed by default.

---

## 🧰 What's Inside
- `install-seb-stack.sh` — full interactive provisioner
- `scripts/healthcheck.sh` — quick service status report
- `monitoring/` — Prometheus + Grafana docker-compose
- `.githooks/commit-msg` — Conventional Commits guard (enable via `git config core.hooksPath .githooks`)
- `.github/workflows/ci.yml` — linting (shell, md, yaml)
- `.github/workflows/deploy-pages.yml` — Jekyll dark docs to Pages
- `.github/workflows/release-please.yml` — automated releases
- `docs/` — dark Jekyll site
- `CHANGELOG.md`, `LICENSE`, `.gitignore`

See [docs → Install](/docs/install.md) for details.
