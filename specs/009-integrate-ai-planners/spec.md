# Đặc tả tính năng: Tích hợp AI Planners & Food Scanner

**Feature Branch**: `009-integrate-ai-planners`

**Created**: 2026-06-15

**Status**: Draft

**Input**: User description: "t tạo cho t 1 bản kế huachj để match nhưng con chatbot ben recommendsystem (web2api) vào dự án code của t"

## Kịch bản người dùng & Kiểm thử (User Scenarios & Testing)

### Kịch bản 1 - Tích hợp AI Workout Planner (Độ ưu tiên: P1)

Người dùng VIP muốn tạo một lịch tập cá nhân hóa dựa trên thông tin thể trạng hiện tại (tuổi, giới tính, chiều cao, cân nặng, mục tiêu, mức độ hoạt động) cùng với trình độ tập luyện (Beginner, Intermediate, Advanced) và số ngày tập mỗi tuần mong muốn.

**Tại sao ưu tiên này**: Cung cấp giá trị cốt lõi của tính năng tập luyện thông minh của V-FIT.

**Kiểm thử độc lập**:
- Người dùng truy cập màn hình Workout Planner, chọn số ngày tập (ví dụ: 4 ngày) và trình độ (Beginner).
- Nhấn "Tạo lịch tập", hệ thống gửi request đến `POST /api/v1/workout-planner/` của FastAPI.
- Kết quả trả về kế hoạch dạng JSON hiển thị chi tiết lịch trình các ngày tập kèm theo danh sách bài tập.

---

### Kịch bản 2 - Tích hợp AI Meal Planner (Độ ưu tiên: P1)

Người dùng VIP muốn tạo thực đơn ăn uống dinh dưỡng hàng ngày dựa trên các thông số thể trạng và số bữa ăn mong muốn trong ngày (ví dụ: 3 bữa hoặc 4 bữa).

**Tại sao ưu tiên này**: Dinh dưỡng đóng vai trò 50% trong tập luyện.

**Kiểm thử độc lập**:
- Truy cập tính năng Meal Planner, chọn số bữa ăn mong muốn trong ngày.
- Nhấn "Tạo thực đơn", hệ thống gọi `POST /api/v1/meal-planner/` của FastAPI.
- Giao diện hiển thị lượng Calo khuyến nghị hàng ngày, tỷ lệ dinh dưỡng (Carbs, Protein, Fat) và thực đơn từng bữa.

---

### Kịch bản 3 - Tích hợp AI Food Scanner bằng Văn bản (Độ ưu tiên: P2)

Người dùng muốn ước lượng nhanh lượng Calorie và dinh dưỡng của một món ăn bằng cách nhập mô tả văn bản (ví dụ: "cơm gà - 1 đĩa").

**Tại sao ưu tiên này**: Thay thế cho tính năng quét ảnh trong trường hợp không có camera hoặc quét ảnh lỗi.

**Kiểm thử độc lập**:
- Người dùng vào nhật ký ăn uống, nhập tên món ăn "Phở bò" và lượng "1 tô".
- Nhấn "Ước lượng dinh dưỡng", hệ thống gửi yêu cầu tới `POST /api/v1/food-scanner/text`.
- Hệ thống trả về chính xác bảng phân bổ Calo, Protein, Carbs, Fat của tô phở đó để người dùng lưu lại.

---

## Yêu cầu tính năng (Requirements)

### Yêu cầu chức năng

- **FR-001**: Ứng dụng MUST tích hợp gọi các API Planners của FastAPI thông qua `aiDioProvider`.
- **FR-002**: Người dùng phải có quyền VIP hoạt động (`isVipActive == true`) mới được truy cập các tính năng Workout Planner và Meal Planner.
- **FR-003**: Dữ liệu thể trạng (tuổi, cân nặng, chiều cao, giới tính, mục tiêu) MUST được tự động điền từ `profile_repository` và `bodyMetricsProvider` để giảm thiểu thao tác nhập liệu của người dùng.
- **FR-004**: Kết quả JSON trả về từ AI MUST được hiển thị trực quan bằng giao diện đẹp mắt (ví dụ: Glassmorphism hoặc thẻ Card chi tiết), có nút để lưu lại kế hoạch.

## Tiêu chí thành công (Success Criteria)

### Kết quả đo lường được

- **SC-001**: Người dùng nhận được lịch tập cá nhân hóa hoàn chỉnh trong vòng dưới 10 giây từ khi gửi yêu cầu.
- **SC-002**: Thực đơn gợi ý hiển thị rõ ràng lượng calo và khối lượng macros (Carb/Protein/Fat) dưới dạng biểu đồ hoặc biểu diễn trực quan.
