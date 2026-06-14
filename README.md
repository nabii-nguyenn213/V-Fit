# V-FIT AI-Native Fitness Ecosystem

Chào mừng bạn đến với **V-FIT** – Hệ sinh thái hỗ trợ luyện tập thể hình thông minh tích hợp AI. Tài liệu này là nguồn thông tin duy nhất (Single Source of Truth) hướng dẫn cài đặt, kiến trúc hệ thống, phát triển local và triển khai thực tế.

---

## 1. Bản Đồ Thư Mục & Stack Công Nghệ

### Bản đồ thư mục (Folder Map)

```text
V-FIT/
├── VFIT_Backend/           # Java 21 & Spring Boot 3.3.5 Backend Gateway
├── VFIT_Fontend/           # Flutter 3.x Mobile Client App
├── AI-VFIT/
│   └── V-Fit/              # AI Core (Recommendation System, CV Engine)
│       ├── RecommendationSystem/  # FastAPI (port 8000) - AI Coach, Planners
│       └── api_server.py          # Flask (port 5000) - Real-time Form Check
├── gemini-web2api/         # AI Service Gateway nội bộ (port 8081)
├── skills/
│   ├── conversation/       # Quản lý prompts hệ thống tập trung
│   └── tech-decision/      # Nhật ký quyết định kiến trúc
└── specs/                  # Tài liệu đặc tả và kế hoạch Spec Kit
```

### Stack Công Nghệ (Tech Stack)

| Layer | Công nghệ |
|---|---|
| **Frontend** | Flutter 3.x · Dart ≥3.4 · Riverpod · BLoC · GoRouter · Dio · Hive · FL Chart · Freezed |
| **Backend** | Java 21 · Spring Boot 3.3.5 · Spring Security 6 · JWT · MapStruct · Lombok · WebSocket · Resilience4j |
| **AI Python Core** | FastAPI · Flask · OpenCV · MediaPipe Pose · Ultralytics YOLOv8 · Gemini API |
| **Database** | MongoDB · Redis |
| **DevOps** | Docker · Docker Compose · Cloudflare Tunnel |

---

## 2. Các Nguyên Tắc Cốt Lõi & Hướng Dẫn Phát Triển

### Nguyên tắc Hiến pháp (Constitution Principles)

1. **AI-Native Control Plane**: AI là tầng quyết định cho huấn luyện và phân tích. Mọi logic phụ thuộc vào AI phải đi qua một hợp đồng rõ ràng. Backend Spring Boot thực hiện xác thực, giới hạn tần suất (rate-limit), lưu trữ và kiểm toán.
2. **Prompt Governance**: Tất cả prompts chạy trong runtime phải nằm tại `skills/conversation/`.
3. **Data Boundary Discipline**: Dữ liệu đầu vào gửi cho AI phải được tối giản hóa và cấp quyền. Đầu ra từ AI phải được parse thành DTO chặt chẽ và xử lý fallback trước khi hiển thị lên giao diện.
4. **Observable Modular Monolith**: Backend duy trì cấu trúc Monolith phân rã theo module rõ ràng. Giao tiếp giữa các module ưu tiên sử dụng Spring Events để tăng tính độc lập.

### Quy Trình Làm Việc Với Beads Issue Tracker

Dự án sử dụng **bd (beads)** để quản lý tác vụ:

```bash
bd ready              # Tìm tác vụ sẵn sàng làm việc
bd show <id>          # Xem chi tiết tác vụ
bd update <id> --claim  # Nhận tác vụ để thực hiện
bd close <id>         # Đóng tác vụ khi hoàn thành
bd dolt push          # Đẩy dữ liệu beads lên remote
```

**Quy trình kết thúc phiên làm việc (Session Completion)**:
1. Tạo issue cho các công việc còn tồn đọng nếu cần thiết.
2. Chạy các cổng kiểm thử chất lượng (Tests, linters, builds).
3. Đóng các task hoàn thành và đồng bộ trạng thái.
4. **PUSH TO REMOTE (Bắt buộc)**:
   ```bash
   git pull --rebase
   git push
   git status  # Phải hiển thị "up to date with origin"
   ```

---

## 3. Danh Sách Tính Năng & Trạng Thái

| Module | Tính năng | Trạng thái |
|---|---|---|
| **🔐 Auth** | Splash screen, Đăng ký/Đăng nhập, OTP qua email, Quên/Reset mật khẩu, Refresh token tự động, Social Login (Google/Facebook) | ✅ Hoàn chỉnh |
| **🚀 Onboarding** | Điền thông tin cá nhân bắt buộc, Route Guard chuyển hướng người dùng mới | ✅ Hoàn chỉnh |
| **🏠 Home** | Giao diện dashboard tổng hợp, Grid Command điều hướng | ✅ Hoàn chỉnh |
| **💪 Workout** | Xem danh sách/chi tiết workout, Danh sách/chi tiết bài tập, Workout Session tracking | ✅ Hoàn chỉnh |
| **🍎 Nutrition** | Nhật ký ăn uống, Tính macros/calories | ✅ Hoàn chỉnh |
| **📈 Progress** | Biểu đồ cân nặng/BMI/Body Fat, Chụp ảnh tiến trình lưu trữ | ✅ Hoàn chỉnh |
| **💳 Payment** | Gói VIP Premium, Webhook SePay VietQR tự động nâng cấp VIP | ✅ Hoàn chỉnh |
| **🤖 AI Coach** | Chat trực tiếp nhận lời khuyên dinh dưỡng, tập luyện dựa trên body metrics (Gated VIP) | ✅ Hoàn chỉnh |
| **🤖 AI Form Check** | Phát hiện sai tư thế thời gian thực qua camera và đưa ra âm thanh sửa đổi | ✅ Hoàn chỉnh |
| **🤖 AI Body Scan** | Quét hình dáng người gầy/béo và lệch vẹo (imbalance) qua camera | ✅ Hoàn chỉnh |

---

## 4. Cấu Hình & Chạy Local

Hệ thống AI và Backend của V-FIT gồm 4 thành phần chạy ở các port khác nhau khi phát triển dưới local:

```text
Flutter Client (App)
       │
       ├───► Spring Boot Backend Gateway (Port 8080) ───► Flask Real-time API (Port 5000)
       │
       └───► FastAPI Recommendation System (Port 8000) ──► gemini-web2api (Port 8081)
```

### Bước 1: Khởi động gemini-web2api (Port 8081)
Dịch vụ dịch thuật API Gemini sang định dạng tương thích OpenAI:
```bash
cd gemini-web2api
pip install httpx
python gemini_web2api.py
# Lắng nghe tại: http://localhost:8081
```

### Bước 2: Khởi động FastAPI RecommendationSystem (Port 8000)
Chịu trách nhiệm cho AI Coach, Workout/Meal Planner:
```bash
cd AI-VFIT/V-Fit/RecommendationSystem
pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8000
# Swagger docs: http://127.0.0.1:8000/docs
```

### Bước 3: Khởi động Flask AI API Server (Port 5000)
Chạy AI Computer Vision phục vụ Form Check và Body Scan thời gian thực:
```bash
cd AI-VFIT/V-Fit
pip install -r requirements.txt
python api_server.py
# Lắng nghe tại: http://localhost:5000
```

### Bước 4: Khởi động Spring Boot Backend (Port 8080)
Cổng gateway chính của hệ sinh thái:
1. Đảm bảo cấu hình file `VFIT_Backend/.env` trỏ đúng tới Flask API:
   ```env
   AI_CLIENT_MODE=http
   AI_BASE_URL=http://localhost:5000
   ```
2. Chạy dịch vụ:
   ```bash
   cd VFIT_Backend
   mvn spring-boot:run
   ```

### Bước 5: Chạy ứng dụng Flutter
1. Đảm bảo file cấu hình `environment.dart` có `aiBaseUrlCandidates` trỏ đúng IP máy tính (nếu dùng thiết bị thật) hoặc `10.0.2.2` (nếu dùng Emulator):
   - `apiBaseUrl` -> Cổng 8080 (Spring Boot)
   - `aiBaseUrl` -> Cổng 8000 (FastAPI Recommendation System)
2. Khởi chạy dự án:
   ```bash
   cd VFIT_Fontend
   flutter run
   ```

---

## 5. Tích Hợp Real-Time AI Camera (WebSocket)

Để đạt hiệu năng thời gian thực và độ trễ thấp khi quét tư thế/dáng người, V-FIT sử dụng WebSocket truyền tải dữ liệu trực tiếp:

```text
Flutter App  ───(WebSocket stream video frame)───►  Spring Boot Backend Gateway
                                                          │
                                                    (HTTP POST frame)
                                                          ▼
Flutter App  ◄───(WebSocket send feedback)────────  Flask AI API (Port 5000)
```

### Các Endpoint WebSocket Thực Tế (Backend & App):

- **AI Form Checking**: `ws://<host>:8080/ws/ai/form-check`
- **AI Body Analysis**: `ws://<host>:8080/ws/ai/body-analysis`

*Lưu ý quan trọng*: Đường dẫn trong tài liệu phát triển cũ từng bị viết nhầm thành `/api/ai/form-check`. Đường dẫn chính xác bắt buộc phải sử dụng tiền tố `/ws/` để khớp với cơ chế lọc bảo mật và điều phối kết nối của Spring Security.

---

## 6. Ma Trận Cấu Hình Đồng Bộ (Configuration Verification Matrix)

Dưới đây là bảng đối chiếu cấu hình quan trọng để đảm bảo quá trình đưa sản phẩm lên Server và App không bị lệch:

| Cấu hình | Môi trường Local | Môi trường Staging/VPS | Ghi chú |
|---|---|---|---|
| **Spring Boot Gateway Port** | `8080` | `8080` (hoặc cấu hình thông qua Reverse Proxy HTTPS) | Cần mở cổng `8080` cho kết nối REST & WebSocket. |
| **FastAPI RecSystem Port** | `8000` | `8000` | Cần mở cổng `8000` hoặc route domain riêng (ví dụ: `https://ai-coach.vfit.com`). |
| **Flask API Server Port** | `5000` | `5000` (Không cần Public ra ngoài) | Chỉ Spring Boot kết nối nội bộ đến Flask qua mạng Docker. |
| **gemini-web2api Port** | `8081` | `8081` (Không cần Public ra ngoài) | Chỉ FastAPI kết nối nội bộ đến dịch vụ này qua localhost. |
| **Spring Boot -> Flask Link** | `AI_BASE_URL=http://localhost:5000` | `AI_BASE_URL=http://vfit-ai-api:5000` | Khi chạy Docker Compose, dùng tên service làm host. |
| **FastAPI -> web2api Link** | `http://localhost:8081/v1` | `http://localhost:8081/v1` | Luôn gọi thông qua localhost nội bộ của server. |
| **Flutter `apiBaseUrl`** | `http://10.0.2.2:8080` (Emulator) | `https://api.vfit.com` | Tên miền chính thức của API Gateway. |
| **Flutter `aiBaseUrl`** | `http://10.0.2.2:8000` (Emulator) | `https://ai-coach.vfit.com` | Tên miền chính thức của FastAPI AI Recommendation. |

### Hướng Dẫn Deploy VPS bằng Docker Compose
Khi deploy lên môi trường Staging/Production bằng Docker:
1. Chạy lệnh:
   ```bash
   cd VFIT_Backend
   docker-compose up -d --build
   ```
2. Docker Compose sẽ tự động thiết lập và liên kết các container thông qua mạng nội bộ:
   - Container `vfit-backend` giao tiếp với `vfit-ai-api` bằng alias `http://vfit-ai-api:5000`.
   - Nginx hoặc Cloudflare Tunnel sẽ đảm nhận nhiệm vụ chuyển tiếp lưu lượng HTTPS ngoài internet tới các cổng tương ứng của Gateway.
