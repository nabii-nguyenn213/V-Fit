# V-FIT Production Deployment

Read `../../docs/DEPLOY_ARCHITECTURE_RULES.md` before changing production
deployment, OAuth, Android signing, frontend runtime config, or backend env
contracts.

## Recommended Layout

Use this layout when the app is heading toward real mobile release:

```text
Frontend: Vercel, Netlify, or VPS Nginx
Backend: Docker container on VPS
Database: MongoDB Atlas
Domain: api.your-domain.com -> backend
```

Keep MongoDB private. The mobile app and frontend should call only the HTTPS API domain.

## Backend On VPS

1. Install Docker and Docker Compose.
2. Copy the repository to the server.
3. Create production env:

```bash
cp .env.production.example .env.production
```

4. Edit `.env.production`:

```env
APP_BASE_URL=https://api.your-domain.com
CORS_ALLOWED_ORIGINS=https://your-domain.com,https://app.your-domain.com
MONGODB_URI=mongodb+srv://vfit_app:<strong_password>@<cluster-host>/vfit?retryWrites=true&w=majority
JWT_SECRET=<long_random_secret>
OTP_PEPPER=<different_long_random_secret>
BOOTSTRAP_ADMIN_EMAIL=admin@your-domain.com
BOOTSTRAP_ADMIN_PASSWORD=<strong_admin_password>
```

5. Start backend:

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

6. Check health:

```bash
curl http://127.0.0.1:8080/actuator/health
```

After the first successful admin bootstrap, set:

```env
BOOTSTRAP_ADMIN_ENABLED=false
```

Then redeploy.

## First Server Checklist

On an Ubuntu VPS, the minimum production setup is:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin nginx certbot python3-certbot-nginx
sudo systemctl enable --now docker nginx
```

Open only SSH, HTTP, and HTTPS:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

Point DNS `A` record for `api.your-domain.com` to the VPS public IP before issuing SSL.

## Nginx

Use `deploy/nginx/vfit-api.conf` as the reverse proxy template. Replace:

```text
api.your-domain.com
```

with the real API domain.

The backend port is bound to `127.0.0.1:8080`, so it is reachable from Nginx on the server but not exposed directly to the public internet.

Install the API site:

```bash
sudo cp deploy/nginx/vfit-api.conf /etc/nginx/sites-available/vfit-api.conf
sudo ln -s /etc/nginx/sites-available/vfit-api.conf /etc/nginx/sites-enabled/vfit-api.conf
sudo nginx -t
sudo systemctl reload nginx
```

Issue HTTPS certificate:

```bash
sudo certbot --nginx -d api.your-domain.com
```

## Mobile App

The mobile app should use:

```text
https://api.your-domain.com/api
```

as the API base URL.

Never ship MongoDB credentials in the mobile app. Only the backend owns `MONGODB_URI`.
