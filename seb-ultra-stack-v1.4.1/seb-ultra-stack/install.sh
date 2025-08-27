#!/bin/bash
echo '🔥 Installing SEB Ultra Stack...'
read -p 'Enter your domain: ' DOMAIN
read -p 'Enter your email: ' EMAIL
read -sp 'Enter DB root password: ' DB_ROOT
echo ''
echo "✅ Configured for $DOMAIN ($EMAIL)"
