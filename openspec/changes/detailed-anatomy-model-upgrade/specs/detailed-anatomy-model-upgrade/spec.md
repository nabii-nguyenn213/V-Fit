# Specification for Detailed Anatomy Model Upgrade

## Summary
Nâng cấp giao diện trực quan của `InteractiveMuscleModelViewer` để vẽ hình ảnh cơ thể và cơ bắp với độ chi tiết giải phẫu học cao (medical anatomy detail), xoay chuyển 3D mượt mà 360 độ.

## Verification Spec

### Automated Tests
- Chạy `flutter analyze` để xác minh không có lỗi cú pháp hoặc lỗi phân tích trong tệp `interactive_muscle_model_viewer.dart`.
- Chạy `flutter test` nếu có kiểm thử tương đương.

### Manual Verification
- Chạy ứng dụng trên thiết bị ảo hoặc thực tế.
- Điều hướng đến thư viện bài tập và mở bản đồ cơ bắp 3D.
- Xác nhận:
  - Khung xương quai xanh (collarbones) nổi bật ở mặt trước, cột sống (spine) phân đốt rõ rệt ở mặt sau.
  - Các khối cơ có các vân thớ cơ (striations) song song/hướng tâm chuyển động lập thể khi xoay mô hình.
  - Các đầu gân bám (fascicle) có màu kem nhạt/sáng bóng, tạo hiệu ứng chuyển tiếp từ sợi cơ sang các khớp xương y hệt ảnh thiết kế mẫu.
  - Các khớp xương khuỷu tay và đầu gối có hình dáng tròn lõm giải phẫu học rõ ràng hơn.
  - Vùng đầu hiển thị góc nghiêng (tai, mũi, cằm) khi xoay sang hai bên.
  - Mô hình xoay chuyển mượt mà ở tốc độ 60fps khi kéo/drag chuột hoặc ngón tay.
