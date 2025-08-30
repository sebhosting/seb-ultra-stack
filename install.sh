#!/bin/bash
# SEB Ultra Stack Installer
# Auto-download and run the setup from GitHub

set -e

echo "🚀 Starting SEB Ultra Stack Installation..."

# Clone the repo if not already present
if [ ! -d "/tmp/seb-ultra-stack" ]; then
    git clone https://github.com/sebhosting/seb-ultra-stack /tmp/seb-ultra-stack
else
    echo "Repo already cloned, pulling latest changes..."
    cd /tmp/seb-ultra-stack
    git pull origin main
fi

cd /tmp/seb-ultra-stack

# Run main setup script
if [ -f "./setup.sh" ]; then
    chmod +x ./setup.sh
    sudo ./setup.sh
else
    echo "❌ setup.sh not found!"
    exit 1
fi
