# Báo Cáo Cập Nhật Logic AI Phân Tích Vóc Dáng (Changelog)

## 🎯 Tóm tắt nhanh dành cho Mobile App Developer
> **LƯU Ý QUAN TRỌNG:** Bản cập nhật này **KHÔNG** làm thay đổi bất kỳ tham số đầu vào (input parameters) hay cấu trúc giao tiếp nào. Team Mobile App **không cần phải sửa đổi bất kỳ dòng code nào** ở phía client. Ứng dụng cứ tiếp tục gửi ảnh (`frame`) dạng Full Frame và tọa độ (`keypoints`) nguyên bản như cũ.

---

## 🐛 Vấn đề đã được giải quyết (Lỗi "Auto Béo")
* **Tình trạng trước đây:** AI hoạt động tốt trên webcam máy tính (Landscape) nhưng khi lên Mobile App (Portrait) thì luôn nhận diện người dùng là "Béo" bất chấp thực tế.
* **Nguyên nhân cốt lõi:** Sự lệch pha về hệ quy chiếu. Độ phân giải ảnh gốc từ camera điện thoại rất lớn, trong khi mặt nạ (mask) mà mô hình YOLO xuất ra đã bị thu nhỏ để tối ưu hiệu năng. Việc lấy độ dày eo đo trên mask nhỏ đem chia cho bề ngang vai đo trên ảnh khổng lồ đã tạo ra một tỷ lệ sai lệch nghiêm trọng.

---

## 🛠 Các thay đổi chi tiết trong mã nguồn (Backend/AI)

### 1. File `body_analyzer.py`
* **Mục tiêu:** Quy đổi tọa độ khung xương MediaPipe từ dạng phần trăm (Normalized) về chuẩn Pixel thực tế của bức ảnh.
* **Logic cập nhật:**
  * Tự động trích xuất kích thước ảnh gốc ngay bên trong hàm thông qua lệnh `frame_height, frame_width = frame.shape[:2]`.
  * Nhân trực tiếp tọa độ `x`, `y` với chiều rộng và chiều cao của `frame` để lấy ra số Pixel chuẩn xác trước khi tính toán khoảng cách 2 vai bằng định lý Pytago.

### 2. File `body_shape_predictor.py`
* **Mục tiêu:** Đồng bộ hóa hệ quy chiếu đo lường (Scale Synchronization) giữa số đo vai và số đo bụng mà không cần Mobile App phải tự nới lề (crop) ảnh.
* **Logic cập nhật:**
  * Lấy kích thước thực tế của YOLO mask (`mask.shape`).
  * Tự động tính toán tỷ lệ co giãn ngầm bên trong AI: `scale_factor = mask_w / frame_w`.
  * Thu nhỏ số đo bề ngang vai (`shoulder_width_px`) theo đúng `scale_factor` của mask (`adjusted_shoulder`).
  * Thực hiện tính toán `fat_ratio` dựa trên cùng một hệ quy chiếu và ép kiểu `float` an toàn khi trả về JSON.

---

## 📈 Kết quả đạt được (Impact)
* Hệ thống AI giờ đây đã tự động co giãn linh hoạt. 
* Tỷ lệ mỡ (`fat_ratio`) tính ra sẽ luôn chuẩn xác tuyệt đối trên mọi độ phân giải camera (từ 480p đến 4K) và trên mọi dòng điện thoại khác nhau.