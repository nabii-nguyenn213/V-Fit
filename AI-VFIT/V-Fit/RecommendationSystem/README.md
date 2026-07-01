# V-FIT Recommendation System

## Giới thiệu

V-FIT Recommendation System là backend AI hỗ trợ ứng dụng V-FIT.

Hệ thống cung cấp các chức năng:

* AI Coach
* Workout Planner
* Meal Planner
* Food Recommendation
* Tích hợp với Food Scanner

---

# Kiến trúc hệ thống

```text
Mobile App
      ↓
RecommendationSystem
      ↓
gemini-web2api
      ↓
Gemini
```

Lưu ý:

* Mobile App chỉ gọi API của RecommendationSystem.
* Không gọi trực tiếp Gemini.
* Toàn bộ xử lý AI được thực hiện ở backend.

---

# Chức năng

## 1. AI Coach

Chatbot hỗ trợ người dùng về:

* Tập luyện
* Dinh dưỡng
* Thói quen sinh hoạt
* Fitness cơ bản

API:

```text
POST /api/v1/coach
```

---

## 2. Workout Planner

Tạo lịch tập cá nhân hóa dựa trên:

* Tuổi
* Giới tính
* Cân nặng
* Chiều cao
* Mục tiêu
* Trình độ tập luyện
* Số buổi tập mỗi tuần

API:

```text
POST /api/v1/workout-planner
```

---

## 3. Meal Planner

Tạo kế hoạch dinh dưỡng cá nhân hóa:

* Calories
* Protein
* Carb
* Fat
* Gợi ý thực đơn

API:

```text
POST /api/v1/meal-planner
```

---

## 4. Food Scanner

Nhận thông tin món ăn và trả về:

* Calories
* Protein
* Carb
* Fat

API:

```text
POST /api/v1/food-scanner
```

---

# Yêu cầu hệ thống

* Python 3.11+
* FastAPI
* Uvicorn
* Requests
* python-dotenv

---

# Cài đặt

Clone project:

```bash
git clone <V-FIT-REPO>
```

Di chuyển vào thư mục:

```bash
cd RecommendationSystem
```

Cài thư viện:

```bash
pip install -r requirements.txt
```

---

# Chạy AI Service

Recommendation System sử dụng gemini-web2api.

Clone:

```bash
git clone https://github.com/Sophomoresty/gemini-web2api.git
```

Di chuyển vào thư mục:

```bash
cd gemini-web2api
```

Cài thư viện:

```bash
pip install httpx
```

Khởi động:

```bash
python gemini_web2api.py
```

Mặc định:

```text
http://localhost:8081
```

---

# Chạy Backend

Mở terminal mới:

```bash
cd RecommendationSystem
```

Khởi động FastAPI:

```bash
python -m uvicorn main:app --reload
```

Backend:

```text
http://localhost:8000
```

Swagger:

```text
http://localhost:8000/docs
```

---

# Kết nối Mobile App

Mobile App chỉ cần gọi:

```text
http://SERVER_IP:8000
```

Ví dụ:

```text
http://192.168.1.10:8000
```

Các endpoint:

```text
POST /api/v1/coach

POST /api/v1/workout-planner

POST /api/v1/meal-planner

POST /api/v1/food-scanner
```

---

# Deploy

Khi deploy cần chạy đồng thời:

```text
Service 1:
gemini-web2api

Service 2:
RecommendationSystem
```

RecommendationSystem sẽ tự động gọi:

```text
http://localhost:8081/v1/chat/completions
```

để xử lý AI.

---

# Lưu ý

* Đây là backend AI dành cho V-FIT.
* Mobile App được phát triển riêng.
* Hệ thống hiện tại phục vụ mục đích MVP và Demo.
* Có thể mở rộng thêm Body Analysis và Form Check trong tương lai.
