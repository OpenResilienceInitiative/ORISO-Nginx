# ORISO-Nginx

## Overview
Nginx reverse proxy and API gateway for the ORISO platform. Routes all frontend requests to the appropriate backend services, handles CORS, and serves static content.

## 🎯 What is Nginx?
Nginx is a high-performance web server and reverse proxy. In ORISO, it:
- **Routes requests** from frontend to backend services
- **Handles CORS** (Cross-Origin Resource Sharing)
- **Manages authentication** headers
- **Proxies Keycloak** at `/auth/*`
- **Terminates SSL/TLS** (if configured)

## 📦 Current Deployment

### Running in Docker
**Container Name:** `nginx-restored`  
**Image:** `nginx:latest`  
**Network Mode:** Host (binds directly to host ports)  
**Port:** `8089` (main HTTP port)  
**Config Location:** `/etc/nginx/nginx.conf` (mounted from host)  
**Host Config Path:** `/home/caritas/Desktop/online-beratung/caritas-workspace/caritas-onlineBeratung-nginx/nginx-up.conf.backup`

### How to Access
- **Main URL:** http://91.99.219.182:8089
- **Keycloak:** http://91.99.219.182:8089/auth
- **API Services:** http://91.99.219.182:8089/service/*

## 🗺️ Route Map

### Keycloak
```
/auth/* → http://127.0.0.1:8080/*
```
Strips `/auth` prefix and forwards to Keycloak.

### Backend Services
```
/service/tenant/*           → TenantService (8081)
/service/users/*            → UserService (8082)
/service/consultingtypes/*  → ConsultingTypeService (8083)
/service/agencies           → AgencyService (8084)
/service/uploads/*          → UploadService (8085 via ClusterIP)
/service/matrix/*           → UserService MatrixController (8082)
/service/agencyadmin/*      → AgencyService Admin (8084)
/service/useradmin/*        → UserService Admin (8082)
/service/tenantadmin/*      → TenantService Admin (8081)
/service/topic/*            → ConsultingTypeService Topics (8083)
/service/conversations/*    → UserService Conversations (8082)
/service/settings           → ConsultingTypeService Settings (8083)
```

### Special Routes
```
/_matrix/media/*  → Matrix Synapse (30292) - Media uploads
/health/*         → Health Dashboard (30100)
/websocket        → LiveService WebSocket (8086)
```

### Mock Endpoints (For Missing Services)
```
/service/message/*      → Mock (200 OK)
/service/appointment/*  → Mock (200 OK)
/service/statistics/*   → Mock (200 OK)
/api/v1/*               → Mock RocketChat API
```

## ⚙️ Configuration

### Main Config File
**File:** `nginx.conf`  
**Lines:** 728  
**Size:** ~37KB

### Key Features
1. **CORS Handling:** Full CORS support with OPTIONS preflight
2. **Header Management:** Proper Host, X-Forwarded-*, and Origin headers
3. **Path Rewriting:** Strips `/service` prefix when needed
4. **File Uploads:** Supports up to 50MB for Matrix media
5. **WebSocket Support:** For LiveService real-time connections

### CORS Configuration
Every endpoint includes:
```nginx
if ($request_method = OPTIONS) {
    add_header 'Access-Control-Allow-Origin' $http_origin always;
    add_header 'Vary' 'Origin' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, PATCH, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, ...' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Access-Control-Max-Age' 86400 always;
    return 204;
}
add_header 'Access-Control-Allow-Origin' $http_origin always;
add_header 'Vary' 'Origin' always;
add_header 'Access-Control-Allow-Credentials' 'true' always;
```

## 🚀 Deployment

### Current Setup (Docker)

```bash
# Start nginx container (current setup)
docker run -d \
  --name nginx-restored \
  --network host \
  -v /home/caritas/Desktop/online-beratung/caritas-workspace/caritas-onlineBeratung-nginx/nginx-up.conf.backup:/etc/nginx/nginx.conf:ro \
  nginx:latest
```

### Restart Nginx
```bash
# Restart container
docker restart nginx-restored

# Or reload config without downtime
docker exec nginx-restored nginx -s reload
```

### Test Configuration
```bash
# Test config syntax
docker exec nginx-restored nginx -t

# Check nginx version
docker exec nginx-restored nginx -V
```

### View Logs
```bash
# Access logs
docker exec nginx-restored tail -f /var/log/nginx/access.log

# Error logs
docker exec nginx-restored tail -f /var/log/nginx/error.log
```

## 🔧 Management Commands

### Check Status
```bash
# Container status
docker ps | grep nginx

# Check what's listening on port 8089
ss -tlnp | grep 8089

# Test endpoint
curl http://91.99.219.182:8089/auth/realms/master
```

### Update Configuration

**Method 1: Using Mounted File (Current Setup)**
```bash
# Edit the config
cd /home/caritas/Desktop/online-beratung/caritas-workspace/caritas-onlineBeratung-nginx
vi nginx-up.conf.backup

# Test config
docker exec nginx-restored nginx -t

# Reload nginx
docker exec nginx-restored nginx -s reload
```

**Method 2: Replace Container**
```bash
# Stop old container
docker stop nginx-restored
docker rm nginx-restored

# Start new container with updated config
docker run -d \
  --name nginx-restored \
  --network host \
  -v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:latest
```

### Backup Configuration
```bash
# Backup current config
docker exec nginx-restored cat /etc/nginx/nginx.conf > nginx-backup-$(date +%Y%m%d).conf
```

## 🐛 Troubleshooting

### Nginx Won't Start

**Symptoms:**
```bash
docker logs nginx-restored
# Error: bind() to 0.0.0.0:8089 failed (98: Address already in use)
```

**Solution:**
```bash
# Find what's using port 8089
ss -tlnp | grep 8089
lsof -i :8089

# Kill the process or change nginx port
```

### 502 Bad Gateway

**Symptoms:** Frontend gets 502 errors

**Solution:**
```bash
# Check if backend service is running
curl http://127.0.0.1:8081/actuator/health  # TenantService
curl http://127.0.0.1:8082/actuator/health  # UserService
curl http://127.0.0.1:8083/actuator/health  # ConsultingTypeService
curl http://127.0.0.1:8084/actuator/health  # AgencyService

# Check nginx error logs
docker exec nginx-restored tail -50 /var/log/nginx/error.log
```

### CORS Errors

**Symptoms:** Browser console shows CORS errors

**Solution:**
```bash
# Check nginx config has CORS headers
docker exec nginx-restored cat /etc/nginx/nginx.conf | grep -A5 "Access-Control-Allow-Origin"

# Test OPTIONS request
curl -X OPTIONS -H "Origin: http://localhost:3001" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Authorization, Content-Type" \
  -v http://91.99.219.182:8089/service/users/
```

### 404 Not Found

**Symptoms:** API endpoint returns 404

**Solution:**
```bash
# Check nginx routing
docker exec nginx-restored cat /etc/nginx/nginx.conf | grep -A10 "location /service/users"

# Check access logs
docker exec nginx-restored tail -20 /var/log/nginx/access.log
```

## 📊 Monitoring

### Access Logs
```bash
# Real-time access log
docker exec nginx-restored tail -f /var/log/nginx/access.log

# Count requests by endpoint
docker exec nginx-restored cat /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -nr | head -20

# Count requests by status code
docker exec nginx-restored cat /var/log/nginx/access.log | awk '{print $9}' | sort | uniq -c | sort -nr
```

### Error Logs
```bash
# Real-time error log
docker exec nginx-restored tail -f /var/log/nginx/error.log

# Count errors by type
docker exec nginx-restored cat /var/log/nginx/error.log | grep -oP '\[error\] \d+#\d+: \*\d+ \K[^,]+' | sort | uniq -c | sort -nr
```

### Performance
```bash
# Check active connections
docker exec nginx-restored cat /var/run/nginx.pid | xargs ps -p

# Check worker processes
docker exec nginx-restored ps aux | grep nginx
```

## 🔐 Security

### Current Setup
- ✅ CORS properly configured
- ✅ Headers sanitized (proxy_hide_header)
- ✅ File upload limits (25MB-50MB)
- ⚠️ HTTP only (no HTTPS/TLS)
- ⚠️ No rate limiting configured

### Hardening for Production

#### 1. Enable HTTPS
```nginx
server {
    listen 443 ssl;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    # ... rest of config
}
```

#### 2. Add Rate Limiting
```nginx
http {
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    
    location /service/ {
        limit_req zone=api_limit burst=20 nodelay;
        # ... rest of location
    }
}
```

#### 3. Hide Server Version
```nginx
http {
    server_tokens off;
}
```

#### 4. Add Security Headers
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
```

## 📝 Configuration Files

### ORISO-Nginx Repository
```
ORISO-Nginx/
├── README.md                    ✅ This file
├── nginx.conf                   ✅ Current working config
├── nginx.conf.backup            ✅ Backup of working config
├── DEPLOYMENT.md                📄 Deployment guide (to be created)
└── docker-compose.yml           📄 Docker Compose (optional)
```

### Old Repository (Reference)
**Location:** `/home/caritas/Desktop/online-beratung/caritas-workspace/caritas-onlineBeratung-nginx/`

Contains:
- `nginx-up.conf.backup` - Currently used config (mounted in container)
- `nginx.conf` - Updated with current config
- `nginx.conf.backup` - Updated with current config
- Old test/broken configs (cleaned up)

## 🔗 Integration

### Frontend (ORISO-Frontend)
Frontend runs on port 3001 and makes requests to:
```
http://91.99.219.182:8089/service/*
http://91.99.219.182:8089/auth/*
```

Nginx handles CORS and routes to backend services.

### Backend Services
All services listen on localhost:
- TenantService: 8081
- UserService: 8082
- ConsultingTypeService: 8083
- AgencyService: 8084
- UploadService: ClusterIP (10.43.x.x:8085)

Nginx proxies external requests to these internal ports.

### Keycloak
Keycloak runs on localhost:8080 without `/auth` prefix.
Nginx adds `/auth` prefix for backwards compatibility with frontend URLs.

## 📈 Performance Tuning

### Current Settings
```nginx
worker_connections 1024;
keepalive_timeout 65;
sendfile on;
```

### For Production
```nginx
events {
    worker_connections 2048;
    use epoll;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;
}
```

## ✅ Status

**Current Status:** ✅ Running and working correctly

**Container:** `nginx-restored`  
**Uptime:** 2 days  
**Config:** Tested and validated  
**CORS:** Working  
**Routing:** All services accessible

## 🎯 Next Steps

1. ✅ Config files cleaned up
2. ✅ ORISO-Nginx repository created
3. ✅ Documentation written
4. ⏳ Create Kubernetes deployment (optional)
5. ⏳ Add HTTPS/TLS support (for production)
6. ⏳ Implement rate limiting (for production)
7. ⏳ Add monitoring/metrics (Prometheus)

---

**Maintained by:** ORISO Team  
**Last Updated:** October 31, 2025  
**Version:** 1.0.0  
**Status:** Production Ready ✅

