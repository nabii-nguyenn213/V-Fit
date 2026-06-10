# Feature Specification: Real-time Body Scan Onboarding Flow

**Feature Branch**: `006-realtime-body-scan-onboarding`

**Created**: 2026-06-10

**Status**: Draft

**Input**: User description: "fix cho t luồng scan body t chỉ cần real time khi bên AI xác định được thể trạng cơ thể là dừng theo luồng app (luồng app khi đăng nhập sẽ là điền ttin xong đến scan =>> xác định thể trạng người lúc này real time khi nhận data dáng người lần đầu thì lưu vào db và dừng cái scan body check)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Real-time Onboarding Body Scan (Priority: P1)

As a newly registered user completing the onboarding flow, I want the second step of onboarding (Body Scan) to run a real-time AI camera analysis of my posture and body metrics. Once the AI successfully identifies my body type and posture metrics for the first time, the system should automatically save these metrics to the database, mark my onboarding as completed, stop the camera/WebSocket stream, and automatically redirect me to the Home page.

**Why this priority**: Essential for a smooth, frictionless onboarding experience. Replaces the clunky manual static photo upload with interactive, instant real-time AI detection.

**Independent Test**:
1. Log in with a fresh user account that has pending onboarding status.
2. Complete Step 0 (Physical Profile: Height, Weight, etc.) and save.
3. On Step 1 (Body Scan), click "Bắt đầu quét cơ thể realtime".
4. Position yourself in front of the camera. As soon as the AI model detects your posture, verify that it saves the result to the database, displays a success message, and redirects you to the Home page automatically.

**Acceptance Scenarios**:

1. **Given** the user is on onboarding Step 1 (Body Scan), **When** they click "Bắt đầu quét cơ thể realtime", **Then** the app must open the real-time camera view using `/ws/ai/body-analysis`.
2. **Given** the real-time camera is active during onboarding, **When** the first valid AI body analysis result (non-fallback, confidence > 0) is received, **Then** the app must automatically stop the WebSocket connection.
3. **Given** a valid body analysis result is received, **When** the app halts the scan, **Then** it must submit the result JSON to the backend API (`/api/v1/users/onboarding/realtime`), save the result, set user onboardingStatus to COMPLETED, set user active to true, and update the local User state.
4. **Given** onboarding is completed, **When** the API call succeeds, **Then** the app must show a success notification and redirect the user to `/home`.

---

### Edge Cases

- **AI Fallback / No detection**: If the AI returns a fallback response (e.g. `fallback: true` due to partial body visibility), the onboarding scan should continue streaming until a clear full-body frame is captured and successfully analyzed (i.e. `fallback: false` and `confidence > 0`).
- **Network Outage / Failure during Save**: If the network connection drops or the save API call fails, the app must show an error notification and allow the user to retry the scan, rather than silently failing or locking the screen.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST support a REST API endpoint `/api/v1/users/onboarding/realtime` (POST) that accepts `AiBodyAnalysisResult` in JSON, updates user goal, sets onboardingStatus to COMPLETED, and saves the body analysis record in the database.
- **FR-002**: The Flutter client MUST integrate `AiRealtimeCameraView` in onboarding Step 1 (Body Scan) when the user launches the scan.
- **FR-003**: The Flutter client MUST intercept the first valid (non-fallback) body analysis result from the WebSocket and automatically invoke the onboarding save API.
- **FR-004**: Upon successful saving of the onboarding data, the client MUST stop the camera stream, close the WebSocket, and navigate the user to `/home`.

### Key Entities

- **User**: The V-FIT user entity whose onboardingStatus must transition from `PENDING` to `COMPLETED`.
- **BodyAnalysisResult**: The DB document storing the history of body scans, which now includes scans sourced from "onboarding-realtime".

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The real-time body scan completes and saves to the database automatically in under 5 seconds from when a full body is successfully framed.
- **SC-002**: 100% of successful onboarding scans correctly update the user's `onboardingStatus` to `COMPLETED` and `active` to `true` in MongoDB.
