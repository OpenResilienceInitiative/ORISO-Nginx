#!/bin/bash
# ORISO-Nginx Docker Startup Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Starting ORISO-Nginx..."
echo "=================================================="
echo "📂 Config directory: $SCRIPT_DIR"
echo "📄 Config file: nginx.conf"
echo "🌐 Port: 8089"
echo "=================================================="

# Check if config exists
if [ ! -f "$SCRIPT_DIR/nginx.conf" ]; then
    echo "❌ Error: nginx.conf not found!"
    echo "Please ensure nginx.conf exists in $SCRIPT_DIR"
    exit 1
fi

# Test config syntax (if nginx is installed on host)
if command -v nginx &> /dev/null; then
    echo "🔍 Testing nginx config syntax..."
    docker run --rm -v "$SCRIPT_DIR/nginx.conf:/etc/nginx/nginx.conf:ro" nginx:latest nginx -t
    if [ $? -ne 0 ]; then
        echo "❌ Config test failed!"
        exit 1
    fi
    echo "✅ Config syntax is valid"
else
    echo "⚠️  nginx not installed on host, skipping syntax test"
fi

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q '^oriso-nginx$'; then
    echo "🛑 Stopping existing oriso-nginx container..."
    docker stop oriso-nginx
    docker rm oriso-nginx
fi

# Start new container
echo "🚀 Starting nginx container..."
docker run -d \
  --name oriso-nginx \
  --network host \
  -v "$SCRIPT_DIR/nginx.conf:/etc/nginx/nginx.conf:ro" \
  --restart unless-stopped \
  nginx:latest

# Check if container started successfully
sleep 2
if docker ps --format '{{.Names}}' | grep -q '^oriso-nginx$'; then
    echo ""
    echo "=================================================="
    echo "✅ ORISO-Nginx started successfully!"
    echo "=================================================="
    echo "📊 Container status:"
    docker ps | grep oriso-nginx
    echo ""
    echo "🔗 Access URLs:"
    echo "   Main:     http://91.99.219.182:8089"
    echo "   Keycloak: http://91.99.219.182:8089/auth"
    echo ""
    echo "📝 Useful commands:"
    echo "   Logs:     docker logs -f oriso-nginx"
    echo "   Reload:   docker exec oriso-nginx nginx -s reload"
    echo "   Stop:     docker stop oriso-nginx"
    echo "   Restart:  docker restart oriso-nginx"
    echo "=================================================="
else
    echo ""
    echo "❌ Failed to start nginx container!"
    echo "Check logs with: docker logs oriso-nginx"
    exit 1
fi

