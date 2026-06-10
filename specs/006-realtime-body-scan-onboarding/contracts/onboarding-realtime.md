# REST API Contract: Real-time Onboarding Body Scan

## Endpoint
`POST /api/v1/users/onboarding/realtime`

- **Headers**:
  - `Authorization: Bearer <JWT_TOKEN>`
  - `Content-Type: application/json`

## Request Payload
Accepts the `AiBodyAnalysisResult` JSON model.

```json
{
  "posture": {
    "summary": "Good posture",
    "riskScore": 12
  },
  "imbalance": {
    "summary": "No major imbalances",
    "severity": "LOW"
  },
  "estimate": {
    "bodyFatPercent": 15.4,
    "leanMassKg": 62.0,
    "confidence": 0.85,
    "waistShoulderRatio": 0.78
  },
  "recommendation": {
    "focus": "muscle_gain",
    "weeklySessions": 4
  },
  "fallback": false
}
```

## Response Payload
Returns the standard `ApiResponse` wrapping an `OnboardingResponse`.

```json
{
  "code": "SUCCESS",
  "message": "Operation completed successfully",
  "data": {
    "onboardingStatus": "COMPLETED",
    "user": {
      "id": "647f6312a02b3c1d2e3f4a5b",
      "email": "user@vfit.com",
      "role": "USER",
      "onboardingStatus": "COMPLETED",
      "active": true,
      "goalType": "GAIN_MUSCLE",
      "bodyMetrics": {
        "heightCm": 180.0,
        "weightKg": 75.0,
        "bodyFatPercent": 15.4,
        "bmi": 23.1,
        "measuredAt": "2026-06-10T08:52:00Z"
      }
    },
    "posture": {
      "summary": "Good posture",
      "riskScore": 12
    },
    "imbalance": {
      "summary": "No major imbalances",
      "severity": "LOW"
    },
    "estimate": {
      "bodyFatPercent": 15.4,
      "leanMassKg": 62.0,
      "confidence": 0.85,
      "waistShoulderRatio": 0.78
    },
    "recommendation": {
      "focus": "muscle_gain",
      "weeklySessions": 4
    },
    "fallback": false
  }
}
```
