# Data Model: Real-time Body Scan Onboarding Flow

## Entities

### User (MongoDB `users` collection)
During the onboarding flow, the user undergoes specific state transitions:
- **State 0**: Registered but onboarding is `PENDING`.
- **State 1**: Completes physical profile (Height, Weight, Body Fat).
- **State 2**: Executes real-time body scan. Upon receipt of valid body shape metrics:
  - `onboardingStatus` transitions to `COMPLETED`.
  - `active` transitions to `true`.
  - `goalType` is updated to the value inferred from the body metrics and AI recommendation.

### BodyAnalysisResult (MongoDB `bodyAnalysisResult` collection)
A new record is inserted into this collection for the scan history:
- `userId`: String (corresponds to user ID)
- `metadata`: Map containing:
  - `"source": "onboarding-realtime"`
  - `"inferredGoalType": GoalType`
- `posture`: Detailed posture analysis map.
- `imbalance`: Detailed imbalance analysis map.
- `estimate`: Body estimates (fat percentage, lean mass, confidence, waist/shoulder ratio).
- `recommendation`: Focused workout recommendations.
