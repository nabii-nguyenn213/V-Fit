# Tasks: Đăng ký Dùng thử VIP 3 ngày, Thiết kế lại Hồ sơ và Quy trình Thiết lập Ban đầu

**Input**: Design documents from `/specs/010-deploy-play-store/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Tests are OPTIONAL. We will focus on manual verification and existing backend test suits.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Setup task list and verify spec-kit requirements

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Add `"VIP_TRIAL"` to the list of Premium plans in backend security [FeatureGate.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/security/FeatureGate.java)
- [x] T003 [P] Add `"VIP_TRIAL"` support in [UserMapper.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/mapper/UserMapper.java) and [PaymentServiceImpl.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/payment/service/impl/PaymentServiceImpl.java)
- [x] T004 Define API endpoint router for onboarding reset `/api/v1/users/onboarding/reset` on frontend [api_endpoints.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/core/constants/api_endpoints.dart)
- [x] T005 Setup new endpoint in backend [OnboardingController.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/controller/OnboardingController.java)
- [x] T006 Implement the backend service method `resetOnboarding` in [OnboardingService.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/service/OnboardingService.java) and [OnboardingServiceImpl.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/service/impl/OnboardingServiceImpl.java)
- [x] T007 Update [validators.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/core/utils/validators.dart) on frontend to use Vietnamese error messages for required, email, password, and optionalNumber validations

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - 3-day VIP Trial on register (US1) (Priority: P1) 🎯 MVP

**Goal**: Automatically grant 3-day VIP trial to newly registered users (both local and social auth)

**Independent Test**: Register a new user, log in, go to Profile, verify "Vip Trial" is displayed.

### Implementation for User Story 1

- [x] T008 [US1] Auto-assign 3-day VIP Trial subscription in [UserServiceImpl.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/service/impl/UserServiceImpl.java) for local registered user
- [x] T009 [US1] Auto-assign 3-day VIP Trial subscription in [AuthServiceImpl.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/auth/service/impl/AuthServiceImpl.java) for Google/Facebook OAuth registered user
- [x] T010 [P] [US1] Support `"VIP_TRIAL"` plan mapping in frontend [user_model.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/data/models/user_model.dart)
- [x] T011 [US1] Format `"VIP_TRIAL"` representation to `'Vip Trial'` in frontend [profile_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/presentation/pages/profile_page.dart)

**Checkpoint**: User Story 1 functional. New users receive 3 days of VIP Trial.

---

## Phase 4: User Story 2 - Redesign Body Metrics Display on Profile Page (US2) (Priority: P1)

**Goal**: Show a beautiful light/dark mode card prompting body metrics update if onboarding is pending, instead of VIP error block.

**Independent Test**: Login with a user having PENDING onboarding, go to Profile, verify card shows "Cập nhật thể trạng cơ thể" and adapts to theme mode.

### Implementation for User Story 2

- [x] T012 [US2] Update [profile_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/presentation/pages/profile_page.dart) to check `user.onboardingStatus == OnboardingStatus.pending` before showing body metrics
- [x] T013 [US2] If pending, render the custom `AppCard` displaying "Cập nhật thể trạng cơ thể" and a "Tiếp tục thiết lập" button routing to `/onboarding`. Ensure it adapts to light/dark themes natively.

**Checkpoint**: User Story 2 functional. No VIP error block is shown on Profile for pending onboarding users.

---

## Phase 5: User Story 3 - Block Edit Profile and Lock Goal Field (US3) (Priority: P1)

**Goal**: Block Edit Profile screen for pending onboarding users (prompt setup) and lock Goal selection for completed users (allow reset via button).

**Independent Test**: Try accessing Edit Profile with a pending onboarding user (verify blocker), and with completed user (verify Goal locked, and "Thiết lập lại từ đầu" resets onboarding status and redirects).

### Implementation for User Story 3

- [x] T014 [US3] Update [edit_profile_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/presentation/pages/edit_profile_page.dart) to check if `user.onboardingStatus != OnboardingStatus.completed` at build time
- [x] T015 [US3] If pending onboarding, block the profile edit form and display the custom card prompting the user to complete their body metrics/onboarding setup (same card design as Profile)
- [x] T016 [US3] Lock the Goal dropdown field when onboarding is complete or pending in [edit_profile_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/presentation/pages/edit_profile_page.dart)
- [x] T017 [US3] Implement the "Thiết lập lại từ đầu" button and confirmation dialog in [edit_profile_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/presentation/pages/edit_profile_page.dart) that triggers the API call `/api/v1/users/onboarding/reset`
- [x] T018 [US3] Implement the repository method `resetOnboarding` in [onboarding_repository.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/onboarding/data/repositories/onboarding_repository.dart) to send `PUT` request

**Checkpoint**: User Story 3 functional. Edit Profile page restricts Goal and handles pending onboarding.

---

## Phase 6: User Story 4 - Pre-fill physical metrics on Onboarding screen (US4) (Priority: P1)

**Goal**: Pre-populate height, weight, and body fat fields on Onboarding screen using current user metrics if already present.

**Independent Test**: Set metrics in Edit Profile, then trigger "Thiết lập lại từ đầu", verify metrics are pre-filled in the new Onboarding session.

### Implementation for User Story 4

- [x] T019 [US4] Update [onboarding_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/onboarding/presentation/pages/onboarding_page.dart)'s `initState` to fetch/pull existing body metrics from cache or API and pre-populate fields.

**Checkpoint**: User Story 4 functional. Onboarding inputs are pre-filled.

---

## Phase 7: User Story 5 - Localize login/register validators and all text strings (US5) (Priority: P1)

**Goal**: Fully translate frontend validation error messages and leftover non-accented text blocks to accented Vietnamese.

**Independent Test**: Trigger validation errors in Login and Register forms, verify they are in Vietnamese. Verify camera scan and payment activation text strings are in accented Vietnamese.

### Implementation for User Story 5

- [x] T020 [US5] Update password validation callbacks in [login_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/auth/presentation/pages/login_page.dart) to pass appropriate Vietnamese label
- [x] T021 [US5] Update password validation callbacks in [change_password_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/presentation/pages/change_password_page.dart) to pass appropriate Vietnamese label
- [x] T022 [P] [US5] Localize payment text strings in [profile_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/presentation/pages/profile_page.dart) (VIP payment prompt, VIP activation message)
- [x] T023 [P] [US5] Localize all camera scan feedback text strings and buttons in [ai_onboarding_body_scan_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/onboarding/presentation/pages/ai_onboarding_body_scan_page.dart)
- [x] T024 [P] [US5] Localize body analysis text strings and buttons in [ai_body_analysis_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/ai/presentation/pages/ai_body_analysis_page.dart)

**Checkpoint**: User Story 5 functional. 100% of these screens are localized in accented Vietnamese.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Code cleanup and validation

- [/] T025 Run backend integration tests to check user creation and onboarding reset flow
- [/] T026 Perform manual verification on emulator/simulator for onboarding, profile editing, and theme adaptation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete
