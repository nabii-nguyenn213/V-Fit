# V-FIT Onboarding, Feature Gates, and AI Gateway

## Feature Policy

| Actor | Allowed | Blocked |
| --- | --- | --- |
| Guest | Read static exercise and workout catalog APIs | Progress write, AI, profile |
| Authenticated Free | Guest features, profile, progress logs, journey snaps | AI Form Check, AI Body Analysis outside onboarding, Recommendation |
| Premium Customer | All customer features | Admin revenue dashboard |
| Admin | Revenue dashboard only | Customer mobile flows |

Premium means `subscription.status = ACTIVE` and `subscription.planCode in (VIP_MONTHLY, VIP_YEARLY)`.

## DB Schema

The current implementation stores these documents in MongoDB, using `Map<String,Object>` for flexible AI payloads. If this is moved to PostgreSQL, the production schema should map those fields to `JSONB`.

### `users`

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID / ObjectId | Primary key |
| `email` | VARCHAR(255) | Unique, lower-cased |
| `password_hash` | TEXT | BCrypt |
| `full_name` | VARCHAR(180) | Display name |
| `avatar_url` | TEXT | Relative upload path or absolute CDN URL |
| `role` | VARCHAR(32) | `USER` or `ADMIN` only |
| `onboarding_status` | VARCHAR(32) | `PENDING`, `COMPLETED` |
| `active` | BOOLEAN | `false` until onboarding is completed |
| `subscription_status` | VARCHAR(32) | `FREE`, `ACTIVE`, `EXPIRED`, `CANCELED` |
| `subscription_plan_code` | VARCHAR(32) | `VIP_MONTHLY`, `VIP_YEARLY`, nullable |
| `premium_until` | TIMESTAMP | Nullable |
| `progress` | JSONB | XP, level, completed workouts |
| `created_at` | TIMESTAMP | Audit |
| `updated_at` | TIMESTAMP | Audit |

### `user_profiles`

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID / ObjectId | Primary key |
| `user_id` | UUID / ObjectId | Unique FK to `users.id` |
| `gender` | VARCHAR(32) | Nullable |
| `date_of_birth` | DATE | Nullable |
| `goal_type` | VARCHAR(64) | Nullable |
| `height_cm` | NUMERIC(5,2) | Required before body scan |
| `weight_kg` | NUMERIC(5,2) | Required before body scan |
| `body_fat_percent` | NUMERIC(5,2) | Optional |
| `bmi` | NUMERIC(4,1) | Calculated by backend |
| `body_analysis_posture` | JSONB | AI posture analysis |
| `body_analysis_imbalance` | JSONB | AI imbalance analysis |
| `body_analysis_estimate` | JSONB | AI body estimate |
| `recommendation_context` | JSONB | Recommendation seed/context |
| `measured_at` | TIMESTAMP | Last physical measurement |
| `created_at` | TIMESTAMP | Audit |
| `updated_at` | TIMESTAMP | Audit |

### `progress_logs`

| Column | Type | Notes |
| --- | --- | --- |
| `id` | UUID / ObjectId | Primary key |
| `user_id` | UUID / ObjectId | Indexed |
| `type` | VARCHAR(32) | `JOURNEY_SNAP`, `WORKOUT`, `BODY_ANALYSIS`, `FORM_CHECK` |
| `photo_url` | TEXT | Nullable for non-photo logs |
| `note` | TEXT | Optional |
| `metrics` | JSONB | Weight, reps, duration, calories, etc. |
| `ai_feedback` | JSONB | Form check or body scan summaries |
| `created_at` | TIMESTAMP | Sort key |

## API Surface and AI Core Contracts

### Mandatory Onboarding

```http
PUT /api/v1/users/onboarding/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "heightCm": 175,
  "weightKg": 70,
  "bodyFatPercent": 18
}
```

```http
POST /api/v1/users/onboarding
Authorization: Bearer <token>
Content-Type: multipart/form-data

file=<image-or-video>
```

Step 3 stores the upload, calls `AiClient.analyzeBody`, saves `posture`, `imbalance`, `estimate`, and `recommendation`, then flips the user to `onboardingStatus=COMPLETED` and `active=true`.

### Real-Time Form Check

```text
ws://<api-host>/ws/ai/form-check?token=<access-token>&exerciseId=<exercise-id>
```

The Spring WebSocket handshake validates JWT, reloads the user from DB, checks `onboardingStatus=COMPLETED`, and calls `@featureGate.isPremium(authentication)`. Binary messages are camera frames. Text messages are AI feedback JSON.

Client to Gateway frame contract:

```text
Connection query:
  token: JWT access token
  exerciseId: current exercise catalog id

Binary payload:
  JPEG or NV21 frame bytes, max recommended size 256 KB
  target cadence: 10-15 fps
```

Gateway to AI Core frame contract:

```json
{
  "sessionId": "ws-session-id",
  "userId": "user-uuid",
  "exerciseId": "squat",
  "frameSequence": 1042,
  "timestampMs": 1779270000000,
  "frame": {
    "encoding": "JPEG",
    "width": 720,
    "height": 1280,
    "bytesBase64": "<only-if-not-using-binary-upstream>"
  },
  "device": {
    "platform": "android",
    "camera": "front"
  }
}
```

AI Core to Gateway feedback contract:

```json
{
  "type": "FORM_FEEDBACK",
  "sessionId": "ws-session-id",
  "frameSequence": 1042,
  "latencyMs": 63,
  "coordinates": {
    "boundingBox": { "x": 0.18, "y": 0.12, "width": 0.62, "height": 0.78 },
    "keypoints": [
      { "name": "left_knee", "x": 0.41, "y": 0.66, "score": 0.96 },
      { "name": "right_knee", "x": 0.56, "y": 0.67, "score": 0.95 }
    ]
  },
  "jointAngles": {
    "leftKnee": 82.4,
    "rightKnee": 88.1,
    "hip": 64.8
  },
  "formErrors": [
    {
      "code": "KNEE_VALGUS",
      "severity": "WARN",
      "message": "Keep knees aligned with toes",
      "affectedJoints": ["left_knee", "right_knee"]
    }
  ]
}
```

### Body Analysis Contract

App to Gateway:

```http
POST /api/v1/users/onboarding
Authorization: Bearer <token>
Content-Type: multipart/form-data

file=<body-scan-image-or-video>
```

Gateway to AI Core:

```http
POST /v1/body-analysis
Content-Type: multipart/form-data

userId=<user-id>
source=ONBOARDING
heightCm=175
weightKg=70
bodyFatPercent=18
file=<image-or-video>
```

AI Core response:

```json
{
  "analysisId": "body-analysis-id",
  "posture": {
    "summary": "Forward head posture risk is low",
    "riskScore": 18,
    "landmarks": [{ "name": "left_shoulder", "x": 0.42, "y": 0.34, "score": 0.94 }]
  },
  "imbalance": {
    "summary": "Minor left-right shoulder imbalance",
    "severity": "LOW",
    "segments": [{ "name": "shoulder", "deltaPercent": 4.2 }]
  },
  "estimate": {
    "bodyFatPercent": 22.0,
    "leanMassKg": 58.5,
    "confidence": 0.78
  },
  "recommendationSeed": {
    "focus": "mobility and recomposition",
    "constraints": ["shoulder_stability"]
  }
}
```

The onboarding endpoint is the one allowed exception for `PENDING` users. Any standalone body re-scan endpoint should use `@PreAuthorize("@featureGate.isPremium(authentication)")`.

### Recommendation Contract

Gateway to AI Core:

```http
POST /v1/recommendations
Content-Type: application/json
```

```json
{
  "userId": "user-uuid",
  "subscriptionPlanCode": "VIP_MONTHLY",
  "bodyProfile": {
    "heightCm": 175,
    "weightKg": 70,
    "posture": {},
    "imbalance": {},
    "estimate": {}
  },
  "formHistory": [
    {
      "exerciseId": "squat",
      "errorCode": "KNEE_VALGUS",
      "count": 12,
      "lastSeenAt": "2026-05-20T12:00:00Z"
    }
  ],
  "preferences": {
    "goalType": "GAIN_MUSCLE",
    "daysPerWeek": 4,
    "dietStyle": "balanced"
  }
}
```

AI Core response:

```json
{
  "workoutPlan": {
    "name": "4-day corrective hypertrophy",
    "weeks": [
      {
        "week": 1,
        "sessions": [
          {
            "day": 1,
            "focus": "lower_body",
            "exercises": [
              { "exerciseId": "goblet_squat", "sets": 4, "reps": "8-10" }
            ]
          }
        ]
      }
    ]
  },
  "nutritionPlan": {
    "dailyCalories": 2350,
    "proteinGrams": 145,
    "carbGrams": 250,
    "fatGrams": 70
  },
  "assistantContext": {
    "riskFlags": ["knee_alignment"],
    "tone": "coach",
    "shortTermFocus": "stable squat pattern"
  }
}
```

Persist Pipeline 3 output as `JSONB recommendation_context` or a dedicated recommendation table if versioning plans becomes important.

## Spring Boot Code Shape

Raw binary WebSocket is the active low-latency path in this repo. If the team standardizes on STOMP message broker, keep the same security interceptor and expose this broker config:

```java
@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
class AiFormCheckBrokerConfig implements WebSocketMessageBrokerConfigurer {
    private final JwtPremiumHandshakeInterceptor jwtPremiumHandshakeInterceptor;
    private final JwtUserHandshakeHandler jwtUserHandshakeHandler;

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws/ai/form-check-stomp")
                .addInterceptors(jwtPremiumHandshakeInterceptor)
                .setHandshakeHandler(jwtUserHandshakeHandler)
                .setAllowedOriginPatterns("*");
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.setApplicationDestinationPrefixes("/app");
        registry.enableSimpleBroker("/topic", "/queue");
        registry.setUserDestinationPrefix("/user");
    }
}
```

REST controller security for premium standalone Pipeline 2:

```java
@RestController
@RequestMapping("/api/ai/body-analysis")
@RequiredArgsConstructor
class AiBodyAnalysisController {
    private final AiBodyAnalysisService aiBodyAnalysisService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("@featureGate.isPremium(authentication)")
    ApiResponse<BodyAnalysisResponse> analyze(@RequestPart("file") MultipartFile file) {
        return ApiResponse.ok(aiBodyAnalysisService.analyze(file));
    }
}
```

## Flutter Code Shape

Auth owns the global route state:

```dart
enum AuthStatus { initial, unauthenticated, pendingOnboarding, active }
```

Route guard:

```dart
if (auth.isPendingOnboarding && path != '/onboarding') {
  return '/onboarding';
}
```

Back guard:

```dart
PopScope(
  canPop: false,
  child: OnboardingPageBody(),
)
```

BLoC event flow:

```dart
bloc.add(OnboardingPhysicalProfileSubmitted(
  heightCm: 175,
  weightKg: 70,
));
bloc.add(OnboardingBodyScanSelected(file));
bloc.add(const OnboardingBodyScanSubmitted());
```

WebSocket stream:

```dart
await formCheckStreamClient.connect(exerciseId: exercise.id);
cameraImageStream.listen((jpegBytes) {
  formCheckStreamClient.sendJpegFrame(jpegBytes);
});
formCheckStreamClient.feedback.listen(renderSkeletonAndWarnings);
```

## Clean Architecture Layout

```text
backend/src/main/java/com/vfit
  common/                 shared API, enum, exception, security utilities
  security/               JWT auth, onboarding guard, premium feature gate
  infrastructure/
    config/               Spring, WebSocket, app properties
    external/ai/          AI Core client boundary
    storage/              local or cloud file storage
  modules/
    user/
      controller/         onboarding and profile APIs
      service/            onboarding orchestration
      document/           user aggregate
    ai/
      websocket/          real-time form check gateway
      document/           AI analysis persistence
    progress/             free customer progress logs

frontend/lib
  core/                   router, network, constants, shared widgets
  features/
    auth/application/     Auth state machine: initial, unauthenticated, pendingOnboarding, active
    onboarding/           forced profile and body scan flow
    workout/data/streams/ WebSocket form check stream client
    progress/             free customer journey snaps
```
