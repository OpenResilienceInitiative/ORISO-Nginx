#!/bin/bash
# ORISO-Nginx Config Reload Script (no downtime)

echo "🔄 Reloading ORISO-Nginx configuration..."

if docker ps --format '{{.Names}}' | grep -q '^oriso-nginx$'; then
    # Test config first
    echo "🔍 Testing configuration..."
    docker exec oriso-nginx nginx -t
    
    if [ $? -eq 0 ]; then
        echo "✅ Config is valid, reloading..."
        docker exec oriso-nginx nginx -s reload
        echo "✅ ORISO-Nginx configuration reloaded successfully!"
        echo "   No downtime occurred."
    else
        echo "❌ Config test failed! Not reloading."
        exit 1
    fi
else
    echo "❌ ORISO-Nginx container is not running"
    echo "   Start it with: ./start-nginx.sh"
    exit 1
fi

