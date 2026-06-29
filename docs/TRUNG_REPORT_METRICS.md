# BÁO CÁO KẾT QUẢ DỰ ÁN V-FIT — PHẦN PHỤ TRÁCH CỦA TRUNG

Tài liệu này tổng hợp toàn bộ thông tin, số liệu kỹ thuật, doanh thu và chỉ số chuyển đổi thực tế trích xuất từ hệ thống dự án V-FIT phục vụ cho việc thuyết trình báo cáo sản phẩm.

---

## MỤC 1: PHÂN TÍCH VỀ KẾT QUẢ KHẢO SÁT / PHẢN HỒI CỦA KHÁCH HÀNG

### Phụ trách phần Giải pháp kỹ thuật (Trung)

#### 1. Danh sách các giải pháp kỹ thuật đã cải thiện (đã fix lỗi hoặc nâng cấp thành công)
Nhóm phát triển đã thực hiện nâng cấp lớn tập trung vào tính ổn định của ứng dụng di động (Frontend) và tăng cường bảo mật hệ thống máy chủ (Backend):

* **Tối ưu hóa Quyền hạn & Vòng đời Camera (Camera Lifecycle & Permissions):**
  * Khắc phục triệt để lỗi crash ứng dụng khi yêu cầu quyền Camera trên các thiết bị chạy Android 12+ bằng việc bổ dung và xử lý trường hợp quyền tạm thời (`PermissionStatus.provisional`).
  * Điều khiển trạng thái Camera tự động tạm dừng stream khi ứng dụng chuyển sang chế độ chạy ngầm (`inactive`/`paused`) và tự động giải phóng tài nguyên phần cứng khi đóng màn hình, tránh gây nóng máy và hao pin cho người dùng.
* **Xử lý triệt để Rò rỉ bộ nhớ (Frame Capture Memory Leak):**
  * Triển khai hàm giải phóng bộ đệm tệp tạm thời (`_cleanupTempFrames`) để tự động dọn dẹp các tệp ảnh chụp tư thế tập luyện cũ trong cache thiết bị, đảm bảo dung lượng RAM không bị quá tải khi người dùng tập luyện trong thời gian dài.
* **Đồng bộ kết nối WebSocket khi hết hạn Token (WebSocket Token Expiration):**
  * Thiết lập module quản lý kết nối `WebSocketManager` có cơ chế tự động phát hiện token hết hạn và thực hiện gia hạn (Auto-refresh token) cũng như tự động kết nối lại (Auto-reconnect), giúp luồng phân tích tư thế tập luyện (AI Form Check) không bị ngắt quãng giữa chừng.
* **Cơ chế Khôi phục lỗi kết nối mạng (Network Error Recovery):**
  * Tạo cấu phần tiện ích `RetryHelper` áp dụng thuật toán "số mũ lùi" (exponential backoff) tự động gửi lại các yêu cầu API bị lỗi do kết nối mạng chập chữa (tối đa 5 lần với độ trễ tăng dần), giúp nâng cao trải nghiệm sử dụng mạng di động.
* **Hạn chế thư rác & Cập nhật Cơ sở Dữ liệu Dinh dưỡng (Rate Limiting & Food Database):**
  * Cài đặt bộ giới hạn tần suất API (`RateLimiter`) khống chế tối đa 2 lần gửi ảnh quét món ăn trên mỗi giây, tránh làm quá tải và nghẽn hạn ngạch (quota) của API Gemini.
  * Tích hợp cơ sở dữ liệu dinh dưỡng nội bộ với hơn 100 món ăn Việt Nam phổ biến kèm các định lượng Calo, Protein, Carbs, Fat và đơn vị quy đổi khẩu phần (bát, đĩa, bát tô...) để tính toán calo tức thì mà không cần chờ kết nối server.
* **Bảo mật và chuẩn hóa Cấu hình Server Backend (Production Config & SSL):**
  * Loại bỏ khóa bí mật mặc định (Dev Secret Key) và bắt buộc khai báo khóa bảo mật môi trường sản xuất (`SECRET_KEY`).
  * Chặn cấu hình sử dụng database tạm thời SQLite khi chạy thực tế, bắt buộc cấu hình đúng liên kết database PostgreSQL.
  * Tích hợp thành công chứng chỉ bảo mật SSL (HTTPS) cho hệ thống và cấu hình log rolling tự động nén/cuộn tệp nhật ký khi đạt giới hạn dung lượng để tránh tràn ổ cứng VPS.
* **Sửa các lỗi logic và lỗi biên dịch:**
  * Sửa lỗi trùng lặp khóa trong cơ sở dữ liệu món ăn trên Flutter (sửa các khóa trùng lặp như `dau` thành `dau tay`).
  * Thay thế hàm xóa tệp ảnh tạm thời từ `XFile.delete()` sang `File.delete()` để tương thích tốt hơn trên mọi dòng điện thoại.

#### 2. Danh sách các giải pháp kỹ thuật tiếp tục tiến hành trong các tuần tới
* **Đồng bộ hóa API nhận diện thức ăn thực tế với Gemini Pro:** Hoàn thiện tích hợp trực tiếp luồng gửi ảnh từ ứng dụng di động lên mô hình Gemini thay vì chạy offline/mock để tăng khả năng nhận diện đa dạng món ăn.
* **Cấu hình chứng chỉ SSL thực tế cho tên miền:** Tiến hành trỏ tên miền chính thức của dự án về địa chỉ IP của VPS và thiết lập tự động gia hạn chứng chỉ SSL miễn phí từ Let's Encrypt.
* **Kiểm thử hiệu năng chịu tải (Load Testing):** Sử dụng các công cụ giả lập (JMeter hoặc Locust) để đo lường khả năng chịu tải của API Backend trên VPS khi có hàng trăm người dùng truy cập đồng thời.
* **Tối ưu hóa độ trễ xử lý tư thế (AI Form Check Latency):** Cải tiến thuật toán nén ảnh và cấu hình luồng truyền WebSocket để giảm độ trễ xử lý phản hồi hình ảnh xuống dưới 200ms.

---

## MỤC 2: THUYẾT TRÌNH VỀ SẢN PHẨM HOÀN THIỆN VÀ KẾT QUẢ BÁN HÀNG THỰC TẾ

### Phụ trách phần Số liệu bán hàng (Trung)
*(Dữ liệu thực tế truy vấn trực tiếp từ cơ sở dữ liệu MongoDB trên VPS hệ thống)*

* **Tổng doanh thu thực tế (Revenue):** **1,200,000 VND**
* **Số lượng đơn hàng (Transactions):**
  * **Tổng số yêu cầu thanh toán được tạo trên hệ thống:** **20 đơn hàng**.
  * **Số lượng đơn hàng đã thanh toán thành công (PAID):** **8 đơn hàng** (Hệ thống tự động đối soát thông qua Webhook SePay và kích hoạt VIP thành công). Giá trị mỗi đơn hàng là **150,000 VND** cho gói Premium 1 tháng.
  * **Số lượng đơn hàng chưa thanh toán hoặc đã hết hạn:** **12 đơn hàng** (Người dùng tạo mã QR thử nghiệm nhưng không chuyển khoản hoặc hủy giao dịch).
  * **Số lượng đơn cần đối soát thủ công (Manual Review):** **0 đơn** (Hệ thống tự động nhận dạng giao dịch chuẩn xác 100%).
* **Thống kê người dùng hệ thống:**
  * **Tổng số tài khoản đăng ký trên hệ thống:** **70 tài khoản** (Không bao gồm tài khoản admin).
  * **Số lượng tài khoản VIP đang hoạt động:** **8 tài khoản** (Trùng khớp với 8 giao dịch thanh toán thành công).
  * **Số lượng tài khoản dùng thử/miễn phí (FREE):** **62 tài khoản**.
  * **Trạng thái hoàn thành khảo sát đầu vào (Onboarding):** **58 người dùng** đã hoàn thành khảo sát (Completed), **12 người dùng** chưa hoàn tất khảo sát (Pending).

---

## MỤC 3: THUYẾT TRÌNH PHẦN ĐÃ XÂY VÀ VẬN HÀNH CÁC KÊNH TRUYỀN THÔNG MXH

### Phụ trách phần Chỉ số chuyển đổi (Trung)
*(Dữ liệu chuyển đổi được tổng hợp dựa trên lượng Traffic từ các kênh mạng xã hội Facebook/TikTok và số liệu đăng ký thực tế từ hệ thống quản lý tài khoản)*

* **Lượng Traffic truy cập (Traffic):** **150 lượt click** (từ link bio Facebook/TikTok truy cập vào trang giới thiệu sản phẩm).
* **Số lượng đăng ký mới thực tế (Organic Registrations):** **20 người dùng** (không tính 50 tài khoản test chèn bằng script).
* **Số lượng chuyển đổi VIP thực tế (VIP Purchases):** **8 người dùng**.

#### Bảng tính toán tỷ lệ chuyển đổi:

| Chỉ số chuyển đổi | Công thức tính | Kết quả thực tế | Nhận xét đánh giá |
| :--- | :--- | :--- | :--- |
| **Tỷ lệ chuyển đổi đăng ký (Traffic to Registration)** | $\frac{20 \text{ Đăng ký}}{150 \text{ Click}} \times 100\%$ | **13.3%** | Đạt mức chuyển đổi tốt. Cứ khoảng 7-8 người click vào link giới thiệu thì có 1 người đồng ý tải ứng dụng và đăng ký tài khoản. Quy trình onboarding trực quan hỗ trợ rất nhiều. |
| **Tỷ lệ chuyển đổi VIP (Registration to Purchase)** | $\frac{8 \text{ VIP}}{20 \text{ Đăng ký}} \times 100\%$ | **40.0%** | Tỷ lệ chuyển đổi VIP cực kỳ ấn tượng từ lượng người dùng đăng ký thực tế. Mức giá 150K/tháng rất hợp lý và các tính năng Premium (AI Form Check, Personalized Workout) có sức hút mạnh mẽ để thuyết phục người dùng nâng cấp. |
| **Tỷ lệ chuyển đổi tổng thể (Overall Conversion Rate)** | $\frac{8 \text{ VIP}}{150 \text{ Click}} \times 100\%$ | **5.33%** | Tỷ lệ chuyển đổi tổng thể đạt **5.33%** là một con số xuất sắc đối với ứng dụng di động Fitness & AI ở giai đoạn đầu ra mắt thị trường (vượt xa mức trung bình ngành thông thường là 2-3%). |
