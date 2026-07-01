# V-Fit AI Production Readiness Checklist

## 📋 Configuration Audit Results

Based on comprehensive code scan, the following issues were identified and fixed:

### ✅ Fixed Issues (Code Updated)

1. **Hardcoded Port 5000** 
   - ✅ FIXED: Now uses `PORT` environment variable
   - File: `api_server.py` (line 440+)

2. **Hardcoded Localhost URLs**
   - ✅ FIXED: `WEB2API_URL` now uses env var
   - File: `RecommendationSystem/gemini_client.py`

3. **Hardcoded Model Paths**
   - ✅ FIXED: All model paths now configurable via env vars
   - Files: `body_analyzer.py`, `body_shape.py`, `body_shape_predictor.py`

4. **Localhost Default for Gemini Proxy**
   - ✅ FIXED: Safe default with env var override
   - File: `RecommendationSystem/config.py` (already done)

5. **Missing Error Handling for Model Files**
   - ✅ FIXED: Added file existence checks
   - Files: `body_shape.py`, `body_shape_predictor.py`

6. **Non-root Container Execution**
   - ✅ FIXED: Dockerfile now creates non-root user
   - File: `Dockerfile`

7. **Unsafe CORS Configuration**
   - ✅ FIXED: CORS now restricted via env var
   - File: `api_server.py` (updated with config-based CORS)

8. **Logging Not Production-Ready**
   - ✅ FIXED: Added rotating file handler & logging config
   - File: `api_server.py` (logging setup refactored)

---

## 📁 New Files Created

| File | Purpose |
|------|---------|
| `settings.py` | Centralized configuration management (dev/staging/prod) |
| `.env.example` | Environment variables template |
| `docker-compose.yml` | Development Docker setup |
| `docker-compose.prod.yml` | Production Docker setup with DB, Redis, Nginx |
| `nginx.conf` | Production-grade reverse proxy config |
| `DEPLOYMENT.md` | Complete deployment guide |
| `PRODUCTION_CHECKLIST.md` | This file |

---

## 🚀 Pre-Production Setup Checklist

### 1. Configuration Management

- [ ] Copy `.env.example` to `.env.prod`
- [ ] Generate secure `SECRET_KEY`: `openssl rand -hex 32`
- [ ] Set `GEMINI_API_KEY` with valid API key
- [ ] Configure `CORS_ORIGINS` with your domain(s)
- [ ] Generate secure `DB_PASSWORD`: `openssl rand -base64 32`
- [ ] Update `DATABASE_URL` with production credentials
- [ ] Set `MODEL_PATH_*` to `/models/` (container paths)
- [ ] Set `ENVIRONMENT=production`
- [ ] Set `LOG_LEVEL=INFO` (or `WARNING` for production)

### 2. Model Files

- [ ] Verify all model files exist:
  - `bmi_finetuned_model.pth`
  - `best.pt`
  - `ai_rep_counter/models/phase_model.pt`
- [ ] Create `models/` directory and copy model files there
- [ ] Verify file permissions are readable
- [ ] Test model loading: `python -c "from settings import config; config.verify_models()"`

### 3. Dependencies

- [ ] Review `requirements.txt` for security vulnerabilities
  - Run: `pip-audit` or `safety check`
- [ ] Ensure all versions are pinned (no version ranges)
- [ ] Install production dependencies: `pip install -r requirements.txt gunicorn`
- [ ] Test imports: `python -c "from api_server import app"`

### 4. Docker Setup

- [ ] Install Docker & Docker Compose on server
- [ ] Verify Docker works: `docker --version && docker-compose --version`
- [ ] Build image: `docker build -t vfit-api:latest .`
- [ ] Test image: `docker run --rm vfit-api:latest python -c "from settings import config; print(config)"`

### 5. Database

- [ ] PostgreSQL version verified (15+)
- [ ] Database user created with strong password
- [ ] Database permissions set correctly
- [ ] Backup strategy configured
- [ ] Test connection: `psql -U vfit_user -d vfit_db -c "SELECT version();"`

### 6. SSL/TLS Certificates

- [ ] SSL certificates obtained (Let's Encrypt or commercial CA)
- [ ] Certificates stored in `ssl/` directory:
  - `ssl/cert.pem`
  - `ssl/key.pem`
- [ ] Certificate validity checked (not expired)
- [ ] Certificate renewal automated (certbot timer)

### 7. Nginx Configuration

- [ ] `nginx.conf` reviewed and customized
- [ ] Domain names configured correctly
- [ ] Rate limiting enabled
- [ ] Gzip compression enabled
- [ ] Security headers configured
- [ ] Test config: `nginx -t`

### 8. API Security

- [ ] CORS origins restricted to your domain(s)
- [ ] Rate limiting configured (10 req/s for API, 5 req/m for uploads)
- [ ] Request timeout configured (300 seconds)
- [ ] Max payload size set (16MB)
- [ ] Authentication implemented (if applicable)
- [ ] Input validation enabled

### 9. Server Security

- [ ] Firewall configured (allow 80, 443, 22 SSH)
- [ ] SSH key-based auth enabled
- [ ] Root login disabled
- [ ] Non-root Docker user in place
- [ ] Fail2ban or similar installed
- [ ] SELinux/AppArmor configured (if applicable)

### 10. Monitoring & Logging

- [ ] Logging directory created: `/app/logs/`
- [ ] Log rotation configured
- [ ] Log aggregation service setup (optional)
- [ ] Health check endpoint verified: `/health`
- [ ] Monitoring alerts configured
- [ ] Backup location confirmed

### 11. Deployment & Testing

- [ ] Docker Compose services start successfully
- [ ] All containers are healthy: `docker-compose -f docker-compose.prod.yml ps`
- [ ] API is accessible: `curl https://yourdomain.com/health`
- [ ] API endpoints respond correctly
- [ ] Database is accessible
- [ ] Redis is accessible
- [ ] Model loading works (check logs)
- [ ] File uploads work
- [ ] CORS headers correct

### 12. Domain & DNS

- [ ] Domain name purchased and configured
- [ ] DNS A record points to server IP
- [ ] DNS propagated (can take 24-48 hours)
- [ ] Test: `nslookup yourdomain.com`
- [ ] Test: `curl -I https://yourdomain.com`

### 13. Performance Tuning

- [ ] Gunicorn workers calculated: `2 * CPU_cores + 1` (usually 4-8)
- [ ] Python asyncio configured (if using async code)
- [ ] Database connection pooling enabled
- [ ] Redis cache enabled
- [ ] CDN configured (if serving static files)

### 14. Backup & Disaster Recovery

- [ ] Database backups automated (daily)
- [ ] Backup retention policy set (30 days)
- [ ] Backup storage tested (can restore from backup)
- [ ] Model file backups created
- [ ] Disaster recovery plan documented

### 15. APK & Mobile Configuration

- [ ] APK configured to use production API URL
- [ ] APK signed with production keystore
- [ ] APK tested on physical device
- [ ] API endpoint in APK points to `https://yourdomain.com/api`
- [ ] SSL certificate pinning considered (optional but recommended)

---

## 🧪 Post-Deployment Verification

After deployment, run these tests:

### Health Checks

```bash
# Check API health
curl -v https://yourdomain.com/health

# Check all services
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs --tail 50 vfit-api
```

### API Functionality Tests

```bash
# Test exercises endpoint
curl https://yourdomain.com/api/ai/exercises

# Test form check (with sample image)
curl -X POST https://yourdomain.com/api/ai/form-check \
  -F "image=@sample.jpg"

# Check CORS headers
curl -I -X OPTIONS https://yourdomain.com/api/ai/exercises \
  -H "Origin: https://yourdomain.com"
```

### Performance Tests

```bash
# Load test (example: 100 concurrent requests)
ab -n 1000 -c 100 https://yourdomain.com/health

# Or using wrk:
wrk -t4 -c100 -d30s https://yourdomain.com/health
```

### Security Tests

```bash
# SSL/TLS test
openssl s_client -connect yourdomain.com:443

# Security headers check
curl -I https://yourdomain.com | grep -i "security\|strict\|x-"

# Port scan (from external server)
nmap -p 80,443 yourdomain.com
```

---

## 📊 Environment Variables Summary

| Variable | Development | Production | Required |
|----------|-------------|-----------|----------|
| `ENVIRONMENT` | development | production | ✅ |
| `HOST` | localhost | 0.0.0.0 | ❌ |
| `PORT` | 5000 | 5000 | ❌ |
| `SECRET_KEY` | dev-secret | random-32-chars | ✅ |
| `GEMINI_API_KEY` | (test key) | valid-key | ✅ |
| `GEMINI_PROXY_URL` | http://localhost:8082 | http://gemini-proxy:8082 | ❌ |
| `WEB2API_URL` | http://localhost:8085 | http://web2api:8085 | ❌ |
| `CORS_ORIGINS` | * | yourdomain.com | ✅ |
| `DATABASE_URL` | sqlite:///app.db | postgresql://... | ✅ |
| `DB_USER` | (N/A) | vfit_user | ✅ |
| `DB_PASSWORD` | (N/A) | strong-password | ✅ |
| `LOG_LEVEL` | DEBUG | INFO/WARNING | ❌ |
| `MODEL_PATH_SHAPE` | bmi_finetuned_model.pth | /models/bmi_finetuned_model.pth | ✅ |
| `MODEL_PATH_BODY_DETECT` | best.pt | /models/best.pt | ✅ |
| `MODEL_PATH_REP_COUNTER` | ai_rep_counter/models/phase_model.pt | /models/phase_model.pt | ✅ |

---

## 🔒 Security Best Practices

1. **Environment Variables**
   - Never commit `.env.prod` to version control
   - Use `.gitignore` to exclude `.env*`
   - Rotate secrets regularly

2. **SSL/TLS**
   - Always use HTTPS in production
   - Use TLS 1.2+
   - Certificate expiration alerts

3. **Access Control**
   - Restrict admin access to specific IPs
   - Use SSH keys instead of passwords
   - Regular security audits

4. **Data Protection**
   - Enable database encryption
   - Regular backups with encryption
   - GDPR-compliant data retention

5. **API Security**
   - Rate limiting enabled
   - Input validation on all endpoints
   - SQL injection prevention (ORM usage)
   - CORS properly configured

---

## 📞 Support & Troubleshooting

See `DEPLOYMENT.md` for detailed troubleshooting guides.

For issues:
1. Check logs: `docker-compose -f docker-compose.prod.yml logs vfit-api`
2. Verify environment variables: `env | grep VFIT`
3. Test connectivity: `curl -v https://yourdomain.com/health`
4. Check Docker resources: `docker stats`

---

## ✨ Summary of Changes

### Code Updates Made:
- ✅ All hardcoded localhost URLs removed
- ✅ All hardcoded ports made configurable
- ✅ All hardcoded model paths made configurable
- ✅ Environment variable management centralized in `settings.py`
- ✅ Production logging setup (file + rotation)
- ✅ Dockerfile updated for production (non-root, gunicorn)
- ✅ CORS configuration made production-safe
- ✅ Database connection URL configurable
- ✅ Error handling for missing model files

### Configuration Files Created:
- ✅ `settings.py` - Unified configuration management
- ✅ `.env.example` - Environment template
- ✅ `docker-compose.yml` - Development setup
- ✅ `docker-compose.prod.yml` - Production stack (API, DB, Redis, Nginx)
- ✅ `nginx.conf` - Production-grade reverse proxy
- ✅ `DEPLOYMENT.md` - Complete deployment guide
- ✅ `PRODUCTION_CHECKLIST.md` - This checklist

---

**Ready to deploy!** Follow the checklist above, then refer to `DEPLOYMENT.md` for step-by-step instructions.
