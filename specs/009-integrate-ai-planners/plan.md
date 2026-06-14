# Kế Hoạch Triển Khai: Tích hợp AI Planners & Food Scanner

**Nhánh**: `007-connect-ai-web2api` | **Ngày**: 2026-06-15 | **Đặc tả**: [spec.md](file:///d:/EXE_PRM/specs/009-integrate-ai-planners/spec.md)

## Tóm tắt (Summary)

Tích hợp 3 Chatbot AI Planners từ hệ thống FastAPI (`RecommendationSystem`) vào ứng dụng Flutter bao gồm: Workout Planner (Lên lịch tập), Meal Planner (Lên thực đơn ăn uống), và Food Scanner Text (Phân tích dinh dưỡng món ăn bằng văn bản).

## Cấu trúc Dự án (Project Structure)

### Tầng Dữ liệu (Data Layer)
- **Repository mới**: `VFIT_Fontend/lib/features/ai/data/repositories/ai_planners_repository.dart`
  - Đảm nhiệm việc gửi yêu cầu POST đến `/api/v1/workout-planner/`, `/api/v1/meal-planner/`, và `/api/v1/food-scanner/text`.
  - Sử dụng `aiDioProvider` để tự động định phối kết nối (emulator vs thiết bị thật).

### Tầng Trình bày (Presentation Layer)
- **Providers mới**:
  - `ai_workout_planner_provider.dart`
  - `ai_meal_planner_provider.dart`
  - `ai_food_scanner_provider.dart`
- **Màn hình giao diện mới (UI Pages)**:
  - `lib/features/ai/presentation/pages/ai_workout_planner_page.dart`: Form nhập số ngày tập, trình độ và hiển thị lịch trình tuần.
  - `lib/features/ai/presentation/pages/ai_meal_planner_page.dart`: Chọn tần suất bữa ăn và hiển thị Macro (Calories, Carbs, Protein, Fat).
  - Tích hợp thêm hộp thoại nhập text vào nhật ký ăn uống hiện tại để gọi Food Text Scanner.

---

## Chi Tiết Các Bước Triển Khai (Proposed Changes)

### Tầng Dữ liệu & Provider

#### [NEW] [ai_planners_repository.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/ai/data/repositories/ai_planners_repository.dart)
Tạo repository chứa các hàm gọi API đến các dịch vụ Planners:
- `Future<Map<String, dynamic>> createWorkoutPlan(...)`
- `Future<Map<String, dynamic>> createMealPlan(...)`
- `Future<Map<String, dynamic>> scanFoodText(...)`

#### [NEW] [ai_workout_planner_provider.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/ai/presentation/providers/ai_workout_planner_provider.dart)
Quản lý trạng thái tải (loading), kết quả lịch tập dạng JSON và lưu vào Local Cache nếu cần.

#### [NEW] [ai_meal_planner_provider.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/ai/presentation/providers/ai_meal_planner_provider.dart)
Quản lý trạng thái gọi thực đơn AI và phân bổ Calories/Macros.

### Giao Diện Người Dùng (UI Layout)

#### [NEW] [ai_workout_planner_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/ai/presentation/pages/ai_workout_planner_page.dart)
- Giao diện Glassmorphism hiển thị kế hoạch tập luyện hàng tuần.
- Tự động lấy body metrics hiện tại của người dùng.

#### [NEW] [ai_meal_planner_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/ai/presentation/pages/ai_meal_planner_page.dart)
- Hiển thị lượng Calorie khuyến nghị mỗi ngày kèm biểu đồ phân bổ các nhóm chất.

---

## Kế hoạch Nghiệm thu (Verification Plan)

### Kiểm thử Thủ công (Manual Verification)
1. Mở trang AI Planners trên Flutter App.
2. Kiểm tra chặn VIP Gate: Nếu tài khoản thường, hệ thống yêu cầu nâng cấp VIP.
3. Nếu tài khoản VIP, chọn thông số và bấm "Tạo kế hoạch".
4. Xác nhận kết quả hiển thị chính xác lịch tập/thực đơn từ API FastAPI trả về.
