#!/usr/bin/env bash
set -euo pipefail
if [ ! -f ~/.ssh/id_ed25519.pub ]; then
  ssh-keygen -t ed25519 -C "you@example.com" -N "" -f ~/.ssh/id_ed25519
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519 || true
  echo "Add this SSH key to GitHub, then press Enter:"
  cat ~/.ssh/id_ed25519.pub
  read _
fi
git init
git branch -M main
git remote add origin git@github.com:sebhosting/seb-ultra-stack.git || true
git add .
git commit -m "feat: initial ultimate v1.0.5 with installer + docker + ci/cd" || true
git push -u origin main || true
git tag v1.0.5 || true
git push origin v1.0.5 || true
