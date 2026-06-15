# Tasks: Premium AI Speed Dial & Gated VIP Access

## Phase 1: Core Widgets

- [x] T001 Create shared `FlashyVipRequiredModal` in `lib/core/widgets/flashy_vip_required_modal.dart`
- [x] T002 Create reusable `PremiumAiSpeedDial` in `lib/core/widgets/premium_ai_speed_dial.dart`

## Phase 2: Feature & Routing Updates

- [x] T003 Support `initialTab` in `AiCoachPage` constructor in `lib/features/ai/presentation/pages/ai_coach_page.dart`
- [x] T004 Feed query parameter `tab` to `AiCoachPage` in `lib/core/router/app_router.dart`
- [x] T005 Update `workout_page.dart` to use `PremiumAiSpeedDial` and `FlashyVipRequiredModal`
- [x] T006 Update `nutrition_page.dart` to use `PremiumAiSpeedDial` and `FlashyVipRequiredModal`

## Phase 3: Validation

- [x] T007 Run `flutter analyze` to ensure compilation correctness
