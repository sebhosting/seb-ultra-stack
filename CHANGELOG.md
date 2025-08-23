# Changelog

## v1.0.4 — Branding + Secret Scrub
- Added fancy README with banner, badges, and emoji sections
- Scrubbed secrets to avoid GitHub Secret Scanning false positives
- Added starter docs landing page
- Version bump to v1.0.4

## v1.0.3 — CI Fix + Security Hardening
- Fixed CI workflow with `azohra/shell-linter@v1`
- Added CodeQL workflow for security scanning
- Added Dependabot for GitHub Actions updates

## v1.0.2 — Pages + Release Workflow Fixes
- Fixed Release workflow with proper permissions
- Docs Deploy now auto-enables GitHub Pages and sets custom domain (docs.sebhosting.com)
- CI only fails on critical ShellCheck errors
- Added Release badge to README

## v1.0.1 — Workflow Reset + Installer Fix
- Fixed ShellCheck warning in `install-seb-stack.sh`
- Removed old workflows and replaced with clean CI, Docs Deploy, and Release
- Added Docs Deploy badge in README

## v1.0.0 — Initial Release
- First version with installer scaffold, docs, and workflows
