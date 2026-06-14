# Danh sách nhiệm vụ: Kết nối và tích hợp Backend AI

**Đầu vào**: Các tài liệu thiết kế từ `/specs/007-connect-ai-web2api/`

**Điều kiện tiên quyết**: plan.md, spec.md, research.md, data-model.md, contracts/

## Định dạng: `[ID] [P?] [Story] Mô tả nhiệm vụ`

- **[P]**: Có thể thực hiện song song (ở các tệp tin khác nhau, không có quan hệ phụ thuộc lẫn nhau).
- **[Story]**: Nhiệm vụ thuộc kịch bản người dùng nào (ví dụ: US1, US2).
- Bao gồm đường dẫn tệp cụ thể trong phần mô tả.

---

## Phase 1: Thiết lập (Setup - Cơ sở hạ tầng chung)

**Mục tiêu**: Chuẩn bị môi trường và chạy thử nghiệm cục bộ pipeline AI

- [x] T001 Khởi chạy dịch vụ `gemini-web2api` trên cổng 8081 và `RecommendationSystem` trên cổng 8000. Kiểm tra khả năng phản hồi của API thông qua cURL hoặc Swagger.

---

## Phase 2: Nền tảng (Foundational - Các điều kiện tiên quyết chặn)

**Mục tiêu**: Thiết lập cấu hình mạng trong Flutter và quản lý Prompt trong Backend AI theo đúng Hiến pháp dự án.

**⚠️ QUAN TRỌNG**: Không kịch bản người dùng nào có thể bắt đầu cho đến khi hoàn thành xong phase này.

- [x] T002 Tạo tệp lưu trữ prompt hệ thống `skills/conversation/coach_prompt.md` để lưu nội dung prompt dành cho AI Coach.
- [x] T003 [P] Chỉnh sửa `AI-VFIT/V-Fit/RecommendationSystem/services/coach_router.py` để đọc prompt động từ tệp `skills/conversation/coach_prompt.md` khi chạy.
- [x] T004 Khai báo `aiBaseUrl` và `aiBaseUrlCandidates` tương thích với Emulator Android (10.0.2.2) và thiết bị thật trong `VFIT_Fontend/lib/core/config/environment.dart`.
- [x] T005 [P] Đăng ký `aiDioProvider` và cấu hình interceptor tự động chuyển đổi URL fallback `LocalAiFallbackInterceptor` trong `VFIT_Fontend/lib/core/network/network_providers.dart`.

**Checkpoint**: Nền tảng cấu hình mạng và Prompt đã sẵn sàng - có thể tiến hành triển khai các kịch bản người dùng tiếp theo.

---

## Phase 3: Kịch bản người dùng 1 - Tích hợp cấu hình client và kiểm tra kết nối AI (US1) 🎯 MVP

**Mục tiêu**: Triển khai tầng dữ liệu (data layer) trong Flutter để gọi API AI Coach.

**Kiểm thử độc lập**: Gọi trực tiếp repository hoặc provider test để kiểm tra xem dữ liệu phản hồi từ API `/api/v1/coach/` có được nhận và ánh xạ đúng cấu trúc hay không.

- [x] T006 [P] [US1] Định nghĩa lớp `CoachMessageModel` đại diện cho tin nhắn chat trong `VFIT_Fontend/lib/features/ai/data/models/coach_message_model.dart`.
- [x] T007 [US1] Triển khai lớp repository `AiCoachRepository` để gửi yêu cầu chat tới FastAPI endpoint `/api/v1/coach/` trong `VFIT_Fontend/lib/features/ai/data/repositories/ai_coach_repository.dart`.

**Checkpoint**: Tầng dữ liệu kết nối AI Coach đã hoạt động độc lập và đầy đủ.

---

## Phase 4: Kịch bản người dùng 2 - Giao diện chat AI Coach & Phân quyền VIP (US2)

**Mục tiêu**: Xây dựng giao diện chat AI Coach, tích hợp GoRouter và áp dụng cổng bảo mật VIP cho người dùng Premium.

**Kiểm thử độc lập**: Đăng nhập bằng tài khoản không phải VIP, nhấn vào AI Coach để đảm bảo hiển thị banner quảng cáo. Đăng nhập bằng tài khoản VIP để đảm bảo có thể gửi tin nhắn chat và nhận phản hồi bình thường.

- [x] T008 [P] [US2] Triển khai lớp notifier quản lý trạng thái trò chuyện `AiCoachNotifier` trong `VFIT_Fontend/lib/features/ai/presentation/providers/ai_coach_provider.dart`.
- [x] T009 [US2] Xây dựng trang giao diện chat `AiCoachPage` tại `VFIT_Fontend/lib/features/ai/presentation/pages/ai_coach_page.dart` với phong cách glassmorphism, tích hợp logic kiểm tra `user.isVipActive` và hiển thị banner nâng cấp VIP.
- [x] T010 [US2] Tích hợp route `/ai/coach` trỏ đến `AiCoachPage` trong `VFIT_Fontend/lib/core/router/app_router.dart`.
- [x] T011 [US2] Thêm nút truy cập AI Coach trên trang chủ `HomePage` (`VFIT_Fontend/lib/features/home/presentation/pages/home_page.dart`) hoặc màn hình hồ sơ cá nhân `ProfilePage`.

**Checkpoint**: Giao diện người dùng và kiểm soát quyền VIP đã hoạt động đầy đủ.

---

## Phase 5: Hoàn thiện & Đánh giá (Polish)

**Mục tiêu**: Kiểm thử các trường hợp biên và xử lý lỗi kết nối ngoại tuyến.

- [x] T012 Tiến hành tắt kết nối mạng hoặc tắt API cổng 8000 để kiểm tra thông báo lỗi hiển thị rõ ràng trên màn hình `AiCoachPage`.
- [x] T013 Viết tài liệu hướng dẫn nhanh hoặc tài liệu nghiệm thu tính năng.

---

## Quan hệ phụ thuộc & Thứ tự thực hiện

- **Phase 1 & 2**: Là điều kiện tiên quyết bắt buộc. Phải cấu hình xong `environment.dart` và `network_providers.dart` mới có thể gọi API trong Flutter.
- **Phase 3 (US1)**: Phải hoàn thành trước Phase 4 (US2) vì giao diện UI cần dùng `AiCoachRepository` từ tầng dữ liệu để giao tiếp.
