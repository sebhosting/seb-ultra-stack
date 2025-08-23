#!/usr/bin/env bash
set -euo pipefail

git init
git branch -M main
git remote add origin git@github.com:sebhosting/seb-ultra-stack.git

git add .
git commit -m "feat: initial import v1.0.4 with fancy README and workflows"

# push main
git push -u origin main --force

# tag v1.0.0 baseline
git tag v1.0.0 || true
git push origin v1.0.0 --force || true

# tag v1.0.1 update
git tag v1.0.1 || true
git push origin v1.0.1 --force || true

# tag v1.0.2 update
git tag v1.0.2 || true
git push origin v1.0.2 --force || true

# tag v1.0.3 update
git tag v1.0.3 || true
git push origin v1.0.3 --force || true

# tag v1.0.4 update
git tag v1.0.4 || true
git push origin v1.0.4 --force || true

echo "✅ Repo initialized and tags v1.0.0 → v1.0.4 pushed"
