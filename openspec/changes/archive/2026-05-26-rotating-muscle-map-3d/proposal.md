## Why

Người dùng mong muốn nâng cấp chức năng bản đồ cơ trong phần Luyện tập của ứng dụng V-FIT:
1. Bản đồ cơ cần hỗ trợ xoay 360 độ (vuốt ngang hoặc dùng thanh trượt) để có thể xem mô hình cơ bắp từ mọi hướng một cách trực quan và hiện đại.
2. Khi tương tác chạm vào mô hình cơ bắp, hệ thống cần hỗ trợ lọc chi tiết đến từng nhóm cơ phụ (sub-groups). Ví dụ: Khi người dùng bấm vào cơ vai trước, hệ thống phải mở rộng và tập trung vào nhóm bài tập vai trước (`front-delt`), chứ không hiển thị chung chung cả nhóm cơ vai (`shoulders`).

## What Changes

- Chuyển đổi component hiển thị bản đồ cơ trong `exercise_library_page.dart` từ `InteractiveMuscleMap` (SVG 2D tĩnh) sang `InteractiveMuscleModelViewer` (3D Custom Paint xoay 360 độ).
- Cập nhật cách điều hướng từ `ExerciseLibraryPage` sang `ExerciseGroupDetailPage`: khi người dùng chạm chọn một vùng cơ trên mô hình 3D, lấy thông tin `groupId` và `subGroupId` của vùng cơ đó và truyền vào `ExerciseGroupDetailPage(group: group, initialSubGroupId: subGroupId)`.
- Định vị chính xác các tọa độ 3D và thuật toán hit-test các nhóm cơ phụ trong `interactive_muscle_model_viewer.dart` để đảm bảo độ nhạy và chính xác cao khi chạm.

## Capabilities

### New Capabilities
- `rotating-3d-anatomical-muscle-map`: Bản đồ cơ 3D xoay 360 độ với tương tác chạm lọc chi tiết nhóm cơ phụ.

### Modified Capabilities
- `detailed-anatomical-muscle-map`: Bản đồ SVG 2D sẽ được thay thế bằng bản đồ 3D tương tác.

## Impact

- **Frontend**:
  - `VFIT_Fontend/lib/features/exercise_library/presentation/pages/exercise_library_page.dart` (Thay thế Widget và cập nhật hàm callback điều hướng).
  - `VFIT_Fontend/lib/features/exercise_library/presentation/widgets/interactive_muscle_model_viewer.dart` (Kích hoạt và tối ưu hóa vẽ, tương tác 3D).
