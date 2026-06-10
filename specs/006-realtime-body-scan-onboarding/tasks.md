# Tasks: Real-time Body Scan Onboarding Flow

**Input**: Design documents from `/specs/006-realtime-body-scan-onboarding/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/onboarding-realtime.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Set up route and endpoint paths

- [x] T001 [P] Define API endpoint `/api/v1/users/onboarding/realtime` in `VFIT_Fontend/lib/core/constants/api_endpoints.dart`
- [x] T002 [P] Configure GoRouter route path `/onboarding/body-scan-realtime` in `VFIT_Fontend/lib/core/router/app_router.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish key backend declarations, API calls, and camera view extensions

- [x] T003 Implement `completeRealtimeBodyScan` API call in `VFIT_Fontend/lib/features/onboarding/data/repositories/onboarding_repository.dart`
- [x] T004 Declare `completeRealtimeBodyScan` method in `VFIT_Backend/src/main/java/com/vfit/modules/user/service/OnboardingService.java`
- [x] T005 [P] Add `onFeedbackReceived` callback to `AiRealtimeCameraView` in `VFIT_Fontend/lib/features/ai/presentation/widgets/ai_realtime_camera_view.dart`
- [x] T006 Implement triggering `onFeedbackReceived` callback upon receiving non-fallback, high confidence frame feedback inside `_listenForFeedback` in `VFIT_Fontend/lib/features/ai/presentation/widgets/ai_realtime_camera_view.dart`

---

## Phase 3: User Story 1 - Real-time Body Scan Onboarding (Priority: P1) 🎯 MVP

**Goal**: Complete onboarding and persist body analysis metrics automatically using real-time AI scanner camera.

**Independent Test**: Register a new user, go to Step 1 of onboarding, click "Bắt đầu quét cơ thể realtime", frame body correctly, check that websocket stream closes, database saves the metrics record, and user is redirected to `/home`.

### Implementation for User Story 1

- [x] T007 [US1] Implement `completeRealtimeBodyScan` in `VFIT_Backend/src/main/java/com/vfit/modules/user/service/impl/OnboardingServiceImpl.java`
- [x] T008 [US1] Implement POST `/api/v1/users/onboarding/realtime` endpoint in `VFIT_Backend/src/main/java/com/vfit/modules/user/controller/OnboardingController.java`
- [x] T009 [US1] Add "Bắt đầu quét cơ thể realtime" button to Step 1 of `VFIT_Fontend/lib/features/onboarding/presentation/pages/onboarding_page.dart`
- [x] T010 [US1] Create page `AiOnboardingBodyScanPage` in `VFIT_Fontend/lib/features/onboarding/presentation/pages/ai_onboarding_body_scan_page.dart`

---

## Phase N: Polish & Cross-Cutting Concerns

- [x] T011 Verify DB states for users and bodyAnalysisResult after successful scans
- [x] T012 Run quickstart.md validation and manual verification tests
