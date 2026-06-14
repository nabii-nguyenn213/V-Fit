# Tasks: AI Planners & Food Scanner Integration

**Input**: Design documents from `/specs/009-integrate-ai-planners/`

**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Khởi tạo cấu trúc các tệp tin trong `specs/009-integrate-ai-planners/`
- [x] T002 Cập nhật cấu hình Spec Kit trỏ đến tính năng mới

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Bổ sung phương thức `revertAiPlan` vào interface `lib/features/personalized_workout/domain/repositories/personalized_workout_repository.dart` và khai báo Riverpod provider `isAiWorkoutPlanAppliedProvider` trong `lib/features/personalized_workout/data/repositories/personalized_workout_repository_impl.dart`
- [x] T004 [P] Xác nhận khai báo Riverpod providers `isAiMealPlanAppliedProvider` và `aiMealPlanProvider` trong `lib/features/nutrition/data/repositories/nutrition_repository.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - AI Workout Planner (Priority: P1) 🎯 MVP

**Goal**: Lập lịch tập cá nhân hoá bằng AI, đồng bộ cập nhật UI lập tức khi người dùng ấn áp dụng hoặc hủy áp dụng lịch AI.

**Independent Test**: Áp dụng lịch tập AI mới -> Màn hình "Không gian tập luyện" cập nhật lập tức mà không cần load lại ứng dụng. Nhấn "Hủy áp dụng" -> Lịch tập mặc định được phục hồi tức thì.

### Implementation for User Story 1

- [x] T005 [US1] Triển khai phương thức `revertAiPlan` và cập nhật hàm `getPlan` để reset cờ AI khi có tham số `forceRefresh == true` tại `lib/features/personalized_workout/data/repositories/personalized_workout_repository_impl.dart`
- [x] T006 [US1] Tích hợp invalidate `isAiWorkoutPlanAppliedProvider` sau khi áp dụng lịch AI thành công tại `lib/features/ai/presentation/widgets/ai_coach_sheet.dart`
- [x] T007 [US1] Lắng nghe `isAiWorkoutPlanAppliedProvider` trong `_WorkoutPageState` và bổ sung cờ `isAiApplied` vào `ValueKey` của `MultiBlocProvider` tại `lib/features/workout/presentation/pages/workout_page.dart`
- [x] T008 [US1] Thêm thông báo `_InfoNote` có nút "Hủy áp dụng" ở đầu danh sách tập luyện khi đang kích hoạt lịch AI tại `lib/features/workout/presentation/pages/workout_page.dart`

**Checkpoint**: User Story 1 (Workout AI Sync) hoạt động độc lập hoàn chỉnh.

---

## Phase 4: User Story 2 - AI Meal Planner (Priority: P1)

**Goal**: Thiết lập thực đơn tuần AI, đồng bộ cập nhật UI lập tức khi người dùng nhấn áp dụng hoặc hủy áp dụng.

**Independent Test**: Nhấn áp dụng thực đơn tuần AI -> Màn hình dinh dưỡng cập nhật sang giao diện thực đơn 7 ngày AI tức thì. Bấm nút hủy áp dụng (dấu x) -> Màn hình chuyển về danh sách món ăn phổ biến ngay lập tức.

### Implementation for User Story 2

- [x] T009 [US2] Tích hợp invalidate `isAiMealPlanAppliedProvider` và `aiMealPlanProvider` sau khi áp dụng thực đơn tuần AI thành công tại `lib/features/ai/presentation/widgets/ai_meal_sheet.dart`
- [x] T010 [US2] Cập nhật giao diện `_buildAiWeeklyPlanSection` và cờ lắng nghe Riverpod trong `lib/features/nutrition/presentation/pages/nutrition_page.dart`
- [x] T011 [US2] Xác nhận nút hủy áp dụng thực đơn tuần AI hoạt động và làm mới UI bằng Riverpod invalidation tại `lib/features/nutrition/presentation/pages/nutrition_page.dart`

**Checkpoint**: User Story 2 (Meal AI Sync) hoạt động độc lập hoàn chỉnh.

---

## Phase 5: User Story 3 - AI Food Scanner by Text (Priority: P2)

**Goal**: Ước lượng Calorie và dinh dưỡng bằng cách nhập mô tả văn bản.

**Independent Test**: Nhập mô tả "Phở bò" -> Nhận được kết quả Calo và Macros và có thể lưu vào nhật ký ăn uống.

### Implementation for User Story 3

- [x] T012 [P] [US3] Khai báo và tích hợp API endpoint `/food-scanner/text` vào repo trong `lib/features/nutrition/data/repositories/nutrition_repository.dart`
- [x] T013 [US3] Thiết lập ô nhập văn bản và nút "Ước lượng dinh dưỡng" trong giao diện nhật ký ăn uống tại `lib/features/nutrition/presentation/pages/nutrition_page.dart`

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T014 Run `dart analyze` để kiểm tra toàn vẹn mã nguồn
- [x] T015 Chạy thử liên thông (E2E) các luồng tạo và hủy lịch tập/thực đơn AI

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Có thể bắt đầu ngay.
- **Foundational (Phase 2)**: Cần hoàn thành Setup trước.
- **User Stories (Phases 3+)**: Hoạt động song song sau khi hoàn tất Foundational.
- **Polish (Phase N)**: Bắt đầu sau khi hoàn thành tất cả các User Stories mong muốn.

### Parallel Opportunities

- T003 và T004 có thể thực hiện song song (ở các module độc lập).
- User Story 1 (Tập luyện) và User Story 2 (Dinh dưỡng) có thể triển khai song song.
