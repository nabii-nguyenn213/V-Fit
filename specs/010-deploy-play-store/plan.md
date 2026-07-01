# Kế hoạch Thực hiện: Đăng ký Dùng thử VIP 3 ngày, Thiết kế lại Hồ sơ và Quy trình Thiết lập Ban đầu

**Nhánh**: `010-deploy-play-store` | **Ngày**: 2026-07-01 | **Tài liệu đặc tả**: [spec.md](spec.md)

**Yêu cầu**: Cấp dùng thử VIP 3 ngày khi đăng ký mới, trang hồ sơ hiển thị "Vip Trial", thiết kế lại giao diện nhắc nhở cập nhật thể trạng chuẩn sáng/tối (không hiển thị lỗi phân quyền VIP hay lỗi không tải được dữ liệu), chặn truy cập và khóa chỉnh sửa mục tiêu trong trang chỉnh sửa hồ sơ nếu chưa thiết lập ban đầu (chỉ cho phép đổi mục tiêu bằng cách làm lại thiết lập ban đầu - Onboarding), đảm bảo trường "Họ và tên" luôn cho phép chỉnh sửa bình thường để người dùng đăng ký qua Google/Facebook cập nhật sau, tự động điền các thông tin thể chất cũ khi người dùng bắt đầu thiết lập để tránh bắt họ nhập lại, đồng thời sửa đổi toàn bộ thông báo lỗi validate và các chuỗi văn bản không dấu còn tồn tại trong ứng dụng sang tiếng Việt có dấu chuẩn xác.

## Tóm tắt Kỹ thuật
Triển khai gói VIP dùng thử 3 ngày (`VIP_TRIAL`) khi đăng ký mới trên cả hai luồng đăng ký bằng OTP và mạng xã hội. Trên frontend, cập nhật định dạng hiển thị gói là "Vip Trial". Chỉnh sửa các nhãn tiếng Việt trên trang Chỉnh sửa hồ sơ cho có dấu chuẩn. Khóa trường chọn Mục tiêu trên màn hình Chỉnh sửa hồ sơ; bổ sung nút và endpoint để reset trạng thái thiết lập ban đầu về PENDING. Đảm bảo trường "Họ và tên" là trường nhập liệu chỉnh sửa được bình thường. Thay đổi thẻ chỉ số cơ thể trên trang Hồ sơ: nếu người dùng đang PENDING thiết lập ban đầu, hiển thị thẻ nhắc nhở "Cập nhật thể trạng cơ thể" được thiết kế đồng bộ với hệ thống giao diện sáng/tối (sử dụng `AppCard` và màu chữ chuẩn, tránh khung lỗi đỏ lạc quẻ). Tối ưu hóa `bodyMetricsProvider` để không thực hiện cuộc gọi API 403 khi onboarding đang pending. Áp dụng cùng logic đó chặn chỉnh sửa hồ sơ và hiển thị thẻ nhắc nhở nếu chưa làm xong thiết lập ban đầu. Tự động điền các trường chiều cao/cân nặng/tỷ lệ mỡ có sẵn từ profile vào luồng thiết lập ban đầu. Ngoài ra, tiến hành cập nhật tệp tiện ích `validators.dart` để chuyển đổi toàn bộ thông báo validate sang tiếng Việt có dấu chuẩn, đồng thời sửa tất cả các chuỗi thông báo không dấu trong `login_page.dart`, `profile_page.dart`, `ai_onboarding_body_scan_page.dart`, và `ai_body_analysis_page.dart`.

## Bối cảnh Kỹ thuật

**Ngôn ngữ/Phiên bản**: Java 17, Spring Boot, Dart, Flutter

**Thư viện chính**: Spring Security, Dio, Riverpod

**Lưu trữ**: MongoDB (users collection)

**Kiểm thử**: JUnit, Integration Tests, Flutter widget và manual navigation tests.

**Nền tảng mục tiêu**: Android, iOS

**Loại dự án**: Ứng dụng Di động & Máy chủ Web API

**Mục tiêu Hiệu năng**: Không làm tăng thời gian phản hồi API.

**Ràng buộc**: Đảm bảo tuân thủ Hiến pháp V-FIT về cơ chế phân quyền VIP.

## Kiểm tra Hiến pháp

*Cổng kiểm soát: Bắt buộc vượt qua trước khi nghiên cứu và thiết kế.*

Xác minh kế hoạch thực hiện với Hiến pháp V-FIT:
- **Cơ chế phân quyền VIP cho các tính năng AI**: Đạt. Bằng việc định nghĩa mã `"VIP_TRIAL"` là gói Premium hợp lệ, những người dùng đang trải nghiệm thử vẫn sử dụng được AI Coach bình thường.
- **Ràng buộc an toàn dữ liệu và danh tính**: Đạt.

## Cấu trúc Dự án

### Tài liệu Đặc tả & Thiết kế

```text
specs/010-deploy-play-store/
├── spec.md              # Tài liệu đặc tả tính năng tiếng Việt
├── plan.md              # Bản kế hoạch này tiếng Việt
├── research.md          # Kết quả nghiên cứu kỹ thuật
└── quickstart.md        # Hướng dẫn kiểm tra nhanh
```

### Mã Nguồn Ảnh Hưởng

```text
VFIT_Backend/
├── src/main/java/com/vfit/
│   ├── modules/auth/service/impl/AuthServiceImpl.java
│   ├── modules/payment/service/impl/PaymentServiceImpl.java
│   ├── modules/user/controller/OnboardingController.java
│   ├── modules/user/service/OnboardingService.java
│   ├── modules/user/service/impl/OnboardingServiceImpl.java
│   ├── modules/user/service/impl/UserServiceImpl.java
│   ├── modules/user/mapper/UserMapper.java
│   └── security/FeatureGate.java

VFIT_Fontend/
├── lib/
│   ├── core/constants/api_endpoints.dart
│   ├── core/utils/validators.dart
│   ├── features/ai/presentation/pages/ai_body_analysis_page.dart
│   ├── features/onboarding/data/repositories/onboarding_repository.dart
│   ├── features/onboarding/presentation/pages/ai_onboarding_body_scan_page.dart
│   ├── features/onboarding/presentation/pages/onboarding_page.dart
│   ├── features/profile/data/models/user_model.dart
│   └── features/profile/presentation/pages/
│       ├── edit_profile_page.dart
│       └── profile_page.dart
```

---

## Chi tiết Thay đổi Đề xuất

### 1. Phần Backend (Spring Boot)

#### [MODIFY] [UserServiceImpl.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/service/impl/UserServiceImpl.java)
- Trong hàm `createLocalUser`, tự động gán gói dùng thử VIP 3 ngày cho mọi người dùng mới thuộc nhóm `RoleName.USER`:
  ```java
  .subscription(role == RoleName.ADMIN ? User.SubscriptionSnapshot.free() : User.SubscriptionSnapshot.builder()
          .status(SubscriptionStatus.ACTIVE)
          .planCode("VIP_TRIAL")
          .premiumUntil(Instant.now().plus(java.time.Duration.ofDays(3)))
          .build())
  ```

#### [MODIFY] [AuthServiceImpl.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/auth/service/impl/AuthServiceImpl.java)
- Trong hàm `resolveUserForNewProviderIdentity`, gán gói dùng thử VIP 3 ngày tương tự khi tạo tài khoản thông qua Google/Facebook.

#### [MODIFY] [FeatureGate.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/security/FeatureGate.java)
- Bổ sung `"VIP_TRIAL"` vào danh sách gói Premium được phép vượt qua cổng bảo mật `isPremiumPlan`.

#### [MODIFY] [UserMapper.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/mapper/UserMapper.java)
- Bổ sung `"VIP_TRIAL"` vào hàm `isPremiumPlan`.
- Định dạng mã `"VIP_TRIAL"` thành chuỗi hiển thị `"Vip Trial"` trong hàm `normalizePremiumPlan`.

#### [MODIFY] [PaymentServiceImpl.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/payment/service/impl/PaymentServiceImpl.java)
- Bổ sung `"VIP_TRIAL"` vào các hàm `isVipPlan` và `normalizeVipType` để hỗ trợ hiển thị thông tin gói và thời hạn dùng thử.

#### [MODIFY] [OnboardingController.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/controller/OnboardingController.java)
- Thêm API reset onboarding mới:
  ```java
  @PutMapping("/reset")
  public ApiResponse<UserResponse> resetOnboarding() {
      return ApiResponse.ok(onboardingService.resetOnboarding());
  }
  ```

#### [MODIFY] [OnboardingService.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/service/OnboardingService.java)
- Khai báo phương thức `UserResponse resetOnboarding();`.

#### [MODIFY] [OnboardingServiceImpl.java](file:///d:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/service/impl/OnboardingServiceImpl.java)
- Triển khai phương thức `resetOnboarding()`:
  - Cập nhật `onboardingStatus` của người dùng về `OnboardingStatus.PENDING`.
  - Thiết lập `goalType` về `null`.
  - Lưu và xóa cache `personalized_workouts` liên quan.

---

### 2. Phần Frontend (Flutter)

#### [MODIFY] [api_endpoints.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/core/constants/api_endpoints.dart)
- Thêm hằng số endpoint reset onboarding:
  ```dart
  static const onboardingReset = '/api/v1/users/onboarding/reset';
  ```

#### [MODIFY] [profile_repository.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/data/repositories/profile_repository.dart)
- Cập nhật `bodyMetricsProvider` để kiểm tra trạng thái của người dùng. Nếu chưa hoàn thành onboarding thì trả về `const BodyMetricModel()` thay vì thực hiện cuộc gọi API không hợp lệ.

#### [MODIFY] [validators.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/core/utils/validators.dart)
- Việt hóa toàn bộ các thông báo validate:
  - Trường bắt buộc: `'$label không được để trống'`
  - Email sai định dạng: `'Vui lòng nhập địa chỉ email hợp lệ'`
  - Mật khẩu: độ dài tối thiểu 8 ký tự, chứa ít nhất một chữ hoa và một chữ số bằng tiếng Việt.
  - Số hợp lệ: `'$label phải là một số'`, `'$label phải nằm trong khoảng từ $min đến $max'`.

#### [MODIFY] [login_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/auth/presentation/pages/login_page.dart)
- Thay đổi validator của mật khẩu thành: `(value) => Validators.required(value, label: 'Mật khẩu')`.

#### [MODIFY] [change_password_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/presentation/pages/change_password_page.dart)
- Thay đổi validator của mật khẩu hiện tại thành: `(value) => Validators.required(value, label: 'Mật khẩu hiện tại')`.

#### [MODIFY] [onboarding_repository.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/onboarding/data/repositories/onboarding_repository.dart)
- Định nghĩa hàm `Future<UserModel> resetOnboarding()` thực hiện gửi yêu cầu `PUT` lên endpoint `/api/v1/users/onboarding/reset`.

#### [MODIFY] [user_model.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/data/models/user_model.dart)
- Bổ sung giá trị `'VIP_TRIAL'` vào phương thức kiểm tra `hasVipPlan`.

#### [MODIFY] [profile_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/presentation/pages/profile_page.dart)
- Trong phần `_formatPremiumPlan`, ánh xạ mã `'VIP_TRIAL'` trả về chuỗi `'Vip Trial'`.
- Sửa đổi thông báo khi nạp VIP: `'Vui lòng đăng nhập để nạp VIP.'`
- Việt hóa thông báo thanh toán thành công: `'Đã nhận thanh toán. VIP đã được kích hoạt.'` và `'VIP đã được kích hoạt.'`
- Chỉnh sửa luồng hiển thị chỉ số cơ thể:
  - Trước khi gọi `bodyMetrics.when`, thực hiện kiểm tra trạng thái người dùng:
    ```dart
    if (user.onboardingStatus == OnboardingStatus.pending) {
       // Hiển thị thẻ nhắc nhở cập nhật thể trạng sử dụng AppCard chuẩn sáng/tối
       // Nút bấm "Tiếp tục thiết lập" điều hướng sang màn hình '/onboarding'
    } else {
       // Chạy luồng gọi API và hiển thị chỉ số cơ thể bình thường
    }
    ```

#### [MODIFY] [edit_profile_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/profile/presentation/pages/edit_profile_page.dart)
- Kiểm tra trạng thái thiết lập ban đầu khi bắt đầu xây dựng giao diện. Nếu `user.onboardingStatus != OnboardingStatus.completed`, chặn hiển thị form sửa, thay vào đó hiển thị thẻ `PendingOnboardingPlaceholder` với nút bấm **"Tiếp tục thiết lập"** đưa người dùng đến luồng thiết lập ban đầu (đồng bộ logic như trang Hồ sơ).
- Việt hóa có dấu tất cả các nhãn tiếng Việt không dấu (Chỉnh sửa hồ sơ, Họ và tên, Giới tính, Mục tiêu, Chiều cao (cm), Cân nặng (kg), Tỷ lệ mỡ (%), Lưu hồ sơ, Chọn từ thư viện, Chụp ảnh).
- Đảm bảo trường "Họ và tên" (FullName) luôn ở trạng thái cho phép nhập liệu (không bị disable) để người dùng đăng ký qua Google có thể cập nhật lại sau.
- Khóa (disable) ô Dropdown chọn mục tiêu khi `user.onboardingStatus == OnboardingStatus.pending` hoặc khi đã có mục tiêu.
- Ở phía dưới ô chọn mục tiêu, nếu người dùng đã hoàn thành onboarding, hiển thị thông báo giải thích: "Để thay đổi mục tiêu/phương hướng, vui lòng thiết lập lại hồ sơ từ đầu." kèm nút bấm **"Thiết lập lại từ đầu"**.
- Khi người dùng click vào nút, hiển thị hộp thoại xác nhận (Confirmation Dialog): "Bạn có chắc chắn muốn thay đổi phương hướng? Hệ thống sẽ thiết lập lại trạng thái để bạn thực hiện thiết lập lại từ đầu."
- Khi chọn đồng ý, thực hiện gọi API `/onboarding/reset` và cập nhật thông tin qua `ref.read(authControllerProvider.notifier).setUser(user)`. Luồng định tuyến router sẽ tự động đưa người dùng về màn hình `/onboarding`.

#### [MODIFY] [onboarding_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/onboarding/presentation/pages/onboarding_page.dart)
- Trong phương thức `initState`, kiểm tra dữ liệu chỉ số cơ thể hiện tại của người dùng (từ `bodyMetricsProvider` hoặc gọi API lấy chỉ số) và thực hiện gán giá trị mặc định lên các ô nhập liệu Chiều cao, Cân nặng, Tỷ lệ mỡ để người dùng không phải nhập lại các thông tin họ đã thiết lập trước đó.

#### [MODIFY] [ai_onboarding_body_scan_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/onboarding/presentation/pages/ai_onboarding_body_scan_page.dart)
- Việt hóa toàn bộ các chuỗi thông báo quét cơ thể:
  - `'Đã quét cơ thể thành công.'`
  - `'Lưu kết quả thất bại: $e. Vui lòng thử lại.'`
  - `'Chưa nhận được dữ liệu'`
  - `'Đã quét thành công'`
  - `'Hãy quét lại với toàn thân nằm trong khung hình.'`
  - `'AI đã ghi nhận thông tin hình thể. Hãy kiểm tra trước khi tiếp tục.'`
  - `'Không có dữ liệu cơ thể để hiển thị.'`
  - Nút bấm: `'Quét lại'` và `'Chấp nhận'`.

#### [MODIFY] [ai_body_analysis_page.dart](file:///d:/EXE_PRM/VFIT_Fontend/lib/features/ai/presentation/pages/ai_body_analysis_page.dart)
- Việt hóa toàn bộ các chuỗi text:
  - `'Chưa nhận được dữ liệu dáng người. Hãy quét lại với toàn thân nằm trong khung hình.'`
  - Nút bấm: `'Quét lại'` và `'Chấp nhận'`.

---

## Kế hoạch Xác minh

### Kiểm thử Tự động
- Khởi chạy máy chủ backend và đảm bảo các bài test phân quyền và bộ lọc chạy thành công.

### Xác minh Thủ công
- Đăng ký tài khoản mới và kiểm tra thời hạn sử dụng thử VIP là 3 ngày.
- Kiểm tra trang Hồ sơ và trang Chỉnh sửa hồ sơ khi tài khoản chưa hoàn tất onboarding để đảm bảo cả hai nơi đều chặn hiển thị và đưa ra thẻ nhắc nhở "Cập nhật thể trạng" chuẩn sáng/tối đồng bộ.
- Vào trang Chỉnh sửa hồ sơ, đảm bảo ô mục tiêu bị khóa. Bấm nút "Thiết lập lại từ đầu" và kiểm tra xem luồng hoạt động có reset và đưa người dùng quay lại màn hình Onboarding với các dữ liệu cũ được điền sẵn hay không.
- Nhập thiếu thông tin hoặc sai định dạng trên màn hình Đăng nhập/Đăng ký để xác nhận toàn bộ thông báo lỗi hiển thị rõ ràng bằng tiếng Việt có dấu.
- Tiến hành thực hiện quét cơ thể bằng AI, xác nhận tất cả thông tin phản hồi và các nút bấm ("Quét lại", "Chấp nhận"...) đều hiển thị có dấu chuẩn.
