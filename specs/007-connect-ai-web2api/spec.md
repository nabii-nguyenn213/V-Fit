# Đặc tả tính năng: Kết nối và Tích hợp Backend AI

**Nhánh**: `web2api`

**Ngày tạo**: 2026-06-14

**Trạng thái**: Bản thảo (Draft)

**Yêu cầu đầu vào**: "connect dự án của t vs AI dựa trên README.md"

## Kịch bản Người dùng & Kiểm thử *(bắt buộc)*

### Kịch bản 1 - Chạy thử nghiệm cục bộ Pipeline AI (Độ ưu tiên: P1)

Là một lập trình viên, tôi muốn chạy dịch vụ `gemini-web2api` trên cổng 8081 và `RecommendationSystem` trên cổng 8000, để các yêu cầu LLM được xử lý thành công và chuyển hướng đến Google Gemini mà không cần khóa API thương mại (production key).

**Tại sao ưu tiên này**: Đây là thiết lập cốt lõi. Mọi chức năng AI khác đều phụ thuộc vào việc pipeline AI chạy local này hoạt động ổn định.

**Kiểm thử độc lập**:
1. Chạy `python gemini_web2api.py` trong thư mục `gemini-web2api` và xác nhận nó đang lắng nghe trên cổng 8081.
2. Chạy `python -m uvicorn main:app --host 0.0.0.0 --port 8000` trong thư mục `RecommendationSystem` và xác nhận nó đang lắng nghe trên cổng 8000.
3. Mở tài liệu Swagger tại `http://localhost:8000/docs` và gửi một yêu cầu thử nghiệm tới `/api/v1/coach/`. Xác nhận nó trả về phản hồi hợp lệ từ Gemini.

**Kịch bản nghiệm thu**:
1. **Cho biết** cả hai dịch vụ `gemini-web2api` và `RecommendationSystem` đều đang chạy, **Khi** một yêu cầu REST được gửi đến endpoint Coach của `RecommendationSystem`, **Thì** nó phải gọi thành công API hoàn thành của `gemini-web2api` và trả về kết quả AI Coach tương ứng.

---

### Kịch bản 2 - Cấu hình Flutter Client Kết nối AI (Độ ưu tiên: P1)

Là người dùng VIP hoặc khách hàng, tôi muốn ứng dụng Flutter tự động phát hiện `aiBaseUrl` cho môi trường cục bộ, máy ảo (emulator) và các thiết bị thật, để ứng dụng có thể kết nối thông suốt với backend AI.

**Tại sao ưu tiên này**: Rất cần thiết để người dùng di động có thể kết nối với dịch vụ AI.

**Kiểm thử độc lập**:
1. Chạy ứng dụng Flutter trên trình giả lập Android và xác nhận `aiBaseUrl` được phân giải thành `http://10.0.2.2:8000`.
2. Gửi một câu hỏi tới AI Coach từ ứng dụng và xác minh yêu cầu được chuyển tiếp chính xác đến FastAPI RecommendationSystem.

**Kịch bản nghiệm thu**:
1. **Cho biết** ứng dụng đang chạy ở chế độ debug trên trình giả lập Android, **Khi** một yêu cầu AI được khởi tạo, **Thì** nó phải mặc định sử dụng `http://10.0.2.2:8000` trừ khi được ghi đè bởi biến môi trường `AI_BASE_URL`.
2. **Cho biết** ứng dụng không thể kết nối tới URL đầu tiên, **Khi** danh sách ứng viên URL có nhiều hơn 1 địa chỉ, **Thì** nó phải tự động thử kết nối tới địa chỉ tiếp theo.

---

### Kịch bản 3 - Giao diện trò chuyện với AI Coach (Độ ưu tiên: P2)

Là một thành viên VIP của V-FIT, tôi muốn mở màn hình AI Coach và nhắn tin trò chuyện trực tiếp để nhận lời khuyên dinh dưỡng và tập luyện từ huấn luyện viên AI.

**Tại sao ưu tiên này**: Tính năng cốt lõi cho phép người dùng trực tiếp trải nghiệm giá trị của tích hợp AI.

**Kiểm thử độc lập**:
1. Đăng nhập bằng tài khoản VIP.
2. Điều hướng đến trang AI Coach.
3. Gửi tin nhắn "Tôi nên tập gì hôm nay?" và xác nhận AI Coach phản hồi với lời khuyên chi tiết.

**Kịch bản nghiệm thu**:
1. **Cho biết** người dùng VIP vào trang AI Coach, **Khi** họ gửi câu hỏi, **Thì** ứng dụng phải gọi API `POST /api/v1/coach/` kèm theo thông tin thể trạng (tuổi, giới tính, chiều cao, cân nặng, mục tiêu, mức vận động) và nội dung tin nhắn.
2. **Cho biết** người dùng thường (không phải VIP) cố gắng mở AI Coach, **Khi** họ nhấn vào tính năng này, **Thì** hệ thống phải hiển thị banner nâng cấp gói VIP.

---

### Các trường hợp biên (Edge Cases)

- **Backend AI ngoại tuyến**: Nếu hệ thống AI bị lỗi kết nối hoặc quá tải, ứng dụng phải hiển thị thông báo lỗi kết nối rõ ràng thay vì bị crash.
- **Thiếu thông tin thể trạng**: Nếu người dùng chưa điền đầy đủ chiều cao/cân nặng/mục tiêu, hệ thống sẽ gửi các giá trị mặc định hợp lý kèm theo gợi ý người dùng bổ sung thông tin hồ sơ.

## Yêu cầu *(bắt buộc)*

### Yêu cầu chức năng

- **FR-001**: Flutter client PHẢI định nghĩa `aiBaseUrl` và `aiBaseUrlCandidates` trong `Environment`, hỗ trợ ghi đè qua `--dart-define=AI_BASE_URL`.
- **FR-002**: Flutter client PHẢI cung cấp `aiDioProvider` kết nối tới FastAPI kèm theo interceptor hỗ trợ fallback URL tự động.
- **FR-003**: Flutter client PHẢI hỗ trợ tính năng AI Coach bằng cách gọi `POST /api/v1/coach/` truyền kèm ngữ cảnh hồ sơ người dùng.
- **FR-004**: Flutter client PHẢI giới hạn các tính năng AI cho người dùng VIP. Người dùng không phải VIP chỉ được xem banner quảng cáo nâng cấp VIP.
- **FR-005**: Các prompt dùng bởi RecommendationSystem PHẢI được lưu trữ tại thư mục `skills/conversation/` để tuân thủ hiến pháp dự án.

### Các thực thể chính

- **User Profile**: Chứa tuổi, giới tính, chiều cao, cân nặng, mục tiêu tập luyện, mức vận động và trạng thái VIP.
- **Coach Message**: Đại diện cho một tin nhắn trong cuộc hội thoại giữa người dùng và AI Coach.

## Tiêu chí thành công *(bắt buộc)*

### Chỉ số đo lường

- **SC-001**: Phản hồi từ AI Coach hiển thị lên màn hình trong vòng dưới 10 giây ở điều kiện mạng bình thường.
- **SC-002**: 100% người dùng không phải VIP bị chặn không cho sử dụng dịch vụ chat với AI Coach.

## Giả định

- Nhà phát triển đã cài đặt Python 3.8+ trên máy tính cục bộ.
- Dịch vụ `gemini-web2api` hoạt động ở chế độ ẩn danh (không cần cookie tài khoản Gemini Advanced) cho các yêu cầu sử dụng mô hình Flash cơ bản.
