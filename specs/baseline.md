# VFIT Baseline Specification

## Purpose

VFIT is a mobile-first AI fitness ecosystem. The app combines authentication,
onboarding, workout guidance, exercise catalog browsing, nutrition search, AI
food estimation, progress tracking, challenges, VIP payment, and admin
operations. The backend is the trusted gateway. The frontend is the primary
customer and admin interface. AI is the reasoning layer.

## Current Source Layout

- Backend: `VFIT_Backend`.
- Frontend: `VFIT_Fontend`.
- Prompt logic: `skills/conversation/`.
- Architecture decisions: `skills/tech-decision/decision.md`.
- Spec Kit docs: `specs/` and `.specify/`.

## Actors

- Guest: opens app config, public catalogs, login, register, OTP, password
  recovery.
- Pending user: authenticated user who has not completed onboarding.
- Active free user: completed onboarding, non-VIP user.
- Active VIP user: completed onboarding with active VIP monthly or yearly plan.
- Admin: platform operator routed to admin screens.
- Sepay: external payment webhook sender.
- AI Core: intelligent processing service behind `AiClient`.

## Feature Inventory

### App Shell And Routing

Flutter starts at `/splash`. GoRouter redirects by auth status, onboarding
status, and role. Admin users are routed to `/admin/revenue`. Active customers
use the shell routes `/home`, `/workouts`, `/nutrition`, `/progress`,
`/profile`, and `/premium`.

### Authentication

The system supports registration, OTP resend, OTP verification, login, refresh
token, logout, forgot password, reset password, active sessions, and session
deletion. Flutter uses Dio with an auth interceptor that attaches access tokens
and refreshes tokens on eligible `401` responses.

### Onboarding

Pending users provide physical profile fields and goal metrics. Body scan
uploads are stored by backend storage, sent to `AiClient.analyzeBody`, persisted
as `BodyAnalysisResult`, and returned as posture, imbalance, estimate, and
recommendation context. Completing onboarding marks the user active.

### Profile

Users can view current profile, update profile, upload avatar, change password,
view body metrics, list sessions, delete sessions, and delete account.

### Home And App Config

The app reads public configuration from `/api/app/config`. Backend app config
stores app name, slogan, support email, terms URL, privacy URL, latest version,
minimum supported version, and maintenance state.

### Workout Catalog

The backend exposes workout programs at `/api/workouts` and
`/api/workouts/{id}`. Flutter displays workout list and detail routes.

### Exercise Library

The backend exposes classic exercise endpoints at `/api/exercises` and
`/api/exercises/{id}` plus grouped exercise library at
`/api/v1/exercises/grouped`. Flutter includes a muscle map using SVG, XML, and
path hit testing to browse exercise groups and details.

### Personalized Workout

The backend exposes `/api/v1/workouts/personalized`. The service reads the
current user's `GoalType`, fetches `GoalWorkoutMetadata`, and returns rules,
nutrition recovery guidance, and weekly schedule. Results are cached by user id.

### Nutrition

The backend exposes food search at `/api/v1/foods/search` backed by MongoDB food
data. Flutter supports search and local food remembrance through Hive.

### AI Nutrition Scan

Premium users call `/api/ai/food-calorie-estimate` with a multipart camera
image. Backend validates premium access, builds metadata, calls
`AiClient.estimateFoodCalories`, and returns food name, serving size, calories,
macros, confidence, notes, and estimated timestamp.

### AI Form Check

VIP users connect to `/ws/ai/form-check?token=<jwt>&exerciseId=<id>`.
Handshake validates JWT, onboarding, and premium state. Flutter sends binary
camera frames. Backend forwards frame metadata to `AiClient.analyzeForm` and
returns feedback JSON over WebSocket.

### Progress

Users create, list, and delete journey snaps at `/api/progress/snaps`. Uploads
are stored through Cloudinary/local storage. Creating a snap publishes
`ProgressPhotoUploadedEvent`.

### Gamification

The backend exposes badges, challenges, join, revive, participation detail, and
active participations. An async listener maps uploaded progress photos to active
challenges without blocking the upload response.

### Check-In

Users can perform daily check-in through `/api/v1/checkin` and inspect monthly
status through `/api/v1/checkin/status`. Check-in can reward vouchers.

### Payment And VIP

Users can apply vouchers, checkout, create premium payment, inspect payment
status, and inspect VIP status. Sepay webhook verifies HMAC, extracts payment
code, validates amount, marks payment paid, unlocks premium, consumes voucher,
and pushes realtime payment status over `/ws/payments`.

### Admin

Admins can view dashboard stats, manage users, update app config, seed exercise
library defaults, view monthly revenue, and view revenue transactions.

## Sync Flows

### Auth Sync Flow

Flutter form -> Dio -> Spring auth controller -> auth service -> MongoDB
session/token documents -> API envelope -> Flutter auth controller -> GoRouter
redirect.

### Onboarding Sync Flow

Flutter onboarding page -> REST profile/body scan request -> Spring onboarding
controller -> user service -> file storage -> `AiClient.analyzeBody` -> MongoDB
body analysis and user state -> onboarding response -> Flutter route unlock.

### Catalog Sync Flow

Flutter page -> public GET endpoint -> Spring controller -> service/repository
-> MongoDB catalog -> API envelope -> Flutter list/detail UI.

### Payment Sync Flow

Flutter premium page -> create payment REST -> payment service -> MongoDB
payment transaction -> VietQR URL -> Flutter payment UI -> status polling or
WebSocket event.

## Async Flows

### Progress Challenge Async Flow

Journey snap upload -> save progress document -> publish
`ProgressPhotoUploadedEvent` -> `@Async @EventListener` ->
`ChallengeParticipationService.mapPhotoToActiveChallenges`.

### Sepay Webhook Async Flow

Sepay bank event -> `/api/payments/sepay/webhook` -> HMAC verification ->
transaction lookup -> mark paid -> save subscription -> update user snapshot ->
publish `/ws/payments` event.

### Scheduler Async Flow

Spring schedulers run cleanup loops for expired auth artifacts, inactive
accounts, pending payment expiry, and voucher expiry.

### AI WebSocket Async Flow

Flutter camera stream -> `/ws/ai/form-check` binary frames -> AI client call per
frame -> text feedback message -> Flutter realtime coaching overlay.

## Queue And Context Runtime

The current codebase does not include RabbitMQ, Kafka, JMS, SQS, or another
external queue broker. The current "queue" behavior is in-process and
event-driven:

- Spring application events carry domain events.
- `@Async` listeners process background challenge mapping.
- Schedulers poll MongoDB for time-based transitions.
- Webhooks receive external async payment events.
- WebSockets push realtime events to connected clients.
- Redis holds temporary counters, locks, and cache entries.
- MongoDB holds durable context documents.

The "dAbbit context" for this repo is the AI/context state bundle made of
MongoDB durable user state, Redis runtime state, Flutter local/session state,
and prompt contracts in `skills/conversation/`.

## AI Control Requirements

- AI inputs MUST include only required metadata.
- AI outputs MUST be mapped to bounded response contracts.
- AI fallback responses MUST be safe and explicit.
- Premium AI MUST be protected by JWT, onboarding state, subscription state,
  rate limit, and circuit breaker.
- Prompt changes MUST happen in `skills/conversation/`.

## Success Criteria

- Users complete auth and onboarding without accessing protected flows early.
- VIP users receive AI outputs or safe fallback outputs for every AI request.
- Free users are blocked from premium AI.
- Payment webhook unlocks premium exactly once per valid paid transaction.
- Progress photo uploads do not wait for challenge mapping.
- Specs are concrete and match actual code paths.
