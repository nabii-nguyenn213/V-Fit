# Kế Hoạch Triển Khai: Tối ưu hoá & Sửa lỗi đồng bộ dữ liệu AI Planner

Tài liệu này chi tiết phương án giải quyết lỗi không cập nhật ngay lập tức giao diện "Không gian tập luyện" và "Workspace dinh dưỡng" khi người dùng nhấn "Áp dụng" kế hoạch AI.

## Các thay đổi đề xuất (Proposed Changes)

---

### 1. Tầng Dữ liệu (Data Layer)

#### [MODIFY] [personalized_workout_repository.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/personalized_workout/domain/repositories/personalized_workout_repository.dart)
- Bổ sung `Future<void> revertAiPlan();` vào interface để hỗ trợ hủy áp dụng lịch AI.

#### [MODIFY] [personalized_workout_repository_impl.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/personalized_workout/data/repositories/personalized_workout_repository_impl.dart)
- Khai báo Riverpod provider `isAiWorkoutPlanAppliedProvider` để lắng nghe cờ AI áp dụng cục bộ.
- Triển khai `revertAiPlan()` gọi `localDataSource.setAiApplied(false)`.
- Cập nhật `getPlan({bool forceRefresh = false})` để reset cờ AI áp dụng khi kéo xuống làm mới (`forceRefresh == true`).

---

### 2. Tầng Giao diện (Presentation Layer)

#### [MODIFY] [ai_coach_sheet.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/ai/presentation/widgets/ai_coach_sheet.dart)
- Sau khi gọi `applyAiPlan(personalizedWorkout)`, thêm `ref.invalidate(isAiWorkoutPlanAppliedProvider);`.
- Loại bỏ lệnh gọi BLoC thủ công vì BLoC sẽ tự động được làm mới phản ứng nhờ Key của `MultiBlocProvider`.

#### [MODIFY] [ai_meal_sheet.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/ai/presentation/widgets/ai_meal_sheet.dart)
- Sau khi lưu thực đơn thành công, thêm `ref.invalidate(isAiMealPlanAppliedProvider);` và `ref.invalidate(aiMealPlanProvider);` để các widget đang xem tự động cập nhật.

#### [MODIFY] [workout_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/workout/presentation/pages/workout_page.dart)
- Lắng nghe `isAiWorkoutPlanAppliedProvider` trong `_WorkoutPageState`.
- Thêm cờ `isAiApplied` vào `ValueKey` của `MultiBlocProvider` (`key: ValueKey('${user?.goalType}_$isAiApplied')`).
- Cập nhật hàm `_refresh(context)` gọi `ref.invalidate(isAiWorkoutPlanAppliedProvider)` trước khi reload.
- Thêm thông báo `_InfoNote` ở đầu trang lịch cá nhân khi đang dùng lịch AI kèm nút "Hủy áp dụng".

## Kế hoạch Nghiệm thu (Verification Plan)

### Kiểm thử Thủ công (Manual Verification)
1. **Lập lịch tập AI**: Tạo và áp dụng lịch tập -> Xác nhận màn hình Workout cập nhật lập tức -> Bấm "Hủy áp dụng" để chuyển về lịch mặc định.
2. **Thực đơn dinh dưỡng AI**: Tạo và áp dụng thực đơn -> Xác nhận màn hình Dinh dưỡng cập nhật lập tức -> Bấm "Hủy áp dụng" (dấu x) để chuyển về danh sách món ăn phổ biến.
