\# V-FIT Recommendation System



Hệ thống AI Recommendation cho ứng dụng \*\*V-FIT\*\*.



Module này hỗ trợ:



\* Gợi ý lịch tập (Workout Recommendation)

\* Gợi ý dinh dưỡng (Nutrition Recommendation)

\* AI Coach / Chat Assistant

\* Kết nối với Food Scanner



\---



\# Chức năng chính



\## 1. Workout Planner



Tạo kế hoạch tập luyện dựa trên thông tin người dùng:



\* Tuổi

\* Giới tính

\* Chiều cao / cân nặng

\* Mục tiêu tập luyện

\* Trình độ tập

\* Số buổi tập mỗi tuần



Kết quả:



\* Lịch tập đề xuất

\* Gợi ý bài tập

\* Split tập luyện phù hợp



Ví dụ:



```text

Goal: Giảm mỡ

→ 4 buổi/tuần

→ Cardio + Strength

```



\---



\## 2. Nutrition Planner



Tính toán dinh dưỡng dựa trên:



\* BMR

\* TDEE

\* Goal người dùng



Kết quả:



\* Calories/ngày

\* Protein

\* Carbs

\* Fat



Ví dụ:



```text

70kg – tăng cơ

→ 2800 kcal

→ 140g protein

```



\---



\## 3. AI Coach



AI chatbot hỗ trợ fitness.



Ví dụ:



\* Hôm nay tôi nên tập gì?

\* Push day là gì?

\* Tôi nên ăn bao nhiêu protein?



AI sẽ trả lời dựa trên profile và mục tiêu người dùng.



\---



\## 4. Food Scanner Integration



Nhận dữ liệu từ module Food Scanner:



\* Tên món ăn

\* Calories

\* Protein

\* Carb

\* Fat



Dùng cho:



\* Nutrition tracking

\* Meal recommendation

\* Theo dõi calories



\---



\# Cấu trúc Project



```text

Recommendation-System/

│

├── main.py

├── config.py

├── gemini\_client.py

│

├── schema/

│   ├── coach\_schema.py

│   ├── workout\_schema.py

│   └── meal\_schema.py

│

├── services/

│   ├── coach\_router.py

│   ├── workout\_planner\_router.py

│   ├── meal\_planner\_router.py

│   └── food\_scanner\_router.py

│

├── requirements.txt

└── .env

```



\---



\# Cài đặt



Cài thư viện:



```bash

pip install -r requirements.txt

```



Ví dụ `requirements.txt`:



```txt

fastapi

uvicorn

python-dotenv

requests

google-generativeai

```



\---



\# Tạo file .env



Tạo file:



```text

.env

```



Nội dung:



```env

GEMINI\_API\_KEY=your\_api\_key

```



Lưu ý:



\* Không push `.env` lên GitHub.

\* Không chia sẻ API key công khai.



\---



\# Chạy hệ thống



Khởi động backend:



```bash

uvicorn main:app --reload

```



Swagger API:



```text

http://127.0.0.1:8000/docs

```



Tại đây có thể test toàn bộ API.



\---



\# API Endpoints



\## Coach AI



```text

POST /coach

```



Chatbot fitness AI.



\---



\## Workout Planner



```text

POST /workout

```



Tạo lịch tập.



\---



\## Meal Planner



```text

POST /meal

```



Tạo kế hoạch dinh dưỡng.



\---



\## Food Scanner



```text

POST /scan

```



Nhận diện món ăn và calories.



\---



\# Công nghệ sử dụng



\* Python

\* FastAPI

\* Gemini API

\* REST API

\* JSON Response



\---



\# Ghi chú



\* Đây là backend AI của V-FIT.

\* Mobile/Web frontend được phát triển riêng.

\* Hệ thống ưu tiên demo nhanh và dễ mở rộng.

\* Có thể tích hợp với Body Analysis và Form Check trong tương lai.



