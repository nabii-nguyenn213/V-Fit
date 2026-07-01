\# V-FIT FoodScanner



Module \*\*FoodScanner\*\* dùng camera để chụp món ăn, gửi ảnh lên \*\*Gemini Vision API\*\*, sau đó trả về:



\* Tên món ăn

\* Calories ước lượng

\* Protein

\* Carbs

\* Fat

\* Độ tin cậy



\---



\## 1. Cấu trúc thư mục



```text

FoodScanner/

│

├── main.py

├── camera.py

├── gemini\_service.py

├── ui.py

├── config.py

├── requirements.txt

├── .env

└── README.md

```



\---



\## 2. Cài đặt



Mở terminal tại thư mục `FoodScanner`:



```bash

cd FoodScanner

pip install -r requirements.txt

```



Nếu chưa có `requirements.txt`, tạo file và thêm:



```txt

opencv-python

requests

python-dotenv

```



\---



\## 3. Tạo file `.env`



Trong thư mục `FoodScanner`, tạo file `.env`:



```env

GEMINI\_API\_KEY=your\_gemini\_api\_key

```



Lưu ý: không push file `.env` lên GitHub.



\---



\## 4. Chạy chương trình



```bash

python main.py

```



Sau khi chạy, cửa sổ camera sẽ mở.



Phím sử dụng:



```text

S = Scan món ăn

Q = Thoát chương trình

```



\---



\## 5. Kết quả hiển thị



Sau khi bấm `S`, hệ thống sẽ hiển thị:



```text

Food: tên món ăn

Calories: tổng kcal

Protein: gram protein

Carbs: gram carb

Fat: gram fat

Confidence: độ tin cậy

```



\---



\## 6. Lưu ý



\* Cần có camera/webcam.

\* Cần internet để gọi Gemini API.

\* Calories chỉ là ước lượng, không chính xác tuyệt đối.

\* Không được public API key lên GitHub.



\---



\## 7. Git ignore khuyến nghị



Trong repo nên có file `.gitignore`:



```gitignore

.env

\_\_pycache\_\_/

\*.pyc

venv/

.venv/

```



