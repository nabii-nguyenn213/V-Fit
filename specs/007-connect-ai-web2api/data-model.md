# Data Model: AI Connection and Coach Chat

## Models

### 1. CoachMessageModel (Flutter)
Represents a message sent to or received from the AI Coach.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique message identifier |
| `text` | String | Content of the message |
| `isUser` | bool | True if sent by the user, false if from AI |
| `createdAt` | DateTime | Timestamp of the message |

### 2. CoachRequest (FastAPI / Flutter API request)
Payload sent to RecommendationSystem.

| Field | Type | Description |
|-------|------|-------------|
| `question` | String | Question asked by the user |
| `age` | int | User age |
| `gender` | String | User gender |
| `weight` | double | User weight in kg |
| `height` | double | User height in cm |
| `goal` | String | User fitness goal |
| `activity_level` | String | User activity level |
