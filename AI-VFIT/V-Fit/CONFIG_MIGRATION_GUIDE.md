# Configuration Migration Guide - Local to Production

## Overview

Bạn đã successfully migrate từ local hardcoded configuration sang **production-ready enterprise configuration**. Dưới đây là guide để hiểu các thay đổi và cách sử dụng.

---

## 🎯 What Changed?

### Before (Local/Hardcoded) ❌
```python
# api_server.py
app.run(host="0.0.0.0", port=5000, debug=False, threaded=True)

# gemini_client.py
WEB2API_URL = "http://localhost:8085/v1/chat/completions"

# body_analyzer.py
self.shape_predictor = BodyShapePredictor(model_path="best.pt")
```

### After (Production-Ready) ✅
```python
# settings.py - centralized config
class Config:
    PORT = int(os.getenv("PORT", 5000))
    WEB2API_URL = os.getenv("WEB2API_URL", "http://localhost:8085/v1/chat/completions")
    MODEL_PATHS = {
        "body_detect": os.getenv("MODEL_PATH_BODY_DETECT", str(BASE_DIR / "best.pt")),
    }

# api_server.py - uses config
app.run(host=config.HOST, port=config.PORT, debug=config.DEBUG, threaded=True)

# body_analyzer.py - uses config
model_path = os.getenv("MODEL_PATH_BODY_DETECT", "best.pt")
self.shape_predictor = BodyShapePredictor(model_path=model_path)
```

---

## 📋 Quick Start

### 1️⃣ Development (Local Machine)

```bash
# Clone project
cd AI-VFIT/V-Fit

# Create .env file
cp .env.example .env

# Install dependencies
pip install -r requirements.txt

# Run locally
python api_server.py
# API running at: http://localhost:5000
```

### 2️⃣ Development with Docker

```bash
# Build and run development stack
docker-compose up -d vfit-dev

# Check logs
docker-compose logs -f vfit-dev

# API running at: http://localhost:5000
```

### 3️⃣ Production Deployment

```bash
# Setup server
ssh root@yourdomain.com

# Clone and setup
git clone <repo>
cd AI-VFIT/V-Fit

# Configure production
cp .env.example .env.prod
# Edit .env.prod with your values (see DEPLOYMENT.md)

# Start production stack
docker-compose -f docker-compose.prod.yml up -d

# Verify
curl https://yourdomain.com/health
```

---

## 🔧 Configuration Files Explained

### `settings.py` (NEW)
Centralized configuration management that supports **3 environments**:

```python
# Automatically detects environment from ENVIRONMENT variable
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

# 3 config classes:
class DevelopmentConfig(Config)    # Debug=True, all origins CORS
class StagingConfig(Config)        # Debug=False, restricted CORS
class ProductionConfig(Config)     # Strict security, required keys
```

**Usage in code:**
```python
from settings import config
print(config.PORT)           # 5000
print(config.DEBUG)          # False (in production)
print(config.CORS_ORIGINS)   # ["yourdomain.com"]
```

### `.env.example` (NEW)
Template showing all available environment variables:

```bash
ENVIRONMENT=development
SECRET_KEY=your-secret-here
GEMINI_API_KEY=your-api-key
CORS_ORIGINS=*
MODEL_PATH_SHAPE=bmi_finetuned_model.pth
...
```

**Create your own:**
```bash
cp .env.example .env           # Development
cp .env.example .env.prod      # Production
cp .env.example .env.staging   # Staging
```

### `docker-compose.yml` (NEW)
Development setup with local database:

```yaml
services:
  vfit-dev:
    build: .
    environment:
      - ENVIRONMENT=development
      - GEMINI_API_KEY=your-key
    volumes:
      - .:/app    # Hot reload
```

**Start:**
```bash
docker-compose up -d vfit-dev
```

### `docker-compose.prod.yml` (NEW)
Production stack with **multiple services**:

```yaml
services:
  vfit-api:        # Flask API with gunicorn (4 workers)
  db:              # PostgreSQL database
  redis:           # Cache layer
  gemini-proxy:    # AI model proxy
  nginx:           # Reverse proxy & SSL/TLS
```

**Features:**
- Automatic restart on failure
- Health checks
- Volume mounting for logs & uploads
- Network isolation
- Resource limits

**Start:**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### `nginx.conf` (NEW)
Production-grade reverse proxy configuration:

```nginx
upstream vfit_api {
    server vfit-api:5000;
}

server {
    listen 443 ssl http2;
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    
    location /api/ {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://vfit_api;
    }
}
```

**Features:**
- SSL/TLS termination
- Rate limiting
- Gzip compression
- Security headers
- Automatic HTTPS redirect

---

## 🌍 Environment Variables Reference

### Security Variables
| Variable | Dev | Prod | Purpose |
|----------|-----|------|---------|
| `ENVIRONMENT` | development | production | App behavior |
| `SECRET_KEY` | dev-secret | random-32-chars | Flask session security |
| `DEBUG` | true | false | Debug mode |

### API Configuration
| Variable | Dev | Prod | Purpose |
|----------|-----|------|---------|
| `HOST` | localhost | 0.0.0.0 | Server bind address |
| `PORT` | 5000 | 5000 | Server port |
| `CORS_ORIGINS` | * | yourdomain.com | Allowed origins |

### External Services
| Variable | Dev | Prod | Purpose |
|----------|-----|------|---------|
| `GEMINI_API_KEY` | (test) | valid-key | AI API key |
| `GEMINI_PROXY_URL` | http://localhost:8082 | http://gemini-proxy:8082 | Proxy URL |
| `WEB2API_URL` | http://localhost:8085 | http://web2api:8085 | Web API |

### Model Paths
| Variable | Dev | Prod | Purpose |
|----------|-----|------|---------|
| `MODEL_PATH_SHAPE` | bmi_finetuned_model.pth | /models/bmi_finetuned_model.pth | Body shape model |
| `MODEL_PATH_BODY_DETECT` | best.pt | /models/best.pt | Body detection model |
| `MODEL_PATH_REP_COUNTER` | ai_rep_counter/models/phase_model.pt | /models/phase_model.pt | Rep counter model |

### Database
| Variable | Dev | Prod | Purpose |
|----------|-----|------|---------|
| `DATABASE_URL` | sqlite:///app.db | postgresql://user:pass@db:5432/vfit | DB connection |
| `DB_USER` | (N/A) | vfit_user | DB user |
| `DB_PASSWORD` | (N/A) | strong-password | DB password |

### Logging
| Variable | Dev | Prod | Purpose |
|----------|-----|------|---------|
| `LOG_LEVEL` | DEBUG | INFO | Log verbosity |
| `LOG_FILE` | logs/app.log | /app/logs/api.log | Log file path |

---

## 📂 File Structure

```
AI-VFIT/V-Fit/
├── settings.py                    # ✨ NEW: Configuration management
├── .env.example                   # ✨ NEW: Environment template
├── .env                           # (create from .env.example for dev)
├── .env.prod                      # (create from .env.example for prod)
├── docker-compose.yml             # ✨ NEW: Development Docker setup
├── docker-compose.prod.yml        # ✨ NEW: Production Docker setup
├── nginx.conf                     # ✨ NEW: Production reverse proxy
│
├── api_server.py                  # UPDATED: Use config from settings
├── Dockerfile                     # UPDATED: Production-ready
│
├── body_analysis/
│   ├── body_analyzer.py          # UPDATED: Use config for model path
│   ├── body_shape.py             # UPDATED: Use config + error handling
│   └── body_shape_predictor.py   # UPDATED: Use config + validation
│
├── RecommendationSystem/
│   ├── gemini_client.py          # UPDATED: Use env vars
│   └── config.py                 # (already using env vars)
│
├── DEPLOYMENT.md                  # ✨ NEW: Deployment guide
├── PRODUCTION_CHECKLIST.md        # ✨ NEW: Pre-deploy checklist
├── CONFIG_MIGRATION_GUIDE.md      # ✨ NEW: This file
│
└── requirements.txt               # Python dependencies
```

---

## 🚀 Migration Steps

### Step 1: Update Code (Already Done ✅)
All hardcoded values have been replaced with environment variable support.

### Step 2: Setup Environment Files
```bash
# Development
cp .env.example .env
# Edit .env with your local values (optional, defaults work)

# Staging
cp .env.example .env.staging
nano .env.staging
# Set ENVIRONMENT=staging
# Set other staging-specific values

# Production
cp .env.example .env.prod
nano .env.prod
# Set all required production values (see PRODUCTION_CHECKLIST.md)
```

### Step 3: Test Locally
```bash
# Test with development settings
ENVIRONMENT=development python api_server.py

# Test with Docker
docker-compose up -d vfit-dev
curl http://localhost:5000/health
```

### Step 4: Deploy to Server
```bash
# On production server
docker-compose -f docker-compose.prod.yml up -d
curl https://yourdomain.com/health
```

---

## 🧪 Testing Different Environments

### Test Development
```bash
export ENVIRONMENT=development
python api_server.py
# Logs show: "Environment: development, Debug: True"
```

### Test Staging
```bash
export ENVIRONMENT=staging
export SECRET_KEY=$(openssl rand -hex 32)
export CORS_ORIGINS=https://staging.example.com
python api_server.py
# Logs show: "Environment: staging, Debug: False"
```

### Test Production
```bash
export ENVIRONMENT=production
export SECRET_KEY=$(openssl rand -hex 32)
export GEMINI_API_KEY=your-key
export CORS_ORIGINS=https://yourdomain.com
python api_server.py
# Logs show: "Environment: production, Debug: False"
# If any required env var is missing, it will raise an error
```

---

## ⚠️ Common Mistakes & Solutions

### ❌ Mistake: Using development settings in production
```bash
# WRONG - will expose debug info
ENVIRONMENT=development python api_server.py
```

### ✅ Solution:
```bash
# CORRECT
ENVIRONMENT=production python api_server.py
# This enforces security requirements
```

---

### ❌ Mistake: Model files not found
```
FileNotFoundError: Model file not found: /models/best.pt
```

### ✅ Solution:
```bash
# Create models directory
mkdir -p models
cp best.pt models/
cp bmi_finetuned_model.pth models/

# Set env var
export MODEL_PATH_BODY_DETECT=/models/best.pt
```

---

### ❌ Mistake: CORS errors in production
```
Access to XMLHttpRequest has been blocked by CORS policy
```

### ✅ Solution:
```bash
# Set CORS_ORIGINS to your domain
export CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

---

## 📊 Configuration Comparison

| Aspect | Before | After |
|--------|--------|-------|
| **Port** | Hardcoded 5000 | Configurable via `PORT` |
| **URLs** | Hardcoded localhost | Configurable via env vars |
| **Model Paths** | Relative paths | Configurable via env vars |
| **Database** | None | PostgreSQL support |
| **Caching** | None | Redis support |
| **Reverse Proxy** | None | Nginx with SSL/TLS |
| **Logging** | Console only | File + rotation |
| **CORS** | All origins | Configurable |
| **Security** | Not production-ready | Production-grade |
| **Container User** | root | Non-root (vfit:1000) |

---

## 🎓 Key Concepts

### Environment-Based Configuration
Your app now behaves differently based on `ENVIRONMENT` variable:

```python
# In settings.py
if ENVIRONMENT == "production":
    # Strict security, no defaults
    config = ProductionConfig()
elif ENVIRONMENT == "staging":
    # Similar to prod, but lenient on some things
    config = StagingConfig()
else:
    # Development: permissive, good for debugging
    config = DevelopmentConfig()
```

### Externalized Configuration
All runtime configuration is now external:

```python
# NOT in code ❌
SECRET_KEY = "hardcoded-secret"

# In environment ✅
SECRET_KEY = os.getenv("SECRET_KEY")
```

**Benefits:**
- Same code runs in dev/staging/prod
- Easy to rotate secrets
- Secure: no secrets in git
- Flexible: change without rebuilding

### Docker Volumes
Production uses volumes for persistence:

```yaml
volumes:
  vfit-db-data:      # Database storage
  vfit-redis-data:   # Cache storage
  vfit-logs:         # Application logs
  vfit-uploads:      # User uploads
  vfit-models:       # ML models
```

---

## 📞 Troubleshooting

### Check which config is loaded:
```python
python -c "from settings import config, ENVIRONMENT; print(f'Env: {ENVIRONMENT}, Config: {config}')"
```

### Check environment variables:
```bash
env | grep -E "ENVIRONMENT|SECRET_KEY|CORS|MODEL" | sort
```

### Validate configuration:
```python
from settings import config
config.verify_models()  # Check if model files exist
print(config.CORS_ORIGINS)
print(config.DATABASE_URL)
```

### Debug Docker services:
```bash
docker-compose -f docker-compose.prod.yml logs vfit-api
docker-compose -f docker-compose.prod.yml exec vfit-api env | grep ENVIRONMENT
```

---

## ✅ Verification Checklist

After migration:

- [ ] Code runs locally: `python api_server.py`
- [ ] Docker dev works: `docker-compose up vfit-dev`
- [ ] Config loads correctly: `python -c "from settings import config; print(config)"`
- [ ] Models are found: `python -c "from settings import config; config.verify_models()"`
- [ ] All endpoints accessible: `curl http://localhost:5000/health`
- [ ] Environment variables work: `ENVIRONMENT=production python api_server.py` (should fail without SECRET_KEY)

---

## 📖 Next Steps

1. **Read:** `DEPLOYMENT.md` for production deployment steps
2. **Check:** `PRODUCTION_CHECKLIST.md` before going live
3. **Configure:** Create `.env.prod` with your production values
4. **Test:** Run `docker-compose -f docker-compose.prod.yml up -d`
5. **Verify:** Check health endpoint and logs

---

**Configuration migration complete!** Your application is now enterprise-ready. 🎉
