#!/bin/bash
# ORISO-Nginx Logs Viewer Script

echo "📝 ORISO-Nginx Logs"
echo "=================================================="
echo "Press Ctrl+C to exit"
echo "=================================================="

if docker ps --format '{{.Names}}' | grep -q '^oriso-nginx$'; then
    docker logs -f --tail=50 oriso-nginx
else
    echo "❌ ORISO-Nginx container is not running"
    exit 1
fi

