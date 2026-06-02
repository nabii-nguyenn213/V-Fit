# V-FIT — Danh Sách Chức Năng Hiện Tại

> Tài liệu này liệt kê tất cả các chức năng đã implement trong V-FIT tính đến **31/05/2026**.
> Stack: Flutter 3.x (Dart ≥3.4) · Spring Boot 3 / Java 21 · MongoDB · JWT · Docker

---

## 🔐 Auth — Xác thực

| Chức năng | Màn hình / API | Trạng thái |
|---|---|---|
| Splash screen + route guard tự động | `/splash` | ✅ Hoàn chỉnh |
| Đăng ký tài khoản | `/register` · `POST /api/auth/register` | ✅ Hoàn chỉnh |
| Xác minh OTP qua email | `/register-otp` | ✅ Hoàn chỉnh |
| Đăng nhập | `/login` · `POST /api/auth/login` | ✅ Hoàn chỉnh |
| Refresh JWT token tự động | `POST /api/auth/refresh-token` | ✅ Hoàn chỉnh |
| Đăng xuất | `POST /api/auth/logout` | ✅ Hoàn chỉnh |
| Quên mật khẩu | `/forgot-password` · `POST /api/auth/forgot-password` | ✅ Hoàn chỉnh |
| Reset mật khẩu | `/reset-password` · `POST /api/auth/reset-password` | ✅ Hoàn chỉnh |
| Trang tài khoản bị vô hiệu hóa | `/deactivated` | ✅ Hoàn chỉnh |

---

## 🚀 Onboarding

| Chức năng | Màn hình / API | Trạng thái |
|---|---|---|
| Luồng onboarding bắt buộc sau đăng ký lần đầu | `/onboarding` | ✅ Hoàn chỉnh |
| Guard: chưa onboarding → chặn vào app | Router redirect | ✅ Hoàn chỉnh |
| Cancel & Logout an toàn khỏi onboarding | Nút Exit trong onboarding | ✅ Hoàn chỉnh |

---

## 🏠 Home — Trang chủ

| Chức năng | Màn hình | Trạng thái |
|---|---|---|
| Trang chủ tổng hợp thông tin | `/home` | ✅ Hoàn chỉnh |
| Bottom navigation shell (Home · Workout · Nutrition · Progress · Profile) | `AppShell` | ✅ Hoàn chỉnh |

---

## 💪 Workout — Tập luyện

| Chức năng | Màn hình / API | Trạng thái |
|---|---|---|
| Danh sách workout | `/workouts` · `GET /api/workouts` | ✅ Hoàn chỉnh |
| Chi tiết workout | `/workouts/:id` · `GET /api/workouts/{id}` | ✅ Hoàn chỉnh |
| Danh sách bài tập (exercises) | `/exercises` · `GET /api/exercises` | ✅ Hoàn chỉnh |
| Chi tiết bài tập | `/exercises/:id` · `GET /api/exercises/{id}` | ✅ Hoàn chỉnh |

---

## 📚 Exercise Library — Thư viện bài tập

| Chức năng | Màn hình | Trạng thái |
|---|---|---|
| Thư viện bài tập nhóm theo loại cơ | `ExerciseLibraryPage` | ✅ Hoàn chỉnh |
| Chi tiết nhóm bài tập | `ExerciseGroupDetailPage` | ✅ Hoàn chỉnh |

---

## 🍎 Nutrition — Dinh dưỡng

| Chức năng | Màn hình / API | Trạng thái |
|---|---|---|
| Theo dõi dinh dưỡng hàng ngày | `/nutrition` | ✅ Hoàn chỉnh |
| Danh sách thực phẩm | `GET /api/foods` · `GET /api/foods/{id}` | ✅ Hoàn chỉnh |
| Quét ảnh thức ăn AI | BLoC + widgets | 🔧 Đang phát triển |

---

## 📈 Progress — Tiến trình

| Chức năng | Màn hình | Trạng thái |
|---|---|---|
| Trang theo dõi tiến trình tổng hợp | `/progress` | ✅ Hoàn chỉnh |
| Biểu đồ body metrics (cân nặng, BMI, body fat...) | FL Chart | ✅ Hoàn chỉnh |
| Chụp ảnh body / tiến trình | DraggableCameraButton | ✅ Hoàn chỉnh |
| Xem lịch sử body metrics | `GET /api/users/me/body-metrics` | ✅ Hoàn chỉnh |

---

## 👤 Profile — Hồ sơ cá nhân

| Chức năng | Màn hình / API | Trạng thái |
|---|---|---|
| Xem hồ sơ cá nhân | `/profile` · `GET /api/users/me` | ✅ Hoàn chỉnh |
| Chỉnh sửa thông tin cá nhân | `/profile/edit` · `PUT /api/users/me` | ✅ Hoàn chỉnh |
| Đổi mật khẩu | `/profile/change-password` · `PUT /api/users/change-password` | ✅ Hoàn chỉnh |
| Upload avatar (Cloudinary) | `EditProfilePage` | ✅ Hoàn chỉnh |

---

## 🤖 AI Features

| Chức năng | Màn hình | Trạng thái |
|---|---|---|
| AI Form Check — kiểm tra tư thế qua camera | `/ai-form-check` · `AiFormCheckPage` | ✅ Hoàn chỉnh |
| AI Coaching cá nhân hóa (body analysis, food scan) | Backend module scaffolded | 🔧 Đang phát triển |

---

## 🎯 Personalized Workout — Tập luyện cá nhân hóa

| Chức năng | Layer | Trạng thái |
|---|---|---|
| Workout session (theo dõi buổi tập) | `WorkoutSessionNotifier` | ✅ Hoàn chỉnh |
| BLoC + widgets luyện tập cá nhân | `personalized_workout` | ✅ Hoàn chỉnh |

---

## 🏆 Gamification — Thách thức & Huy hiệu

| Chức năng | Màn hình / API | Trạng thái |
|---|---|---|
| Danh sách huy hiệu | `GET /api/gamification/badges` | ✅ Hoàn chỉnh |
| Thử thách (challenges) | `GET /api/gamification/challenges` | ✅ Hoàn chỉnh |
| Active challenge notifier | `ActiveChallengeNotifier` | ✅ Hoàn chỉnh |

---

## 💳 Payment — Thanh toán

| Chức năng | Layer | Trạng thái |
|---|---|---|
| Luồng thanh toán VIP/Premium | Payment BLoC | ✅ Hoàn chỉnh |
| Webhook SePay (xác nhận thanh toán) | Backend webhook handler | ✅ Hoàn chỉnh |
| Route `/premium` | Router | ✅ Hoàn chỉnh |

---

## 🛡️ Admin — Quản trị

| Chức năng | Màn hình / API | Trạng thái |
|---|---|---|
| Dashboard doanh thu | `/admin/revenue` · `GET /api/admin/dashboard` | ✅ Hoàn chỉnh |
| Danh sách người dùng | `GET /api/admin/users` | ✅ Hoàn chỉnh |
| Đổi role người dùng | `PUT /api/admin/users/{id}/role` | ✅ Hoàn chỉnh |
| Xóa người dùng | `DELETE /api/admin/users/{id}` | ✅ Hoàn chỉnh |
| Xem & cập nhật App Config | `GET/PUT /api/admin/app-config` | ✅ Hoàn chỉnh |
| Route guard: Admin → `/admin/revenue` tự động | Router redirect | ✅ Hoàn chỉnh |

---

## ⚙️ App Config & Infrastructure

| Chức năng | API | Trạng thái |
|---|---|---|
| Lấy cấu hình ứng dụng | `GET /api/app/config` | ✅ Hoàn chỉnh |
| Seeder dữ liệu ban đầu (admin, app config, domain data) | Bootstrap module | ✅ Hoàn chỉnh |
| JWT auth middleware + Spring Security 6 | Security module | ✅ Hoàn chỉnh |
| Docker Compose (Backend + MongoDB + Mongo Express) | `docker-compose.yml` | ✅ Hoàn chỉnh |
| Swagger / OpenAPI UI | `http://localhost:8080/swagger-ui.html` | ✅ Hoàn chỉnh |
| Cloudflare (CDN / Tunnel) | `CloudFlare/` | ✅ Hoàn chỉnh |

---

## 🔧 Scaffolded — Có khung, chưa implement đầy đủ

| Module | Mô tả |
|---|---|
| `subscription` | Quản lý gói đăng ký VIP (backend scaffolded) |
| `community` | Tính năng cộng đồng (backend scaffolded) |
| `notification` | Thông báo push (backend scaffolded) |
| `checkin` | Điểm danh hàng ngày (backend scaffolded) |
| AI food scan | Quét và phân tích dinh dưỡng qua ảnh thức ăn |
| AI body analysis | Phân tích hình thể qua ảnh |

---

## 📦 Tech Stack

| Layer | Công nghệ |
|---|---|
| **Frontend** | Flutter 3.x · Dart ≥3.4 · Riverpod · BLoC · GoRouter · Dio · Hive · FL Chart · Freezed |
| **Backend** | Java 21 · Spring Boot 3.3.5 · Spring Security 6 · JWT · MapStruct · Lombok · WebSocket · Resilience4j |
| **Database** | MongoDB · Redis |
| **Storage** | Cloudinary (avatar/ảnh) |
| **Payment** | SePay webhook |
| **DevOps** | Docker · Docker Compose · Cloudflare |
| **Docs** | Swagger / OpenAPI · Beads (issue tracker) |
