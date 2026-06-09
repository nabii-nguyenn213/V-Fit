# Realtime AI Camera Contracts

## Purpose

Document the Flutter-to-Spring WebSocket contracts used for realtime AI camera analysis. Flutter never calls the Python AI service directly; Spring Boot owns authentication, premium gating, rate limiting, and AI client fallback.

## WebSocket Endpoints

### Form Check

- Path: `/ws/ai/form-check`
- Required query parameters:
  - `token`: V-FIT access token
  - `exerciseId`: selected exercise id; `general` is normalized to `squat` by the backend
- Optional query parameters:
  - `cameraView`: defaults to `side`
- Client message: binary JPEG frame bytes
- Server response: JSON `AiFormCheckFeedback`
  - `score`: integer 0-100
  - `summary`: user-facing feedback
  - `formErrors`: bounded list of form issues
  - `affectedJoints`: bounded list of joint names
  - `cue`: short coaching cue
  - `severity`: `OK`, `WARN`, `ERROR`, `RATE_LIMITED`, or `UNKNOWN`
  - `fallback`: boolean

### Body Analysis

- Path: `/ws/ai/body-analysis`
- Required query parameters:
  - `token`: V-FIT access token
- Client message: binary JPEG frame bytes
- Server response: JSON `AiBodyAnalysisResult`
  - `posture.summary`, `posture.riskScore`
  - `imbalance.summary`, `imbalance.severity`
  - `estimate.bodyFatPercent`, `estimate.leanMassKg`, `estimate.confidence`
  - `recommendation.focus`, `recommendation.weeklySessions`
  - `fallback`: boolean

## Runtime Controls

- Both endpoints use the JWT premium handshake interceptor.
- Both endpoints use Redis-backed WebSocket frame rate limiting.
- WebSocket frame limits use:
  - `AI_WS_FRAME_RATE_MAX_FRAMES`
  - `AI_WS_FRAME_RATE_WINDOW_SECONDS`
- If the WebSocket-specific variables are absent, backend falls back to the existing `AI_RATE_LIMIT_*` values.

## Client Streaming Behavior

Flutter sends low-latency JPEG snapshots over the active WebSocket with backpressure:

- Default interval: 500ms
- A new frame is skipped while a previous frame is awaiting AI feedback
- The in-flight frame guard resets after 3 seconds to avoid a permanently stalled stream
