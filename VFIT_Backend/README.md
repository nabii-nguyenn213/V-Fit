# V-FIT Backend

Spring Boot 3 modular monolith backend for V-FIT, built with Java 21, MongoDB, JWT auth, Docker, Lombok, MapStruct, validation, Swagger/OpenAPI, and basic unit tests.

## Architecture

- `common`: shared API envelopes, exceptions, enums, constants, utilities.
- `infrastructure`: OpenAPI, Mongo, web config, file storage, mock AI/payment clients.
- `security`: Spring Security 6, JWT provider/filter, user details.
- `bootstrap`: admin and sample domain data seeders.
- `modules.auth`: complete register/login/refresh/logout/forgot/reset flow.
- `modules.user`: complete profile, body metrics, password, admin user management.
- Remaining modules are scaffolded with documents, repositories, and service contracts for later implementation.

Module communication is designed to prefer Spring `ApplicationEvent`s for loose coupling and future microservice extraction. User XP/badges/subscription snapshot are embedded inside `users` where the relationship is small and user-owned, while high-volume or independent concepts stay in their own collections.

## Run With Docker

```bash
cp .env.example .env
docker compose up --build
```

Services:

- Backend: `http://localhost:8080`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- Mongo Express: `http://localhost:8081`

MongoDB is initialized by `docker/mongo/init-mongo.js` on the first container startup. It creates:

- Database: `vfit`
- App user: value of `MONGO_APP_USERNAME`
- App password: value of `MONGO_APP_PASSWORD`
- Core collections and indexes
- Public app config collection: `app_configs`

Default admin seed:

- Email: `admin@vfit.com`
- Password: `Admin@123`

## Configure MongoDB In Docker

Create `.env` from the template:

```bash
cp .env.example .env
```

For local development with the full Docker Compose stack, keep:

```env
MONGO_INITDB_DATABASE=vfit
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=change_this_root_password
MONGO_APP_USERNAME=vfit_app
MONGO_APP_PASSWORD=change_this_app_password
MONGODB_URI=mongodb://vfit_app:change_this_app_password@mongodb:27017/vfit?authSource=vfit
BOOTSTRAP_ADMIN_EMAIL=admin@vfit.com
BOOTSTRAP_ADMIN_PASSWORD=Admin@123
BOOTSTRAP_ADMIN_FULL_NAME=V-FIT Admin
BOOTSTRAP_APP_NAME=V-FIT
BOOTSTRAP_APP_SLOGAN=Train smarter, live healthier
BOOTSTRAP_SUPPORT_EMAIL=support@vfit.com
BOOTSTRAP_TERMS_URL=https://vfit.com/terms
BOOTSTRAP_PRIVACY_URL=https://vfit.com/privacy
BOOTSTRAP_LATEST_VERSION=1.0.0
BOOTSTRAP_MIN_SUPPORTED_VERSION=1.0.0
```

Start only MongoDB and Mongo Express:

```bash
docker compose up -d mongodb mongo-express
```

Connect from the Mongo container terminal:

```bash
docker exec -it vfit-mongodb mongosh -u root -p change_this_root_password --authenticationDatabase admin
```

Inside `mongosh`:

```javascript
use vfit
show collections
db.runCommand({ ping: 1 })
db.users.find()
db.app_configs.find()
```

If the backend runs on your host machine through IDE or Maven while MongoDB runs in Docker, use `localhost` in the Mongo URI:

```env
MONGODB_URI=mongodb://vfit_app:change_this_app_password@localhost:27017/vfit?authSource=vfit
```

For the included local dev `.env`, IntelliJ can use:

```env
MONGODB_URI=mongodb://vfit_app:vfit_app_dev_password@localhost:27017/vfit?authSource=vfit
```

The default `application.properties` already points to this local Docker MongoDB URI, so a fresh IntelliJ run works as long as MongoDB is running.

If the backend also runs inside Docker Compose, use the service name `mongodb`:

```env
MONGODB_URI=mongodb://vfit_app:change_this_app_password@mongodb:27017/vfit?authSource=vfit
```

On a server, set the same environment variables in your deployment secret store and replace the passwords with strong values. Do not commit the real `.env` file.

If a Mongo volume already existed before these credentials were added, the init script will not run again automatically. For a fresh local database only, reset the volume with:

```bash
docker compose down -v
docker compose up -d mongodb mongo-express
```

## Run Locally

Start MongoDB locally, then:

```bash
mvn spring-boot:run
```

## Test

```bash
mvn test
```

## Login And Use JWT

PowerShell:

```powershell
$body = @{ email = "admin@vfit.com"; password = "Admin@123" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -ContentType "application/json" -Body $body
```

Git Bash/Linux/macOS:

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@vfit.com","password":"Admin@123"}'
```

Use `data.tokens.accessToken` as:

```text
Authorization: Bearer <accessToken>
```

Example:

```bash
curl http://localhost:8080/api/users/me \
  -H "Authorization: Bearer <accessToken>"
```

## Implemented APIs

- `GET /api/app/config`
- `GET /api/exercises`
- `GET /api/exercises/{id}`
- `GET /api/foods`
- `GET /api/foods/{id}`
- `GET /api/workouts`
- `GET /api/workouts/{id}`
- `GET /api/gamification/badges`
- `GET /api/gamification/challenges`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh-token`
- `POST /api/auth/logout`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`
- `GET /api/users/me`
- `PUT /api/users/me`
- `PUT /api/users/change-password`
- `GET /api/users/me/body-metrics`
- `GET /api/admin/dashboard`
- `GET /api/admin/users`
- `PUT /api/admin/users/{id}/role`
- `DELETE /api/admin/users/{id}`
- `GET /api/admin/app-config`
- `PUT /api/admin/app-config`

Catalog data returned by these endpoints is read from MongoDB. Seed values are only inserted when the database is empty; edit MongoDB data or use admin APIs instead of changing Java constants.

## Next Modules

Workout, exercise, AI, nutrition, gamification, subscription, community, notification, and admin CRUD are scaffolded so their controllers/application services can be added without crossing repository boundaries.
