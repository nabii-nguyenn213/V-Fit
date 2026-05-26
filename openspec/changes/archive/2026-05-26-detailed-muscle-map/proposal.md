## Why

Bản đồ cơ hiện tại hiển thị bằng cách vẽ các khối hình học trừu tượng (3D blocky model) trong `InteractiveMuscleModelViewer`. Cách vẽ này quá đơn giản, thô sơ và thiếu tính thẩm mỹ trực quan, không hiển thị rõ ràng và chi tiết cấu trúc giải phẫu cơ bắp thực tế (như các thớ cơ, hình dạng cơ bắp thực tế ở mặt trước/mặt sau).

Người dùng mong muốn có bản đồ cơ bắp chi tiết và thực tế hơn giống như các sơ đồ giải phẫu học cơ bắp chuyên nghiệp để tăng trải nghiệm trực quan khi tương tác chọn bài tập theo nhóm cơ.

## What Changes

- Thay thế `InteractiveMuscleModelViewer` bằng component `InteractiveMuscleMap` sử dụng bản đồ SVG giải phẫu học chi tiết (`anterior.svg` và `posterior.svg`).
- Cập nhật trang `ExerciseLibraryPage` (`exercise_library_page.dart`) để tích hợp và hiển thị `InteractiveMuscleMap` thay cho trình xem khối 3D cũ.
- Đảm bảo tính tương tác mượt mà: khi chạm vào từng nhóm cơ chi tiết trên SVG (như vai, ngực, tay trước, tay sau, bụng, đùi/chân), ứng dụng sẽ highlight nhóm cơ đó và mở danh sách bài tập tương ứng.
- Loại bỏ hoặc vô hiệu hóa slider xoay 360 độ (do bản đồ SVG 2D giải phẫu chỉ cần hai trạng thái trực quan là Mặt trước và Mặt sau).

## Capabilities

### New Capabilities
- `detailed-anatomical-muscle-map`: Bản đồ cơ giải phẫu học độ chi tiết cao hỗ trợ chọn nhóm cơ tương tác trực quan qua SVG.

### Modified Capabilities
<!-- Trống vì chưa có specs nào trước đó trong thư mục openspec/specs/ -->

## Impact

- **Frontend**:
  - `VFIT_Fontend/lib/features/exercise_library/presentation/pages/exercise_library_page.dart` (Cập nhật để dùng `InteractiveMuscleMap`)
  - `VFIT_Fontend/lib/features/exercise_library/presentation/widgets/interactive_muscle_map.dart` (Xác minh và đảm bảo hoạt động đúng)
  - `VFIT_Fontend/assets/muscle_map/anterior.svg` & `posterior.svg` (Các tệp SVG nguồn giải phẫu học chi tiết)
