# Kế hoạch triển khai: Kết nối và tích hợp Backend AI

**Nhánh**: `web2api` | **Ngày**: 2026-06-14 | **Tài liệu đặc tả**: [spec.md](file:///d:/EXE_PRM/specs/007-connect-ai-web2api/spec.md)

## Tóm tắt

Thiết lập một cầu nối truyền thông an toàn, hiệu quả và đáng tin cậy giữa ứng dụng di động Flutter, cổng kết nối Spring Boot và RecommendationSystem chạy FastAPI (sử dụng gói wrapper `gemini-web2api` chạy local để truy vấn Gemini). Chúng tôi sẽ cấu hình ứng dụng Flutter với các biến môi trường để định tuyến động các yêu cầu AI và xử lý các URL cơ sở dự phòng (fallback). Đồng thời, chúng tôi cũng sẽ triển khai tính năng AI đầu tiên (cụ thể là AI Coach) trong Flutter, bao gồm cả cổng kiểm tra quyền truy cập VIP.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: Dart 3.x, Python 3.11, Java 17

**Thành phần phụ thuộc chính**: 
- Flutter: Dio, Riverpod, GoRouter
- FastAPI: Uvicorn, requests, python-dotenv
- gemini-web2api: httpx

**Lưu trữ**: MongoDB (để lưu trạng thái người dùng V-FIT và các chỉ số), Redis (để cache session và giới hạn lượt gọi - rate limit)

**Kiểm thử**: Xác minh thủ công bằng Swagger, Postman và chạy thử trực tiếp trên Flutter.

**Nền tảng đích**: Android, iOS, Web

**Loại dự án**: Ứng dụng di động + Dịch vụ API backend

**Mục tiêu hiệu năng**: 
- Dưới 10 giây cho các truy vấn LLM thông thường.
- Dưới 2 giây cho việc chuyển đổi trạng thái giao diện UI.

**Ràng buộc**: 
- Các tính năng AI yêu cầu người dùng phải hoàn thành onboarding (`COMPLETED`) và có gói VIP đang hoạt động (`isVipActive = true`).
- Lượt gọi API từ client tuyệt đối không được gọi trực tiếp tới cổng `gemini-web2api` (8081). Chỉ được phép gọi qua RecommendationSystem (8000) hoặc Spring Boot (8080).

## Kiểm tra hiến pháp (Constitution Check)

*GATE: Phải vượt qua trước khi tiến hành nghiên cứu Phase 0. Kiểm tra lại sau thiết kế Phase 1.*

Xác minh kế hoạch triển khai với hiến pháp dự án V-FIT:

- **AI-native control plane**: Hợp lệ. Các tính năng huấn luyện viên và lập kế hoạch được định tuyến qua FastAPI.
- **Tệp prompt**: Hợp lệ. Các file prompt sẽ được lưu trữ trong thư mục `skills/conversation/` và tải vào RecommendationSystem lúc chạy thay vì code cứng trong file Python.
- **Ranh giới dữ liệu**: Hợp lệ. Flutter sẽ tối giản hóa dữ liệu đầu vào trước khi gửi đi.
- **Modular Monolith**: Hợp lệ. Spring Boot backend giữ vai trò xác thực quyền hạn và gói cước của người dùng một cách nhất quán.
- **Cổng Premium**: Hợp lệ. Ứng dụng kiểm tra `user.isVipActive` trước khi cấp quyền truy cập AI Coach.

## Cấu trúc dự án

### Tài liệu (tính năng này)

```text
specs/007-connect-ai-web2api/
├── plan.md              # Tệp này
├── research.md          # Kết quả Phase 0
├── data-model.md        # Kết quả Phase 1
├── quickstart.md        # Hướng dẫn chạy nhanh Phase 1
└── contracts/           # Hợp đồng API Phase 1
    └── coach_contract.json
```

### Mã nguồn (Thư mục gốc)

```text
AI-VFIT/
└── V-Fit/
    └── RecommendationSystem/
        ├── services/
        │   └── coach_router.py
        └── main.py

VFIT_Fontend/
├── lib/
│   ├── core/
│   │   ├── config/
│   │   │   └── environment.dart
│   │   └── network/
│   │       └── network_providers.dart
│   └── features/
│       └── ai/
│           ├── data/
│           │   ├── models/
│           │   │   └── coach_message_model.dart
│           │   └── repositories/
│           │       └── ai_coach_repository.dart
│           └── presentation/
│               ├── pages/
│               │   └── ai_coach_page.dart
│               └── providers/
│                   └── ai_coach_provider.dart
```

**Quyết định cấu trúc**: Kết hợp giữa Web app và Mobile + API. Cả hai repo FastAPI Python và Flutter sẽ được cập nhật.

## Theo dõi độ phức tạp

*Không phát hiện vi phạm hiến pháp nào.*
