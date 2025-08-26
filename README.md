<p align="center">
  <img src="SEBUltraStack.png" alt="SEB Ultra Stack" width="100%" />
</p>

<h1 align="center">🔥 SEB Ultra Stack</h1>
<p align="center">
  WordPress Multisite (subdomains) + Nginx + Redis + Cloudflare + Let's Encrypt — production-ready and fast.
</p>
<p align="center">
  <a href="https://github.com/sebhosting/seb-ultra-stack/actions"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/sebhosting/seb-ultra-stack/ci.yml?label=CI"></a>
  <a href="https://github.com/sebhosting/seb-ultra-stack/releases"><img alt="Release" src="https://img.shields.io/github/v/release/sebhosting/seb-ultra-stack?display_name=tag"></a>
  <img alt="PHP" src="https://img.shields.io/badge/PHP-8.3-informational">
  <img alt="Nginx" src="https://img.shields.io/badge/Nginx-High%20Perf-success">
  <img alt="Redis" src="https://img.shields.io/badge/Redis-Object%20Cache-red">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-blue">
  <a href="https://www.paypal.com/ncp/payment/Z5ZWDLX6BW9NQ"><img alt="Sponsor" src="https://img.shields.io/badge/Sponsor-PayPal-00457C?logo=paypal"></a>
</p>

---

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/sebhosting/seb-ultra-stack/main/install.sh | bash
```

Or clone and run installer locally:

```bash
git clone git@github.com:sebhosting/seb-ultra-stack.git
cd seb-ultra-stack
chmod +x install.sh && ./install.sh
```

---

## Features

- WordPress Multisite (subdomains) with WooCommerce-ready config
- Nginx tuned for HTTP/2, Gzip (+ optional Brotli)
- Redis object cache
- Cloudflare optional + DNS-01 wildcard Let's Encrypt
- Hardened basics: optional UFW/fail2ban, secure headers
- CI (ShellCheck + Yamllint), Docs deploy, Release Drafter
- Dark docs at **https://docs.sebhosting.com** (GitHub Pages)

## Sponsor

If this helps you, consider sponsoring: **https://www.paypal.com/ncp/payment/Z5ZWDLX6BW9NQ**
