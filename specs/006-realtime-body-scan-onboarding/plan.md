# Kế Hoạch Triển Khai: Luồng Đăng Ký Quét Thể Trạng Real-time

**Nhánh**: `006-realtime-body-scan-onboarding` | **Ngày**: 10/06/2026 | **Tài liệu đặc tả**: [spec.md](file:///D:/EXE_PRM/specs/006-realtime-body-scan-onboarding/spec.md)

## Tóm tắt

Tích hợp tính năng phân tích thể trạng thời gian thực (real-time body analysis) vào luồng onboarding thay thế hoặc bổ sung cho việc tải ảnh thủ công. Người dùng có thể bắt đầu quét thể trạng thông qua camera. Ứng dụng Flutter sẽ kết nối đến AI backend qua WebSocket tại `/ws/ai/body-analysis`. Kết quả phân tích thể trạng hợp lệ đầu tiên (nơi `fallback == false` và `confidence > 0`) sẽ được chặn lại, luồng stream sẽ tự động ngắt và kết quả được lưu thông qua API REST mới `/api/v1/users/onboarding/realtime`. API này sẽ cập nhật mục tiêu của người dùng, đổi trạng thái `onboardingStatus` thành `COMPLETED`, lưu bản ghi `BodyAnalysisResult` vào MongoDB và chuyển hướng người dùng về `/home`.

## Bối cảnh kỹ thuật

- **Ngôn ngữ/Phiên bản**: Java 21 (Spring Boot 3.2.x), Dart 3.x (Flutter 3.x)
- **Thư viện chính**: `camera` package trong Flutter, WebSocket connections, `dio` trong Flutter, Spring Security & Spring WebSocket ở backend.
- **Cơ sở dữ liệu**: MongoDB (collections: `users`, `bodyAnalysisResult`)
- **Nền tảng mục tiêu**: Android, iOS và Backend service.

## Kiểm tra Constitution

Xác thực kế hoạch triển khai dựa trên hiến pháp V-FIT:
- Phân tích thể trạng và suy luận mục tiêu được xử lý bởi AI backend: Đạt.
- Bản ghi kết quả phân tích AI tuân thủ cấu trúc kiểu dữ liệu của `AiBodyAnalysisResult`: Đạt.
- Đảm bảo tính toàn vẹn của bảo mật và xác thực thông qua JWT: Đạt.

## Thay Đổi Đề Xuất

### Backend (VFIT_Backend)

#### [MODIFY] [OnboardingService.java](file:///D:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/service/OnboardingService.java)
- Khai báo phương thức `completeRealtimeBodyScan(AiBodyAnalysisResult request)` trả về `OnboardingResponse`.

#### [MODIFY] [OnboardingServiceImpl.java](file:///D:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/service/impl/OnboardingServiceImpl.java)
- Triển khai `completeRealtimeBodyScan(AiBodyAnalysisResult request)`.
- Lưu kết quả phân tích vào MongoDB collection `bodyAnalysisResult` với nguồn (`source`) là `"onboarding-realtime"`.
- Xoá cache `"personalized_workouts"` của người dùng hiện tại khỏi Spring cache.
- Cập nhật trạng thái `onboardingStatus` của người dùng thành `COMPLETED` và `active` thành `true`.
- Cập nhật mục tiêu thể hình (`goalType`) suy luận từ các chỉ số cơ thể.

#### [MODIFY] [OnboardingController.java](file:///D:/EXE_PRM/VFIT_Backend/src/main/java/com/vfit/modules/user/controller/OnboardingController.java)
- Thêm endpoint POST `/realtime` gọi tới `completeRealtimeBodyScan` trong service.

---

### Frontend (VFIT_Fontend)

#### [MODIFY] [api_endpoints.dart](file:///D:/EXE_PRM/VFIT_Fontend/lib/core/constants/api_endpoints.dart)
- Định nghĩa đường dẫn API mới: `static const onboardingRealtime = '/api/v1/users/onboarding/realtime';`

#### [MODIFY] [onboarding_repository.dart](file:///D:/EXE_PRM/VFIT_Fontend/lib/features/onboarding/data/repositories/onboarding_repository.dart)
- Triển khai phương thức `completeRealtimeBodyScan` để gọi endpoint API mới bằng POST request.

#### [MODIFY] [ai_realtime_camera_view.dart](file:///D:/EXE_PRM/VFIT_Fontend/lib/features/ai/presentation/widgets/ai_realtime_camera_view.dart)
- Cung cấp thêm callback `onFeedbackReceived` trong constructor.
- Khi nhận được dữ liệu phản hồi hợp lệ, tự động gọi `_stopStreaming()` và thực thi callback.

#### [MODIFY] [app_router.dart](file:///D:/EXE_PRM/VFIT_Fontend/lib/core/router/app_router.dart)
- Đăng ký GoRoute mới cho `/onboarding/body-scan-realtime` trỏ tới `AiOnboardingBodyScanPage`.

#### [MODIFY] [onboarding_page.dart](file:///D:/EXE_PRM/VFIT_Fontend/lib/features/onboarding/presentation/pages/onboarding_page.dart)
- Cập nhật giao diện Bước 1 (Body Scan) để hiển thị nút "Bắt đầu quét cơ thể realtime" dẫn đến `/onboarding/body-scan-realtime`.

#### [NEW] [ai_onboarding_body_scan_page.dart](file:///D:/EXE_PRM/VFIT_Fontend/lib/features/onboarding/presentation/pages/ai_onboarding_body_scan_page.dart)
- Xây dựng trang quét thể trạng thời gian thực sử dụng `AiRealtimeCameraView`.
- Đăng ký callback `onFeedbackReceived`: khi nhận kết quả phân tích hợp lệ đầu tiên, tắt camera/websocket, gọi repository để lưu vào DB, cập nhật trạng thái auth của người dùng và chuyển hướng về `/home`.

## Kế Hoạch Xác Minh

### Kiểm Thử Tự Động
- Chạy lệnh `mvn test` trong `VFIT_Backend` để chạy unit test cho phần Onboarding.

### Kiểm Thử Thủ Công
- Thực hiện đăng ký tài khoản mới và đi qua luồng onboarding.
- Đứng trước camera để quét thể trạng và xác nhận trang tự động đóng và chuyển hướng sang trang chủ `/home` ngay khi phát hiện posture thành công.
- Kiểm tra dữ liệu trong MongoDB xem trạng thái user đã đổi thành COMPLETED và active chưa, và bản ghi bodyAnalysisResult có được lưu chính xác với nguồn `"onboarding-realtime"` hay không.
