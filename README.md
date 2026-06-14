# V-FIT Recommendation System

## 1. Giới thiệu

`RecommendationSystem` là backend AI riêng của V-FIT, được xây dựng bằng **FastAPI**.

Module này phụ trách các chức năng AI Recommendation:

* AI Coach
* Workout Planner
* Meal Planner
* Food Scanner dạng text
* Kết nối với `gemini-web2api` để gọi AI

Hệ thống này chạy độc lập với backend chính Spring Boot của app.

---

## 2. Kiến trúc

```text
Flutter App
      ↓
Spring Boot Backend / hoặc gọi trực tiếp AI Service
      ↓
RecommendationSystem (FastAPI - port 8000)
      ↓
gemini-web2api (port 8081)
      ↓
Gemini
```

Trong đó:

* Flutter không gọi trực tiếp `gemini-web2api`.
* Flutter hoặc Spring Boot chỉ gọi `RecommendationSystem`.
* `RecommendationSystem` tự gọi `gemini-web2api`.
* `gemini-web2api` là AI service nội bộ, dùng để xử lý request AI.

---

## 3. Các service cần chạy

Khi chạy local cần chạy 2 service:

### Service 1: gemini-web2api

Chạy ở port:

```text
8081
```

URL nội bộ:

```text
http://localhost:8081/v1/chat/completions
```

### Service 2: RecommendationSystem

Chạy ở port:

```text
8000
```

Swagger:

```text
http://127.0.0.1:8000/docs
```

---

## 4. Cài đặt gemini-web2api

Clone repo:

```bash
git clone https://github.com/Sophomoresty/gemini-web2api.git
```

Vào thư mục:

```bash
cd gemini-web2api
```

Cài thư viện:

```bash
pip install httpx
```

Chạy service:

```bash
python gemini_web2api.py
```

Nếu chạy đúng sẽ thấy:

```text
Listening: http://0.0.0.0:8081
Base URL:  http://localhost:8081/v1
```

Không tắt terminal này.

---

## 5. Cài đặt RecommendationSystem

Vào thư mục:

```bash
cd RecommendationSystem
```

Cài dependencies:

```bash
pip install -r requirements.txt
```

Chạy FastAPI:

```bash
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Mở Swagger:

```text
http://127.0.0.1:8000/docs
```

---

## 6. API Endpoints

### AI Coach

```http
POST /api/v1/coach/
```

Ví dụ request:

```json
{
  "question": "Tôi nên tập gì hôm nay?",
  "age": 22,
  "gender": "male",
  "weight": 70,
  "height": 175,
  "goal": "gain muscle",
  "activity_level": "moderate"
}
```

---

### Workout Planner

```http
POST /api/v1/workout-planner/
```

Ví dụ request:

```json
{
  "age": 22,
  "gender": "male",
  "weight": 70,
  "height": 175,
  "goal": "gain muscle",
  "activity_level": "moderate",
  "level": "beginner",
  "days_per_week": 4
}
```

---

### Meal Planner

```http
POST /api/v1/meal-planner/
```

Ví dụ request:

```json
{
  "age": 22,
  "gender": "male",
  "weight": 70,
  "height": 175,
  "goal": "gain muscle",
  "activity_level": "moderate",
  "meals_per_day": 3
}
```

---

### Food Scanner Text

```http
POST /api/v1/food-scanner/text
```

Ví dụ request:

```json
{
  "food_name": "cơm gà",
  "portion": "1 đĩa"
}
```

---

## 7. Kết nối với Flutter

Trong Flutter đã tách riêng 2 backend:

```text
apiBaseUrl = Spring Boot backend, port 8080
aiBaseUrl  = RecommendationSystem, port 8000
```

Ví dụ:

```dart
apiBaseUrl = http://192.168.1.93:8080
aiBaseUrl  = http://192.168.1.93:8000
```

Flutter gọi AI thông qua:

```dart
aiDioProvider
```

Không gọi trực tiếp `web2api`.

---

## 8. Luồng xử lý

Ví dụ user hỏi AI Coach:

```text
Flutter
→ RecommendationSystem /api/v1/coach/
→ gemini-web2api localhost:8081
→ Gemini
→ RecommendationSystem trả kết quả
→ Flutter hiển thị
```

---

## 9. Lưu ý khi chạy local

Nếu chạy bằng Android Emulator:

```text
AI_BASE_URL=http://10.0.2.2:8000
```

Nếu chạy trên điện thoại thật cùng Wi-Fi:

```text
AI_BASE_URL=http://IP_MAY_TINH:8000
```

Ví dụ:

```text
http://192.168.1.93:8000
```

Không dùng:

```text
http://localhost:8000
```

trên điện thoại thật, vì `localhost` trên điện thoại là chính điện thoại đó.

---

## 10. Lưu ý khi deploy

Khi deploy lên VPS/server:

```text
Server
├── RecommendationSystem :8000
└── gemini-web2api       :8081
```

Trong code RecommendationSystem vẫn có thể gọi:

```text
http://localhost:8081/v1/chat/completions
```

vì lúc này `localhost` là localhost của server.

Người dùng Flutter chỉ gọi domain public:

```text
https://api-vfit.com
```

hoặc endpoint backend đã deploy.

---

## 11. Ghi chú quan trọng

* `gemini-web2api` hiện dùng được tốt cho text.
* Không dùng `gemini-web2api` cho scan ảnh vì hiện tại nó không xử lý được image input.
* Food Scanner hiện nên dùng dạng text/manual input.
* UI Flutter hiện có thể cần thêm màn hình hoặc button để gọi:

  * `askCoach()`
  * `createWorkoutPlan()`
  * `createMealPlan()`
* Repository Flutter đã có tầng gọi AI, nhưng UI cần gọi repository thì mới fetch dữ liệu thật.

---

## 12. Tóm tắt chạy local

Mở terminal 1:

```bash
cd gemini-web2api
python gemini_web2api.py
```

Mở terminal 2:

```bash
cd RecommendationSystem
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Mở trình duyệt:

```text
http://127.0.0.1:8000/docs
```

Nếu Swagger hiện lên và gọi API trả kết quả thì hệ thống AI backend đã chạy thành công.
