# 🎯 V-Fit AI - Production Setup Guide

> **Status:** ✅ Configuration Complete - Ready for Deployment  
> **Last Updated:** June 15, 2026

---

## 🚀 Quick Start (5 Minutes)

### For Local Development

```bash
# 1. Clone and setup
cd AI-VFIT/V-Fit
cp .env.example .env

# 2. Install dependencies
pip install -r requirements.txt

# 3. Run
python api_server.py

# ✅ Access: http://localhost:5000
```

### For Production Deployment

```bash
# 1. On your server, setup
git clone <repo>
cd AI-VFIT/V-Fit

# 2. Configure
cp .env.example .env.prod
nano .env.prod  # Fill in your values

# 3. Deploy
docker-compose -f docker-compose.prod.yml up -d

# ✅ Access: https://yourdomain.com
```

---

## 📦 What Was Done

### Phase 1: Code Analysis ✅
Scanned entire codebase and identified **15+ configuration issues**:
- Hardcoded ports, URLs, and file paths
- Unsafe Docker setup
- Missing environment variable support
- Non-production logging

### Phase 2: Configuration Migration ✅
Fixed all issues by:
- Creating centralized `settings.py` with environment detection
- Externalizing all hardcoded values
- Adding environment variable support throughout
- Creating production-grade Docker setup

### Phase 3: Documentation ✅
Created comprehensive guides:
- `DEPLOYMENT.md` - Step-by-step deployment instructions
- `PRODUCTION_CHECKLIST.md` - Pre-deployment verification
- `CONFIG_MIGRATION_GUIDE.md` - Understanding the changes
- `PRODUCTION_SUMMARY.md` - Complete overview
- `README_PRODUCTION_SETUP.md` - This guide

### Phase 4: Docker & Infrastructure ✅
Created production-ready setup:
- Updated `Dockerfile` with gunicorn + non-root user
- Created `docker-compose.prod.yml` with full stack
- Created `nginx.conf` for reverse proxy + SSL/TLS
- Added volume management for persistence

---

## 📋 Files Modified & Created

### 🆕 NEW FILES (8 Created)
```
✅ settings.py                     (NEW)
✅ .env.example                    (NEW)
✅ docker-compose.yml              (NEW)
✅ docker-compose.prod.yml         (NEW)
✅ nginx.conf                      (NEW)
✅ DEPLOYMENT.md                   (NEW)
✅ PRODUCTION_CHECKLIST.md         (NEW)
✅ CONFIG_MIGRATION_GUIDE.md       (NEW)
```

### ✏️ UPDATED FILES (7 Modified)
```
✏️  api_server.py                  (Updated)
✏️  Dockerfile                     (Updated)
✏️  requirements.txt               (Updated - pinned versions)
✏️  body_analyzer.py               (Updated)
✏️  body_shape.py                  (Updated)
✏️  body_shape_predictor.py        (Updated)
✏️  gemini_client.py               (Updated)
```

---

## 🔄 Configuration Flow

```
Your Application
        ↓
settings.py (loads environment)
        ↓
├─ ENVIRONMENT env var
├─ Config class (Dev/Staging/Prod)
├─ Loads from .env file
└─ Uses defaults as fallback

Result:
- Production is STRICT (requires all keys)
- Staging is MODERATE (similar to prod)
- Development is PERMISSIVE (debugging friendly)
```

---

## 🌍 Environment Variables (Essential)

### Required for Production
```bash
ENVIRONMENT=production
SECRET_KEY=<random-32-characters>
GEMINI_API_KEY=<your-api-key>
CORS_ORIGINS=https://yourdomain.com
DATABASE_URL=postgresql://user:pass@db:5432/vfit
MODEL_PATH_SHAPE=/models/bmi_finetuned_model.pth
MODEL_PATH_BODY_DETECT=/models/best.pt
MODEL_PATH_REP_COUNTER=/models/phase_model.pt
```

### Optional (with defaults)
```bash
HOST=0.0.0.0
PORT=5000
LOG_LEVEL=INFO
GEMINI_PROXY_URL=http://gemini-proxy:8082
WEB2API_URL=http://web2api:8085/v1/chat/completions
```

**See `.env.example` for all 20+ variables and their descriptions.**

---

## 🐳 Docker Architecture

### Development (docker-compose.yml)
```
Single Container
- V-Fit API (Flask dev server)
- No database (uses SQLite)
- No SSL
- Hot reload enabled
```

### Production (docker-compose.prod.yml)
```
Multi-Container Stack:
├─ vfit-api (Flask + Gunicorn, 4 workers)
├─ nginx (Reverse proxy, SSL/TLS)
├─ db (PostgreSQL)
├─ redis (Cache)
└─ gemini-proxy (AI model service)

Features:
- Auto-restart on failure
- Health checks
- Volume mounting (data persistence)
- Network isolation
- Resource limits
```

---

## 📊 Performance & Security

### Performance Tuned
- ✅ Gunicorn with 4 worker processes
- ✅ Nginx with gzip compression
- ✅ Redis caching layer
- ✅ Connection pooling
- ✅ Keepalive connections

### Security Hardened
- ✅ Non-root container user
- ✅ SSL/TLS encryption
- ✅ Rate limiting (10 req/s)
- ✅ Security headers (HSTS, CSP, etc.)
- ✅ CORS restricted to your domain
- ✅ Input validation
- ✅ No hardcoded secrets

---

## 🔐 Security Checklist

Before going to production, verify:

```bash
# 1. SECRET_KEY is set and random
echo $SECRET_KEY | wc -c  # Should be 32+ chars

# 2. CORS restricted
echo $CORS_ORIGINS  # Should be YOUR domain, not "*"

# 3. Database password is strong
echo $DB_PASSWORD | wc -c  # Should be 16+ chars

# 4. All required env vars are set
python -c "from settings import config; config.verify_models()"

# 5. Docker is using non-root user
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml exec vfit-api whoami  # Should be "vfit"

# 6. SSL certificates exist
ls -la ssl/cert.pem ssl/key.pem

# 7. Health check passes
curl -k https://localhost/health  # Should return 200

# 8. API responds without debug info
curl -I https://localhost/api/ai/exercises | grep -i "x-debug"  # Should be empty
```

---

## 🚦 Deployment Steps

### Step 1: Prepare Server (30 min)
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Install Docker Compose
curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Step 2: Setup Project (15 min)
```bash
# Clone repository
git clone <your-repo-url> /opt/vfit
cd /opt/vfit/AI-VFIT/V-Fit

# Copy and configure
cp .env.example .env.prod
nano .env.prod  # Edit ALL values

# Create directories
mkdir -p models ssl logs uploads
```

### Step 3: Setup SSL Certificates (10 min)
```bash
# Option A: Let's Encrypt (Recommended)
certbot certonly --standalone -d yourdomain.com
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/key.pem

# Option B: Self-signed (development only)
openssl req -x509 -newkey rsa:4096 -nodes \
  -out ssl/cert.pem -keyout ssl/key.pem -days 365
```

### Step 4: Prepare Models (5 min)
```bash
# Copy model files
cp bmi_finetuned_model.pth models/
cp best.pt models/
cp ai_rep_counter/models/phase_model.pt models/

# Verify
ls -la models/
```

### Step 5: Deploy Services (5 min)
```bash
# Load environment
export $(cat .env.prod | xargs)

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Wait for startup (usually 30 seconds)
sleep 30

# Verify health
docker-compose -f docker-compose.prod.yml ps
curl https://localhost/health  # Should return 200
```

### Step 6: Verify & Test (10 min)
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs --tail 50 vfit-api

# Test API
curl https://yourdomain.com/api/ai/exercises

# Test upload (if applicable)
curl -X POST https://yourdomain.com/api/upload -F "file=@test.jpg"

# Monitor resources
docker stats
```

---

## 🔍 Monitoring & Troubleshooting

### Common Issues & Solutions

#### Issue: Container keeps restarting
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs vfit-api

# Common causes:
# 1. Missing env var: export $(cat .env.prod | xargs)
# 2. Model file not found: verify models in /models/
# 3. Port already in use: change PORT in .env.prod
```

#### Issue: CORS errors
```bash
# Problem: Origin not allowed
# Solution: Update CORS_ORIGINS in .env.prod
CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

#### Issue: High memory usage
```bash
# Check resource usage
docker stats

# Solution: Reduce gunicorn workers (in docker-compose.prod.yml)
# Original: --workers 4
# Reduced: --workers 2
```

#### Issue: SSL certificate errors
```bash
# Check certificate validity
openssl x509 -in ssl/cert.pem -text -noout | grep -A2 "Validity"

# Renew if needed
certbot renew --dry-run
```

---

## 📈 Scaling Considerations

### Horizontal Scaling
To run multiple API instances:
```yaml
# docker-compose.prod.yml modification:
services:
  vfit-api-1:
    image: vfit-api:latest
    # ... config ...
  
  vfit-api-2:
    image: vfit-api:latest
    # ... same config ...
  
  nginx:
    upstream vfit_api {
      server vfit-api-1:5000;
      server vfit-api-2:5000;
    }
```

### Database Scaling
PostgreSQL can be:
- Upgraded to managed service (AWS RDS, Azure Database)
- Replicated (master-slave setup)
- Partitioned (for large datasets)

### Caching Scaling
Redis can be:
- Upgraded to cluster mode
- Replicated across regions
- Used with CDN for static content

---

## 📚 Documentation Reference

| Document | Purpose | Read When |
|----------|---------|-----------|
| **DEPLOYMENT.md** | Detailed deployment steps | Deploying to production |
| **PRODUCTION_CHECKLIST.md** | Pre-deployment verification | Before going live |
| **CONFIG_MIGRATION_GUIDE.md** | Understanding configuration | Learning about changes |
| **PRODUCTION_SUMMARY.md** | Executive overview | Getting context |
| **README_PRODUCTION_SETUP.md** | This file - quick guide | Starting deployment |

---

## ✨ What's Included

### Code Quality
- ✅ Configuration validation
- ✅ Error handling
- ✅ Logging (file + rotation)
- ✅ Security best practices

### Operations
- ✅ Health checks
- ✅ Container orchestration
- ✅ Service dependencies
- ✅ Auto-restart on failure

### Monitoring
- ✅ Log aggregation ready
- ✅ Health endpoint
- ✅ Resource monitoring
- ✅ Prometheus-ready metrics

### Documentation
- ✅ Setup guides
- ✅ Troubleshooting
- ✅ API documentation
- ✅ Configuration reference

---

## 🎓 Key Concepts

### Configuration Precedence
1. **Environment Variable** (highest priority)
2. **Config Class** (dev/staging/prod specific)
3. **Default Value** (fallback)

### Environment Types
- **Development** - Debug enabled, all origins allowed, permissive
- **Staging** - Debug disabled, restricted origins, production-like
- **Production** - Strict validation, required keys, maximum security

### Container Stateless Design
- API containers are stateless (can scale horizontally)
- State stored in PostgreSQL
- Cache stored in Redis
- Logs written to volume

---

## 🎯 Next Steps

### Immediate (This Week)
1. Read `PRODUCTION_CHECKLIST.md` 
2. Prepare server (Docker, Docker Compose)
3. Setup SSL certificates
4. Copy configuration template

### Short-term (This Month)
1. Deploy to staging environment
2. Run load tests
3. Verify all endpoints
4. Monitor for 1 week

### Long-term (Future)
1. Setup automated backups
2. Add monitoring/alerting
3. Implement CI/CD pipeline
4. Consider Kubernetes for scaling

---

## 🆘 Support Resources

### Error Codes
- `FileNotFoundError: Model file not found` → Models not in `/models/`
- `CORS error: Origin not allowed` → Update `CORS_ORIGINS`
- `Connection refused` → Database/Redis not running
- `SSL certificate verify failed` → SSL cert issues

### Commands Reference
```bash
# View logs
docker-compose -f docker-compose.prod.yml logs vfit-api

# Restart services
docker-compose -f docker-compose.prod.yml restart

# Stop all
docker-compose -f docker-compose.prod.yml down

# Check status
docker-compose -f docker-compose.prod.yml ps

# Execute command in container
docker-compose -f docker-compose.prod.yml exec vfit-api python -c "..."

# Clean up (removes stopped containers)
docker system prune
```

---

## 🎉 Success Criteria

After deployment, you should have:

- ✅ API accessible at `https://yourdomain.com`
- ✅ Health check responding: `https://yourdomain.com/health`
- ✅ All models loaded successfully
- ✅ Database connected and working
- ✅ Logs being generated and rotated
- ✅ SSL certificate valid and auto-renewing
- ✅ Rate limiting working (test with rapid requests)
- ✅ CORS properly configured
- ✅ No errors in logs for 24 hours
- ✅ APK/mobile app connecting successfully

---

## 📞 Quick Reference

### Essential Commands
```bash
# Start production environment
docker-compose -f docker-compose.prod.yml up -d

# Stop everything
docker-compose -f docker-compose.prod.yml down

# View real-time logs
docker-compose -f docker-compose.prod.yml logs -f

# Check service health
curl https://yourdomain.com/health

# Backup database
docker-compose -f docker-compose.prod.yml exec db pg_dump -U vfit_user vfit_db > backup.sql

# Restore database
docker-compose -f docker-compose.prod.yml exec -T db psql -U vfit_user vfit_db < backup.sql
```

---

## 🏆 Summary

Your V-Fit AI application is now:
- ✅ **Production-Ready** - Secure, scalable, well-documented
- ✅ **Configuration-Managed** - All settings externalized
- ✅ **Dockerized** - Consistent across environments
- ✅ **Monitored** - Health checks and logging
- ✅ **Secure** - SSL/TLS, rate limiting, CORS
- ✅ **Documented** - Complete guides included

**You are ready to deploy!** Follow DEPLOYMENT.md for step-by-step instructions.

---

**Ready? → Start with DEPLOYMENT.md**

Questions? Check PRODUCTION_CHECKLIST.md or CONFIG_MIGRATION_GUIDE.md
