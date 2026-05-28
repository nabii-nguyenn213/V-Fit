# AI Contracts

## Food Calorie Estimate

Endpoint: `POST /api/ai/food-calorie-estimate`

Input: Multipart image, authenticated premium user.

Output MUST include:

- `foodName`
- `servingSize`
- `calories`
- `proteinGrams`
- `carbGrams`
- `fatGrams`
- `confidence`
- `notes`
- `estimatedAt`

Rules:

- Return fallback values when AI is unavailable.
- Include confidence.
- Never directly mutate nutrition history from raw AI output.

## Form Check WebSocket

Endpoint: `/ws/ai/form-check?token=<access-token>&exerciseId=<exercise-id>`

Input: Binary camera frames from a completed-onboarding premium user.

Output MUST include feedback JSON with score or actionable form summary.

Rules:

- Validate JWT during handshake.
- Validate premium access.
- Rate-limit AI traffic.
- Keep feedback concise enough for real-time exercise.

## Body Analysis

Flow: Onboarding body scan and future premium body re-scan.

Output MUST include posture, imbalance, estimate, recommendation seed,
confidence, and fallback state when required.

Rules:

- Onboarding MAY call body analysis for pending users.
- Standalone re-scan MUST require premium access.
- Do not return medical diagnosis.
