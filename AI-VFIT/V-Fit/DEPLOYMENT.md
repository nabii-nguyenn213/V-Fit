# V-Fit AI - Production Deployment Guide

## Quick Start

### Development Setup

```bash
# Clone repository
git clone <your-repo-url>
cd AI-VFIT/V-Fit

# Create .env from template
cp .env.example .env

# Development mode (local)
python -m pip install -r requirements.txt
python api_server.py

# Or using Docker
docker-compose up -d vfit-dev
```

### Production Setup

```bash
# 1. Configure environment
cp .env.example .env.prod
nano .env.prod  # Edit with your production values

# 2. Set production environment
export ENVIRONMENT=production
export $(cat .env.prod | xargs)

# 3. Build and start services
docker-compose -f docker-compose.prod.yml up -d

# 4. Verify services are healthy
docker-compose -f docker-compose.prod.yml ps
curl https://yourdomain.com/health
```

---

## Environment Variables Configuration

### Required for Production

```bash
# Security
ENVIRONMENT=production
SECRET_KEY=your-very-secure-random-string-here  # Generate: openssl rand -hex 32

# API Keys
GEMINI_API_KEY=your-gemini-api-key-here

# CORS - Restrict to your domain(s)
CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# Database
DB_USER=vfit_user
DB_PASSWORD=your-secure-db-password  # Generate: openssl rand -base64 32
DATABASE_URL=postgresql://vfit_user:password@db:5432/vfit_db

# Model Paths (inside container: /models/)
MODEL_PATH_SHAPE=/models/bmi_finetuned_model.pth
MODEL_PATH_BODY_DETECT=/models/best.pt
MODEL_PATH_REP_COUNTER=/models/phase_model.pt
```

### Optional

```bash
# Server
HOST=0.0.0.0
PORT=5000

# Services
GEMINI_PROXY_URL=http://gemini-proxy:8082
WEB2API_URL=http://web2api:8085/v1/chat/completions

# Logging
LOG_LEVEL=INFO
LOG_FILE=/app/logs/api.log

# File Uploads
UPLOAD_FOLDER=/app/uploads
MAX_UPLOAD_SIZE=10485760  # 10MB

# Requests
MAX_CONTENT_LENGTH=16777216  # 16MB
REQUEST_TIMEOUT=300  # 5 minutes
```

---

## Deployment Steps

### 1. Prepare Server

```bash
# Install Docker & Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Configure SSL Certificates

#### Option A: Let's Encrypt (Recommended)

```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Generate certificate
sudo certbot certonly --standalone -d yourdomain.com -d app.yourdomain.com

# Copy to project
mkdir -p ssl
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/key.pem
sudo chown $USER:$USER ssl/*
```

#### Option B: Self-signed Certificate (Development only)

```bash
openssl req -x509 -newkey rsa:4096 -nodes \
    -out ssl/cert.pem -keyout ssl/key.pem -days 365
```

### 3. Setup Environment

```bash
# Create production environment file
cat > .env.prod << EOF
ENVIRONMENT=production
SECRET_KEY=$(openssl rand -hex 32)
GEMINI_API_KEY=your-api-key-here
CORS_ORIGINS=https://yourdomain.com
DB_PASSWORD=$(openssl rand -base64 32)
DATABASE_URL=postgresql://vfit_user:${DB_PASSWORD}@db:5432/vfit_db
MODEL_PATH_SHAPE=/models/bmi_finetuned_model.pth
MODEL_PATH_BODY_DETECT=/models/best.pt
MODEL_PATH_REP_COUNTER=/models/phase_model.pt
EOF

chmod 600 .env.prod
```

### 4. Prepare Model Files

```bash
# Create models directory
mkdir -p models

# Copy model files to models directory
cp bmi_finetuned_model.pth models/
cp best.pt models/
cp ai_rep_counter/models/phase_model.pt models/

# Create Docker volume for models
docker volume create vfit-models

# Copy models into volume (this will be mounted to /models in container)
docker run --rm -v vfit-models:/models -v $(pwd)/models:/src alpine cp -r /src/* /models/
```

### 5. Deploy Services

```bash
# Load environment variables
export $(cat .env.prod | xargs)

# Start production stack
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to be healthy
sleep 30
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f vfit-api
```

### 6. Verify Deployment

```bash
# Health check
curl https://yourdomain.com/health

# API test
curl -X GET https://yourdomain.com/api/ai/exercises

# Database connection
docker-compose -f docker-compose.prod.yml exec db psql -U vfit_user -d vfit_db -c "SELECT version();"

# View logs
docker-compose -f docker-compose.prod.yml logs --tail 100 vfit-api
```

---

## Maintenance

### Database Backups

```bash
# Manual backup
docker-compose -f docker-compose.prod.yml exec db pg_dump -U vfit_user vfit_db > backup-$(date +%Y%m%d).sql

# Automated backup (cron job)
0 2 * * * docker-compose -f /path/to/docker-compose.prod.yml exec -T db pg_dump -U vfit_user vfit_db | gzip > /backups/vfit-$(date +\%Y\%m\%d).sql.gz
```

### Log Rotation

```bash
# View logs
docker-compose -f docker-compose.prod.yml logs vfit-api

# Clean old logs (keep last 7 days)
docker-compose -f docker-compose.prod.yml exec vfit-api find /app/logs -name "*.log" -mtime +7 -delete
```

### Updates

```bash
# Rebuild and restart services
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d --build

# Verify all services are healthy
docker-compose -f docker-compose.prod.yml ps
```

### SSL Certificate Renewal

```bash
# Automatic renewal (runs daily via Let's Encrypt)
sudo systemctl enable certbot.timer

# Manual renewal
sudo certbot renew --dry-run

# Copy renewed certificate
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/key.pem
sudo chown $USER:$USER ssl/*

# Reload nginx
docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

---

## Troubleshooting

### Service fails to start

```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs vfit-api

# Common issues:
# 1. Port already in use: change PORT in .env.prod
# 2. Model file not found: verify models are in volume
# 3. Database connection: check DB_PASSWORD and DATABASE_URL
```

### High memory usage

```bash
# Check resource usage
docker stats

# Limit container resources in docker-compose.prod.yml:
services:
  vfit-api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

### Slow API responses

```bash
# Check database performance
docker-compose -f docker-compose.prod.yml exec db psql -U vfit_user -d vfit_db -c "SELECT * FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"

# Check Redis cache
docker-compose -f docker-compose.prod.yml exec redis redis-cli INFO stats

# Increase worker processes
docker-compose -f docker-compose.prod.yml down
# Edit docker-compose.prod.yml: add more workers to gunicorn command
docker-compose -f docker-compose.prod.yml up -d
```

---

## Security Checklist

- [ ] `SECRET_KEY` is random and at least 32 characters
- [ ] `GEMINI_API_KEY` is set and valid
- [ ] `CORS_ORIGINS` is restricted to trusted domains
- [ ] Database password is strong (min 16 chars, mix of char types)
- [ ] SSL certificates are installed and valid
- [ ] Firewall allows only necessary ports (80, 443, 22 for SSH)
- [ ] Non-root user runs Docker containers
- [ ] Model files are properly mounted and readable
- [ ] Logs are being collected and monitored
- [ ] Database backups are automated
- [ ] Environment variables are not stored in version control
- [ ] Nginx rate limiting is configured
- [ ] Health checks are passing

---

## APK Build & Deployment

### Android APK Configuration

Update `android/app/build.gradle`:

```gradle
buildTypes {
    release {
        buildConfigField "String", "API_BASE_URL", "\"https://yourdomain.com/api\""
        buildConfigField "String", "API_TIMEOUT", "\"300000\""  // 5 minutes
        buildConfigField "Boolean", "DEBUG_ENABLED", "false"
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### Build APK

```bash
# Android Studio or CLI
./gradlew assembleRelease

# Signed APK
./gradlew bundleRelease

# Output: app/build/outputs/apk/release/app-release.apk
```

### Deploy to Play Store

1. Configure keystore (keep secret!)
2. Build signed APK
3. Upload to Google Play Console
4. Configure app in Play Console to connect to `https://yourdomain.com`

---

## Monitoring & Alerts

### Prometheus Metrics (Optional)

Add to `docker-compose.prod.yml`:

```yaml
prometheus:
  image: prom/prometheus
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus-data:/prometheus
  ports:
    - "9090:9090"
  networks:
    - vfit-network
```

### Uptime Monitoring

```bash
# Cron job to check health every 5 minutes
*/5 * * * * curl -s https://yourdomain.com/health || mail -s "V-Fit API Down" admin@yourdomain.com
```

---

## Contact & Support

For issues or questions about deployment, see the main README.md
