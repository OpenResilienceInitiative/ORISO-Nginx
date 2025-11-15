#!/bin/bash
# ORISO-Nginx Docker Stop Script

echo "🛑 Stopping ORISO-Nginx..."

if docker ps --format '{{.Names}}' | grep -q '^oriso-nginx$'; then
    docker stop oriso-nginx
    echo "✅ ORISO-Nginx stopped"
else
    echo "⚠️  ORISO-Nginx container is not running"
fi

