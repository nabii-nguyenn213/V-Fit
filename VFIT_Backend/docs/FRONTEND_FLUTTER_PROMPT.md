# Prompt Code Frontend Flutter V-FIT

Bạn là Senior Flutter Architect. Hãy code frontend Flutter production-ready cho app V-FIT, kết nối đúng với backend Spring Boot hiện tại.

Không viết demo đơn giản. Hãy dựng project thật, dễ mở rộng, bảo trì, có kiến trúc rõ ràng, có state/error/loading đầy đủ và kết nối API thật.

## 1. Tech Stack

- Flutter latest stable
- Dart null-safety
- State management: Riverpod
- HTTP client: Dio
- Secure token storage: flutter_secure_storage
- Non-sensitive local storage: SharedPreferences
- Routing: GoRouter
- Model serialization: json_serializable hoặc freezed + json_serializable
- Form validation rõ ràng
- Không hardcode API URL, dùng config qua `--dart-define`

Package cần thêm vào `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: latest
  dio: latest
  go_router: latest
  flutter_secure_storage: latest
  shared_preferences: latest
  json_annotation: latest
  freezed_annotation: latest
  jwt_decoder: latest
  intl: latest

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: latest
  build_runner: latest
  json_serializable: latest
  freezed: latest
```

## 2. Backend Contract Bắt Buộc Phải Match

Base URL local:

- Android emulator: `http://10.0.2.2:8080`
- iOS simulator / desktop / web local: `http://localhost:8080`
- Physical phone: `http://<LAN_IP>:8080`
- Production: `https://api.your-domain.com`

Config trong Flutter:

```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);
```

Tất cả response thành công của backend có dạng:

```json
{
  "success": true,
  "message": "OK",
  "data": {},
  "timestamp": "2026-05-18T..."
}
```

Response lỗi có dạng:

```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "Unauthorized",
  "path": "/api/...",
  "details": [],
  "timestamp": "2026-05-18T..."
}
```

Response phân trang nằm trong `data`:

```json
{
  "content": [],
  "page": 0,
  "size": 20,
  "totalElements": 100,
  "totalPages": 5,
  "last": false
}
```

## 3. API Hiện Backend Đã Có

Public:

- `GET /api/app/config`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh-token`
- `POST /api/auth/logout`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`

Protected, cần header `Authorization: Bearer <accessToken>`:

- `GET /api/users/me`
- `PUT /api/users/me`
- `PUT /api/users/change-password`
- `GET /api/users/me/body-metrics`
- `GET /api/exercises?muscleGroup=&difficulty=&keyword=&page=&size=`
- `GET /api/exercises/{id}`
- `GET /api/workouts?page=&size=`
- `GET /api/workouts/{id}`
- `GET /api/foods?keyword=&page=&size=`
- `GET /api/foods/{id}`
- `GET /api/gamification/badges?page=&size=`
- `GET /api/gamification/challenges?page=&size=`

Admin optional, chỉ role `ADMIN`:

- `GET /api/admin/dashboard`
- `GET /api/admin/users?role=&page=&size=`
- `PUT /api/admin/users/{id}/role`
- `DELETE /api/admin/users/{id}`
- `GET /api/admin/app-config`
- `PUT /api/admin/app-config`

Các API chưa có ở backend hiện tại, không được call thật trong FE:

- Workout generate/start/complete/history
- Nutrition meal plan / meal log
- AI form check / body analysis
- Subscription/payment
- Community posts/comments/reports
- Notification
- Gamification me/join/complete/leaderboard

Với các module chưa có API, hãy dựng UI placeholder và repository interface sẵn, nhưng không gọi network endpoint chưa tồn tại. Hiển thị empty/coming soon state chuyên nghiệp.

## 4. Auth Contract

Register body:

```json
{
  "email": "user@example.com",
  "password": "Password1",
  "fullName": "Nguyen Van A"
}
```

Login body:

```json
{
  "email": "user@example.com",
  "password": "Password1"
}
```

Password rule backend:

- Ít nhất 8 ký tự
- Có ít nhất 1 chữ hoa
- Có ít nhất 1 chữ số

Auth response `data`:

```json
{
  "user": {
    "id": "...",
    "email": "user@example.com",
    "fullName": "Nguyen Van A",
    "avatarUrl": null,
    "gender": null,
    "dateOfBirth": null,
    "goalType": null,
    "role": "USER",
    "active": true,
    "xp": 0,
    "level": 1,
    "subscriptionStatus": "FREE",
    "createdAt": "..."
  },
  "tokens": {
    "accessToken": "...",
    "refreshToken": "...",
    "tokenType": "Bearer",
    "expiresInMs": 900000
  }
}
```

Refresh token body:

```json
{
  "refreshToken": "..."
}
```

Logout body:

```json
{
  "refreshToken": "..."
}
```

Yêu cầu auth:

- Lưu `accessToken`, `refreshToken`, `expiresAt`, `user` trong secure storage nếu nhạy cảm.
- Auto login nếu access token còn hạn.
- Nếu access token hết hạn hoặc API trả 401, Dio interceptor phải refresh token một lần.
- Nếu refresh fail, clear storage và chuyển về login.
- Logout gọi `/api/auth/logout`, sau đó clear local state/storage.
- Decode JWT được phép dùng `jwt_decoder`, nhưng source of truth user vẫn lấy từ `/api/users/me` sau khi app mở.

## 5. Enum Phải Match Backend

Role:

```text
USER, PREMIUM_USER, COACH, ADMIN
```

Gender:

```text
MALE, FEMALE, OTHER
```

GoalType:

```text
LOSE_WEIGHT, GAIN_MUSCLE, MAINTAIN, IMPROVE_ENDURANCE, IMPROVE_MOBILITY
```

DifficultyLevel:

```text
BEGINNER, INTERMEDIATE, ADVANCED
```

SubscriptionStatus:

```text
FREE, ACTIVE, EXPIRED, CANCELED
```

## 6. Models Cần Tạo

Core API:

- `ApiResponse<T>`
- `ApiError`
- `PageResponse<T>`

Auth:

- `LoginRequest`
- `RegisterRequest`
- `RefreshTokenRequest`
- `TokenResponse`
- `AuthResponse`

User:

- `UserModel`
- `UpdateProfileRequest`
- `ChangePasswordRequest`
- `BodyMetricModel`

App:

- `AppConfigModel`

Catalog:

- `ExerciseModel`
- `WorkoutProgramModel`
- `FoodModel`
- `BadgeModel`
- `ChallengeModel`

## 7. Cấu Trúc Thư Mục Bắt Buộc

```text
lib/
 ├─ core/
 │   ├─ constants/
 │   ├─ config/
 │   ├─ network/
 │   ├─ router/
 │   ├─ theme/
 │   ├─ utils/
 │   └─ widgets/
 ├─ features/
 │   ├─ auth/
 │   │   ├─ data/
 │   │   ├─ domain/
 │   │   ├─ application/
 │   │   └─ presentation/
 │   ├─ home/
 │   ├─ profile/
 │   ├─ workout/
 │   ├─ nutrition/
 │   └─ progress/
 └─ main.dart
```

Trong mỗi feature chính, dùng cấu trúc:

```text
feature/
 ├─ data/
 │   ├─ models/
 │   ├─ services/
 │   └─ repositories/
 ├─ domain/
 │   ├─ entities/
 │   └─ repositories/
 ├─ application/
 │   └─ providers/
 └─ presentation/
     ├─ pages/
     └─ widgets/
```

## 8. UI/UX Yêu Cầu

- Mobile-first responsive.
- Theme sáng/tối.
- Màu chủ đạo fitness hiện đại: xanh năng lượng, đen/xám trung tính, accent cam hoặc lime.
- Component tái sử dụng:
  - `AppButton`
  - `AppTextField`
  - `AppCard`
  - `AppDialog`
  - `LoadingView`
  - `ErrorView`
  - `EmptyView`
- Navigation bằng bottom navigation sau login:
  - Home
  - Workout
  - Nutrition
  - Progress
  - Profile
- Splash/Auth gate:
  - Check token
  - Fetch `/api/app/config`
  - Nếu maintenanceMode true thì hiển thị maintenance screen
  - Nếu authenticated thì vào Home
  - Nếu chưa authenticated thì vào Login

## 9. Screen Bắt Buộc

Auth:

- Splash screen
- Login screen
- Register screen
- Forgot password screen
- Reset password screen

Home:

- Greeting từ user fullName
- XP/level summary
- Quick cards: workouts, nutrition, progress
- App config slogan/support info nếu có

Profile:

- View `/api/users/me`
- Edit profile `/api/users/me`
- Body metrics `/api/users/me/body-metrics`
- Change password
- Logout
- Role/subscription badge

Workout:

- List workouts từ `/api/workouts`
- Workout detail từ `/api/workouts/{id}`
- Exercise list/filter từ `/api/exercises`
- Exercise detail từ `/api/exercises/{id}`
- Các action start/complete/generate để disabled hoặc coming soon vì backend chưa có endpoint thật.

Nutrition:

- Food list từ `/api/foods`
- Search food bằng `keyword`
- Food detail từ `/api/foods/{id}`
- Meal plan/log UI placeholder vì backend chưa có endpoint thật.

Progress:

- XP/level lấy từ user
- Body metrics card
- Badges từ `/api/gamification/badges`
- Challenges từ `/api/gamification/challenges`
- Join/complete/leaderboard disabled hoặc coming soon vì backend chưa có endpoint thật.

Admin optional:

- Nếu user role `ADMIN`, hiển thị entry admin nhỏ trong Profile.
- Admin dashboard gọi `/api/admin/dashboard`.
- Admin user list gọi `/api/admin/users`.
- Nếu không đủ thời gian, dựng route guard và placeholder, không phá core user app.

## 10. Networking Requirements

Tạo:

- `DioClient`
- `AuthInterceptor`
- `TokenStorage`
- `ApiException`
- `NetworkResult` hoặc dùng `AsyncValue` chuẩn Riverpod

Dio config:

- Base URL từ `AppConfig`
- Timeout rõ ràng
- JSON headers
- Log interceptor chỉ bật debug
- Attach bearer token cho protected endpoints
- Không attach bearer cho:
  - `/api/auth/login`
  - `/api/auth/register`
  - `/api/auth/refresh-token`
  - `/api/auth/forgot-password`
  - `/api/auth/reset-password`
  - `/api/app/config`

HTTP error handling:

- 400: show validation/server message
- 401: refresh token once, nếu fail logout
- 403: show forbidden screen/dialog
- 404: show not found
- 500: show generic server error
- Network timeout/offline: show retry UI

## 11. Routing Requirements

Dùng GoRouter:

- `/splash`
- `/login`
- `/register`
- `/forgot-password`
- `/reset-password`
- `/home`
- `/workouts`
- `/workouts/:id`
- `/exercises`
- `/exercises/:id`
- `/nutrition`
- `/foods/:id`
- `/progress`
- `/profile`
- `/profile/edit`
- `/profile/change-password`
- `/admin` optional

Route guard:

- Chưa login không được vào protected routes.
- Đã login không quay lại login/register trừ khi logout.
- Admin route chỉ cho role `ADMIN`.

## 12. Code Quality

- Không expose DTO lung tung trong UI nếu có domain entity.
- Repository chịu trách nhiệm gọi service/API.
- Provider/controller xử lý state.
- Page chỉ render UI và gọi provider action.
- Không hardcode string API path rải rác; gom vào `ApiEndpoints`.
- Tách validation vào util/helper.
- Comment những phần quan trọng như token refresh flow, route guard, API wrapper parser.
- Có file README hướng dẫn chạy.

## 13. Output Cần Trả Về

Hãy tạo full source code Flutter theo đúng path.

Bắt buộc output:

1. Cây thư mục.
2. `pubspec.yaml`.
3. Code từng file quan trọng theo đúng path.
4. Không thiếu import.
5. Không dùng placeholder kiểu `TODO` cho các chức năng backend đã có.
6. Với chức năng backend chưa có, ghi rõ UI placeholder/coming soon và không call endpoint giả.
7. Hướng dẫn chạy:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

8. Ví dụ login admin local:

```text
email: admin@vfit.com
password: Admin@123
```

9. Ghi chú khi chạy bằng điện thoại thật:

```bash
flutter run --dart-define=API_BASE_URL=http://<IP_LAN_MAY_CHAY_BACKEND>:8080
```

10. Ghi chú production:

```bash
flutter run --release --dart-define=API_BASE_URL=https://api.your-domain.com
```

## 14. Lưu Ý Quan Trọng

Backend hiện tại trả data trong wrapper `ApiResponse`, vì vậy mọi parser phải unwrap `response.data['data']`.

Các list API dùng `PageResponse`, vì vậy UI list phải đọc:

```text
response.data.data.content
```

Không gọi MongoDB trực tiếp từ Flutter. Flutter chỉ gọi Spring Boot API.

Không lưu refresh token trong SharedPreferences. Dùng secure storage.

Không hardcode password/admin trong code Flutter. Ví dụ admin chỉ để README/dev note.
