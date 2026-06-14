# Tasks: AI Planners Integration

## Phase 1: Setup
- [ ] T001 Khởi tạo cấu trúc các tệp tin trong `specs/009-integrate-ai-planners/`
- [ ] T002 Cập nhật cấu hình Spec Kit trỏ đến tính năng mới

## Phase 2: Data & Repository Layer
- [ ] T003 [US1] Xây dựng `AiPlannersRepository` xử lý các endpoint của FastAPI `/workout-planner/`, `/meal-planner/` và `/food-scanner/text`
- [ ] T004 [US1] Xây dựng các Providers quản lý trạng thái Riverpod cho Workout, Meal và Food Scanner

## Phase 3: Presentation & UI Layer
- [ ] T005 [US1] Xây dựng màn hình UI `AiWorkoutPlannerPage` hiển thị lịch tập tuần dạng Glassmorphism
- [ ] T006 [US2] Xây dựng màn hình UI `AiMealPlannerPage` hiển thị thực đơn và Macro dinh dưỡng hàng ngày
- [ ] T007 [US3] Tích hợp AI Food Text Scanner vào giao diện nhật ký ăn uống

## Phase 4: Polish & Integration Gates
- [ ] T008 Thiết lập định tuyến Router (GoRouter) cho các trang Planner mới
- [ ] T009 Xác thực chất lượng biên dịch mã nguồn qua Dart Analyze
