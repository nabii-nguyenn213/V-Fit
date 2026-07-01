# Đặc tả tính năng: Đăng ký Dùng thử VIP 3 ngày, Thiết kế lại Hồ sơ và Quy trình Thiết lập Ban đầu

**Nhánh tính năng**: `010-deploy-play-store`

**Ngày tạo**: 2026-07-01

**Trạng thái**: Bản thảo (Draft)

## Kịch bản Người dùng & Kiểm thử

### Kịch bản 1 - Dùng thử VIP 3 ngày khi đăng ký mới (Độ ưu tiên: P1)
Tất cả người dùng mới đăng ký (qua email/mật khẩu hoặc đăng nhập mạng xã hội Google/Facebook) sẽ tự động nhận được gói dùng thử VIP Trial thời hạn 3 ngày. Trạng thái này hiển thị là "Vip Trial" trong trang hồ sơ.

**Kịch bản nghiệm thu**:
1. **Cho** một người dùng mới đăng ký tài khoản thành công, **Khi** tài khoản được kích hoạt (hoặc đăng nhập thành công bằng MXH), **Thì** hệ thống tự động thiết lập gói VIP dùng thử thời hạn 3 ngày.
2. **Cho** người dùng có gói VIP dùng thử còn hạn, **Khi** truy cập trang Hồ sơ, **Thì** thông tin gói hiển thị là "Vip Trial".
3. **Cho** người dùng có gói VIP dùng thử còn hạn, **Khi** sử dụng các tính năng VIP (như AI Coach), **Thì** hệ thống cho phép truy cập mà không gặp rào cản thanh toán.

---

### Kịch bản 2 - Thay đổi giao diện thông báo chỉ số cơ thể khi chưa nhập dữ liệu (Độ ưu tiên: P1)
Khi người dùng chưa hoàn thành thiết lập ban đầu (chưa nhập chiều cao, cân nặng...), thay vì hiển thị lỗi phân quyền VIP ("Không tải được dữ liệu / Tính năng này chỉ dành cho thành viên VIP"), trang Hồ sơ phải hiển thị một thẻ thông báo "Cập nhật thể trạng cơ thể" được thiết kế đẹp mắt, đồng bộ hoàn hảo với giao diện sáng/tối (Light/Dark mode) của ứng dụng.

**Kịch bản nghiệm thu**:
1. **Cho** người dùng chưa hoàn thành thiết lập ban đầu, **Khi** mở trang Hồ sơ, **Thì** thẻ "Chỉ số cơ thể" hiển thị lời nhắc "Cập nhật thể trạng cơ thể" kèm nút "Tiếp tục thiết lập".
2. **Cho** thẻ thông báo này, **Khi** thay đổi giao diện sáng/tối của ứng dụng, **Thì** màu nền, màu chữ và nút bấm tự động điều chỉnh theo hệ thống, không bị lệch tông màu (lạc quẻ).
3. **Cho** người dùng nhấn nút "Tiếp tục thiết lập" trên thẻ, **Khi** nhấn vào, **Thì** hệ thống chuyển hướng họ trực tiếp tới luồng thiết lập ban đầu.

---

### Kịch bản 3 - Khóa chỉnh sửa Mục tiêu và Chặn trang Chỉnh sửa hồ sơ khi chưa thiết lập ban đầu (Độ ưu tiên: P1)
Trên màn hình Chỉnh sửa hồ sơ cá nhân, người dùng chỉ được phép chỉnh sửa: Họ tên, ảnh đại diện, giới tính, chiều cao, cân nặng, và tỷ lệ mỡ. Trường "Mục tiêu" (Goal) sẽ bị khóa hoàn toàn. Để sửa mục tiêu, người dùng buộc phải thực hiện thiết lập lại từ đầu. Đặc biệt, nếu người dùng chưa hoàn tất thiết lập ban đầu, họ cũng bị chặn không cho chỉnh sửa hồ sơ (hiển thị cùng một giao diện nhắc nhở tiếp tục thiết lập giống trang Hồ sơ).

Trường "Họ và tên" (FullName) phải luôn được phép chỉnh sửa (không bị khóa) để hỗ trợ các trường hợp đăng ký qua Google/Facebook bị thiếu tên hiển thị có thể chủ động nhập bổ sung sau.

**Kịch bản nghiệm thu**:
1. **Cho** người dùng chưa hoàn thành thiết lập ban đầu, **Khi** họ cố gắng truy cập màn hình Chỉnh sửa hồ sơ, **Thì** giao diện hiển thị bảng thông báo "Cập nhật thể trạng cơ thể" yêu cầu hoàn tất thiết lập trước, khóa tất cả các thao tác sửa đổi.
2. **Cho** người dùng đã hoàn thành thiết lập ban đầu, **Khi** mở trang Chỉnh sửa hồ sơ, **Thì** ô chọn "Mục tiêu" hiển thị trạng thái khóa (disable) kèm nút bấm "Thiết lập lại từ đầu" để thay đổi mục tiêu.
3. **Cho** người dùng mở màn hình Chỉnh sửa hồ sơ, **Khi** xem trường "Họ và tên", **Thì** trường này luôn ở trạng thái cho phép nhập liệu và chỉnh sửa bình thường.
4. **Cho** người dùng nhấn nút "Thiết lập lại từ đầu" và xác nhận đồng ý, **Khi** đồng ý, **Thì** trạng thái thiết lập được reset về PENDING, mục tiêu bị xóa, và họ được đưa quay lại màn hình nhập thông tin ban đầu ngay lập tức.

---

### Kịch bản 4 - Tự động điền dữ liệu đã có khi vào màn hình Thiết lập (Độ ưu tiên: P1)
Khi người dùng vào màn hình thiết lập ban đầu (kể cả lần đầu hay khi chọn thiết lập lại từ đầu), hệ thống phải tự động lấy các thông tin thể trạng (giới tính, chiều cao, cân nặng, tỷ lệ mỡ) đã được cấu hình trước đó trong hồ sơ cá nhân để điền sẵn vào các ô nhập liệu, giúp họ không phải nhập lại từ đầu.

**Kịch bản nghiệm thu**:
1. **Cho** người dùng đã có sẵn thông tin chiều cao/cân nặng trong hồ sơ, **Khi** bắt đầu thiết lập ban đầu, **Thì** các ô nhập liệu tương ứng đã hiển thị sẵn giá trị cũ.

---

### Kịch bản 5 - Việt hóa thông báo lỗi validate và các chuỗi text không dấu trong app (Độ ưu tiên: P1)
Khi người dùng nhập thiếu thông tin hoặc sai định dạng trên màn hình Đăng nhập hoặc Đăng ký, hệ thống phải hiển thị thông báo lỗi validate hoàn toàn bằng tiếng Việt có dấu chuẩn xác. Đồng thời, toàn bộ các chuỗi văn bản không dấu còn tồn tại trong ứng dụng (như thông báo nạp VIP, thông báo quét cơ thể, các nút quét lại, chấp nhận) phải được cập nhật sang tiếng Việt có dấu.

**Kịch bản nghiệm thu**:
1. **Cho** người dùng đăng nhập sai hoặc thiếu mật khẩu, **Khi** validate, **Thì** thông báo lỗi hiển thị rõ bằng tiếng Việt: "Mật khẩu không được để trống".
2. **Cho** người dùng mở màn hình Quét cơ thể AI hoặc trang thanh toán nạp VIP, **Khi** hiển thị thông báo hoặc nút bấm, **Thì** toàn bộ nhãn như "Quét lại", "Chấp nhận", "Đã nhận thanh toán. VIP đã được kích hoạt." hiển thị có dấu đầy đủ và chuẩn xác.

## Yêu cầu Hệ thống

### Yêu cầu Chức năng
- **FR-001**: Hệ thống tự động kích hoạt gói VIP Trial 3 ngày cho mọi tài khoản mới đăng ký.
- **FR-002**: Trang Hồ sơ hiển thị nhãn gói VIP dùng thử là "Vip Trial".
- **FR-003**: Ẩn hoàn toàn khung lỗi màu đỏ khi chưa có chỉ số cơ thể, thay thế bằng thẻ thông tin nhắc nhở cập nhật thể trạng có thiết kế chuẩn màu sáng/tối.
- **FR-004**: Khóa trường nhập Mục tiêu trên trang Chỉnh sửa hồ sơ. Cung cấp nút "Thiết lập lại từ đầu" để thay đổi mục tiêu.
- **FR-005**: Nếu người dùng chưa hoàn thành thiết lập ban đầu, chặn truy cập Chỉnh sửa hồ sơ và hiển thị màn hình nhắc nhở hoàn tất thiết lập ban đầu.
- **FR-006**: Trường "Họ và tên" luôn cho phép chỉnh sửa bình thường trên màn hình Chỉnh sửa hồ sơ.
- **FR-007**: Tự động lấy dữ liệu thể chất hiện có để điền sẵn vào các trường nhập liệu tương ứng khi bắt đầu thiết lập ban đầu.
- **FR-008**: Toàn bộ thông báo validate và các chuỗi văn bản trong hệ thống (Đăng nhập, Đăng ký, Quét cơ thể, Nạp VIP) phải hiển thị bằng tiếng Việt có dấu chuẩn xác.

### Thành phần Dữ liệu
- **SubscriptionSnapshot**: Trạng thái gói, mã gói (`VIP_TRIAL`), hạn dùng thử.
- **OnboardingStatus**: Trạng thái PENDING / COMPLETED.
- **BodyMetrics**: Chiều cao, cân nặng, tỷ lệ mỡ, BMI.

## Tiêu chí Thành công

### Kết quả Đo lường được
- **SC-001**: 100% tài khoản đăng ký mới nhận được 3 ngày VIP Trial.
- **SC-002**: Không có lỗi VIP hoặc thông báo lỗi phân quyền khi chưa có chỉ số cơ thể.
- **SC-003**: 100% thông tin cũ được tự động điền khi người dùng làm thiết lập ban đầu.
- **SC-004**: 100% văn bản hiển thị trên các trang Đăng nhập, Đăng ký, Chỉnh sửa hồ sơ, Quét cơ thể và Nạp VIP đều là tiếng Việt có dấu chuẩn xác.
