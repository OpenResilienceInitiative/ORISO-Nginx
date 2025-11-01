# ORISO-Nginx Deployment Guide

## 🚀 Quick Start (3 Steps)

### Step 1: Prepare
```bash
cd /path/to/ORISO-Nginx

# Make scripts executable
chmod +x *.sh
```

### Step 2: Start Nginx
```bash
./start-nginx.sh
```

### Step 3: Verify
```bash
# Check status
docker ps | grep oriso-nginx

# Test endpoint
curl http://91.99.219.182:8089/auth/realms/master
```

**Done!** Nginx is now running on port 8089.

---

## 📦 What's Included

```
ORISO-Nginx/
├── README.md                ✅ Complete documentation
├── STATUS.md                ✅ Current status
├── DEPLOYMENT.md            ✅ This file
├── nginx.conf               ✅ Main config
├── nginx.conf.backup        ✅ Backup config
├── docker-compose.yml       ✅ Docker Compose setup
├── start-nginx.sh           ✅ Start script
├── stop-nginx.sh            ✅ Stop script
├── reload-nginx.sh          ✅ Reload config (no downtime)
└── logs-nginx.sh            ✅ View logs
```

---

## 🛠️ Deployment Methods

### Method 1: Using Start Script (Recommended)

**Advantages:**
- Simple one-command startup
- Validates config before starting
- Handles existing containers
- Shows helpful status messages

**Commands:**
```bash
# Start nginx
./start-nginx.sh

# Stop nginx
./stop-nginx.sh

# Reload config (no downtime)
./reload-nginx.sh

# View logs
./logs-nginx.sh
```

### Method 2: Using Docker Compose

**Advantages:**
- Standard Docker Compose workflow
- Easy to add to larger stacks
- Automatic restarts
- Simple management

**Commands:**
```bash
# Start nginx
docker-compose up -d

# Stop nginx
docker-compose down

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Reload config
docker-compose exec nginx nginx -s reload
```

### Method 3: Manual Docker Run

**For advanced users who want full control:**

```bash
# Start nginx
docker run -d \
  --name oriso-nginx \
  --network host \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  --restart unless-stopped \
  nginx:latest

# Stop nginx
docker stop oriso-nginx
docker rm oriso-nginx

# Reload config
docker exec oriso-nginx nginx -s reload

# View logs
docker logs -f oriso-nginx
```

---

## 🔧 Configuration Updates

### Update Config Without Downtime

1. **Edit the config:**
```bash
cd /path/to/ORISO-Nginx
vi nginx.conf
```

2. **Reload nginx:**
```bash
./reload-nginx.sh
```

**OR with Docker Compose:**
```bash
docker-compose exec nginx nginx -t
docker-compose exec nginx nginx -s reload
```

The `reload-nginx.sh` script automatically:
- Tests config syntax
- Only reloads if valid
- No downtime (keeps existing connections)

### Update Config With Restart

If reload doesn't work (rare):

```bash
./stop-nginx.sh
./start-nginx.sh
```

**OR with Docker Compose:**
```bash
docker-compose restart
```

---

## 🌐 Network Configuration

### Current Setup: Host Network

**What it means:**
- Nginx binds directly to host ports
- No NAT or port mapping needed
- Best performance
- Nginx can access host services on localhost

**Port used:** 8089

**To check:**
```bash
ss -tlnp | grep 8089
```

### Alternative: Bridge Network (Not Recommended)

If you need isolated networking:

**Docker Compose:**
```yaml
services:
  nginx:
    image: nginx:latest
    container_name: oriso-nginx
    ports:
      - "8089:8089"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    restart: unless-stopped
```

**Note:** You'll need to update backend service IPs in nginx.conf.

---

## 🔍 Verification

### Check Container Status
```bash
# Is it running?
docker ps | grep oriso-nginx

# Container details
docker inspect oriso-nginx

# Resource usage
docker stats oriso-nginx
```

### Test Endpoints
```bash
# Keycloak
curl http://91.99.219.182:8089/auth/realms/master

# User service
curl http://91.99.219.182:8089/service/users/

# Health dashboard
curl http://91.99.219.182:8089/health/
```

### Check Logs
```bash
# Using script
./logs-nginx.sh

# Direct docker command
docker logs -f --tail=100 oriso-nginx

# Access log only
docker exec oriso-nginx tail -f /var/log/nginx/access.log

# Error log only
docker exec oriso-nginx tail -f /var/log/nginx/error.log
```

---

## 🐛 Troubleshooting

### Container Won't Start

**Problem:** Port 8089 already in use

**Solution:**
```bash
# Find what's using port 8089
ss -tlnp | grep 8089
lsof -i :8089

# Stop the conflicting service or change nginx port in nginx.conf
```

**Problem:** Config file not found

**Solution:**
```bash
# Ensure nginx.conf exists
ls -lah nginx.conf

# Check file permissions
chmod 644 nginx.conf
```

### Config Reload Fails

**Problem:** Syntax error in config

**Solution:**
```bash
# Test config manually
docker run --rm -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro nginx:latest nginx -t

# Check error message
# Fix the syntax error
# Try reload again
./reload-nginx.sh
```

### Backend Service Not Reachable

**Problem:** 502 Bad Gateway

**Solution:**
```bash
# Check if backend service is running
curl http://127.0.0.1:8081/actuator/health  # TenantService
curl http://127.0.0.1:8082/actuator/health  # UserService
curl http://127.0.0.1:8083/actuator/health  # ConsultingTypeService

# Start missing services
# Check nginx error log
docker exec oriso-nginx tail -50 /var/log/nginx/error.log
```

### CORS Errors

**Problem:** Browser shows CORS errors

**Solution:**
```bash
# Verify CORS headers in config
grep -A5 "Access-Control-Allow-Origin" nginx.conf

# Test OPTIONS request
curl -X OPTIONS -H "Origin: http://localhost:3001" \
  -H "Access-Control-Request-Method: POST" \
  -v http://91.99.219.182:8089/service/users/

# Should return 204 with CORS headers
```

---

## 📊 Monitoring

### Real-time Access Log
```bash
./logs-nginx.sh

# Or filter for specific endpoint
docker exec oriso-nginx tail -f /var/log/nginx/access.log | grep "/service/users"
```

### Error Log
```bash
docker exec oriso-nginx tail -f /var/log/nginx/error.log
```

### Request Statistics
```bash
# Top 10 requested URLs
docker exec oriso-nginx cat /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -nr | head -10

# Requests by status code
docker exec oriso-nginx cat /var/log/nginx/access.log | awk '{print $9}' | sort | uniq -c | sort -nr

# Top 10 client IPs
docker exec oriso-nginx cat /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -10
```

---

## 🔄 Migration from Old Setup

### If You Have `nginx-restored` Container

```bash
# Stop old container
docker stop nginx-restored
docker rm nginx-restored

# Start new ORISO nginx
cd /path/to/ORISO-Nginx
./start-nginx.sh
```

**Note:** Old container used config from:
```
/home/caritas/Desktop/online-beratung/caritas-workspace/caritas-onlineBeratung-nginx/nginx-up.conf.backup
```

New ORISO nginx uses:
```
/path/to/ORISO-Nginx/nginx.conf
```

(Same config, just cleaner location)

---

## 🚀 New Server Deployment

### Complete Setup on Fresh Server

1. **Copy ORISO-Nginx directory:**
```bash
scp -r ORISO-Nginx/ user@new-server:/opt/
```

2. **On new server:**
```bash
cd /opt/ORISO-Nginx

# Install Docker if not installed
curl -fsSL https://get.docker.com | sh

# Make scripts executable
chmod +x *.sh

# Update IP addresses in nginx.conf (if needed)
vi nginx.conf
# Replace 91.99.219.182 with your new server IP

# Start nginx
./start-nginx.sh

# Verify
curl http://YOUR_SERVER_IP:8089/
```

3. **Configure firewall:**
```bash
# Allow port 8089
sudo ufw allow 8089/tcp
```

---

## ✅ Production Checklist

Before deploying to production:

- [ ] Update IP addresses in nginx.conf
- [ ] Test all backend service connections
- [ ] Configure HTTPS/TLS (if needed)
- [ ] Set up log rotation
- [ ] Configure monitoring/alerts
- [ ] Test failover scenarios
- [ ] Document custom changes
- [ ] Create backup schedule
- [ ] Test reload procedure
- [ ] Verify all CORS origins
- [ ] Check firewall rules
- [ ] Test from client networks

---

## 📚 Additional Resources

- **Full Documentation:** See `README.md`
- **Current Status:** See `STATUS.md`
- **Route Map:** See `README.md` - Route Map section
- **Troubleshooting:** See `README.md` - Troubleshooting section

---

## 🎯 Summary

**Quick Commands:**
```bash
./start-nginx.sh      # Start nginx
./stop-nginx.sh       # Stop nginx
./reload-nginx.sh     # Reload config (no downtime)
./logs-nginx.sh       # View logs
```

**Docker Compose:**
```bash
docker-compose up -d          # Start
docker-compose down           # Stop
docker-compose logs -f        # Logs
docker-compose restart        # Restart
```

**Access:**
- **Main URL:** http://91.99.219.182:8089
- **Keycloak:** http://91.99.219.182:8089/auth
- **APIs:** http://91.99.219.182:8089/service/*

---

**Maintained by:** ORISO Team  
**Last Updated:** October 31, 2025  
**Status:** Production Ready ✅

