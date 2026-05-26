## Why

Mô hình 3D cơ bắp hiện tại trong `InteractiveMuscleModelViewer` quá đơn giản, thô sơ và mang tính hình học trừu tượng (chỉ có các hình khối phẳng, đơn sắc), chưa thể hiện được chi tiết giải phẫu học cơ bắp thực tế của cơ thể con người (như các thớ cơ dọc, gân, xương quai xanh, xương sườn, xương bánh chè, cơ mông, cột sống, cấu trúc khuỷu tay,...).

Người dùng đã cung cấp 4 bức ảnh minh họa giải phẫu học cơ bắp chuyên nghiệp có độ chi tiết cao và yêu cầu nâng cấp giao diện mô hình 3D xoay 360 độ để đạt được độ chi tiết và thẩm mỹ tương tự (hiệu ứng 3D khối cơ nổi, thớ cơ rõ rệt, có điểm bám gân trắng và viền khối y khoa cao cấp).

## What Changes

- Nâng cấp `_MuscleModelPainter` trong `interactive_muscle_model_viewer.dart` để vẽ chi tiết giải phẫu học y tế:
  - Thêm hiệu ứng vẽ các thớ cơ (striations) chi tiết chạy dọc theo hướng của từng bó cơ bằng cách sử dụng `canvas.clipPath(path)` kết hợp vẽ các đường sọc mảnh phản chiếu ánh sáng.
  - Vẽ thêm chi tiết xương quai xanh (collarbones), dải xương sườn (ribcage), rãnh bụng chữ V (Adonis belt) ở mặt trước.
  - Vẽ chi tiết cột sống (vertebral spine), phân chia cơ mông (gluteal cleft) ở mặt sau.
  - Vẽ chi tiết vùng đầu/mặt (bản vẽ nghiêng chân dung khi xoay góc) và các khớp xương khuỷu tay, xương đầu gối (patella).
  - Tối ưu hóa màu sắc đổ bóng (gradients) trên nền mô hình để tạo độ sâu 3D chân thực, sang trọng.

## Capabilities

### New Capabilities
- `detailed-3d-anatomy-rendering`: Vẽ chi tiết thớ cơ giải phẫu học đa hướng trên mô hình xoay 360 độ.

### Modified Capabilities
- `rotating-3d-anatomical-muscle-map`: Tích hợp hiển thị thớ cơ chi tiết vào mô hình 3D xoay hiện tại.

## Impact

- **Frontend**:
  - `VFIT_Fontend/lib/features/exercise_library/presentation/widgets/interactive_muscle_model_viewer.dart` (Nâng cấp toàn bộ CustomPainter vẽ chi tiết cơ thể).
