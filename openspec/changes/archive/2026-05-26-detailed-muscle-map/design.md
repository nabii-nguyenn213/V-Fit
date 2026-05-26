## Context

Trình hiển thị bản đồ cơ bắp hiện tại dùng `InteractiveMuscleModelViewer` vẽ các đa giác hình học trừu tượng (3D blocky) không đáp ứng được yêu cầu về thẩm mỹ trực quan và độ chi tiết giải phẫu học cơ bắp. Dự án đã có sẵn hai tệp SVG giải phẫu học chi tiết (`anterior.svg` và `posterior.svg`) và một widget `InteractiveMuscleMap` để hiển thị bản đồ này nhưng hiện không được kích hoạt sử dụng trong giao diện thư viện bài tập.

## Goals / Non-Goals

**Goals:**
- Sử dụng bản đồ cơ bắp SVG giải phẫu học chi tiết trong trang Thư viện bài tập (`exercise_library_page.dart`).
- Đảm bảo tương tác chạm (hit-test) vào từng nhóm cơ trên bản đồ SVG hoạt động chính xác, mượt mà và hiển thị highlight cùng thông tin badge số lượng bài tập tương ứng.
- Đảm bảo hiệu năng tải và vẽ SVG tối ưu trên thiết bị di động.

**Non-Goals:**
- Không hỗ trợ xoay 360 độ liên tục dạng 3D (thay vào đó sử dụng tính năng lật Mặt trước / Mặt sau dạng 2D trực quan).
- Không thay đổi cấu trúc dữ liệu của các nhóm cơ từ Backend.

## Decisions

### Quyết định 1: Kích hoạt lại và tối ưu hóa `InteractiveMuscleMap` thay vì `InteractiveMuscleModelViewer`
- **Lựa chọn:** Sử dụng `InteractiveMuscleMap` (nạp SVG động bằng `flutter_svg`, phân tích cú pháp XML để lấy các vector path bằng `xml` và `path_drawing` để phục vụ việc hit-test và vẽ highlight trên Canvas).
- **Lý do:**
  - Bản đồ SVG chứa đầy đủ chi tiết giải phẫu học (anatomy) gồm thớ cơ, phân khu cơ bắp đẹp mắt.
  - Việc phân tích XML và vẽ lại trên Canvas đảm bảo hit-test chính xác đến từng pixel của path phức tạp mà không bị phụ thuộc vào bounding box chữ nhật.
  - Tránh việc phải tích hợp các engine 3D nặng nề như ThreeJS/Filament hoặc Rive/Lottie phức tạp.

## Risks / Trade-offs

- **[Risk] Hiệu năng phân tích XML của SVG chậm khi khởi chạy lần đầu:**
  - *Mitigation:* `InteractiveMuscleMap` tải dữ liệu SVG thông qua một luồng bất tuần tự (`Future.wait`/`rootBundle.loadString`) và cache lại kết quả phân tích trong suốt vòng đời của State. Dữ liệu chỉ được tải một lần duy nhất.
- **[Risk] Các phần tử SVG không khớp ID với danh sách nhóm cơ từ Backend:**
  - *Mitigation:* Đảm bảo các `id` trong SVG (`shoulders`, `chest`, `biceps`, `triceps`, `core-cardio`, `legs`, `back`) khớp hoàn toàn với `id` của `MuscleGroup` trong Flutter Domain Model.
