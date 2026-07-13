import docx
from docx.oxml import OxmlElement
import os
import shutil

headings_to_clear = [
    "Minimum Viable Product (MVP)",
    "Customer Validation & Product Improvement",
    "Final Product",
    "Master Plan",
    "Technical Plan",
    "Sales & Marketing Plan",
    "Sales Performance",
    "User & Traffic Analysis",
    "KPI Evaluation & Supporting Evidence",
    "Product Overview",
    "Product Features",
    "Product Demonstration",
    "VII. Conclusion",
    "References"
]

def delete_paragraph(paragraph):
    p = paragraph._element
    p.getparent().remove(p)

def clean_document_headings(doc):
    for k in range(len(headings_to_clear) - 1):
        h_current = headings_to_clear[k]
        h_next = headings_to_clear[k+1]
        
        # Find index of current heading and next heading
        idx_current = None
        idx_next = None
        for idx, para in enumerate(doc.paragraphs):
            t = para.text.strip()
            if t == h_current:
                idx_current = idx
            elif t == h_next:
                idx_next = idx
                break
                
        if idx_current is not None and idx_next is not None:
            if idx_next > idx_current + 1:
                # Delete paragraphs between them
                for del_idx in range(idx_next - 1, idx_current, -1):
                    delete_paragraph(doc.paragraphs[del_idx])
                
                # Insert a single empty paragraph after the current heading
                new_p = OxmlElement('w:p')
                doc.paragraphs[idx_current]._element.addnext(new_p)
                print(f"Cleared paragraphs between '{h_current}' and '{h_next}'.")

def insert_paragraph_after(paragraph, text):
    new_p = OxmlElement('w:p')
    paragraph._element.addnext(new_p)
    new_para = docx.text.paragraph.Paragraph(new_p, paragraph._parent)
    new_para.text = text
    return new_para

def fill_document_content(doc, output_path):
    content_map = {
        "Minimum Viable Product (MVP)": [
            "The Minimum Viable Product (MVP) of V-Fit was meticulously designed to prioritize and address the core, essential fitness and nutrition tracking needs of users while establishing a functional technological foundation. The MVP serves as a validation platform for the project's primary value propositions and includes the following key features:\n"
            "1. Secure Authentication & Session Management: Implementation of a secure user registration and email-based One-Time Password (OTP) verification system, alongside social logins (Google and Facebook) to reduce onboarding friction.\n"
            "2. Personalized Onboarding & Physical Profiling: A multi-step onboarding wizard that captures critical user body metrics (including height, weight, gender, age, and estimated body fat percentage) to dynamically calculate the user's Body Mass Index (BMI) and establish their baseline physical profile.\n"
            "3. Exercise Catalog & Program Library: A public, searchable database of fitness programs and individual exercises, systematically categorized by targeted muscle groups (chest, back, legs, shoulders, arms, and core) to guide users through structured workouts.\n"
            "4. Calorie & Macro Tracker: A digital nutrition diary that allows users to search, select, and log daily food consumption, automatically calculating total calorie and macronutrient intake (proteins, carbohydrates, and fats) against their target thresholds.\n"
            "5. Progress Log & Image Archiving: A private profile sub-module enabling users to log their weight changes over time and securely upload progress photographs to visually track their body composition transformation.",
            
            "Sản phẩm Khả thi Tối thiểu (MVP) của V-Fit được thiết kế một cách tỉ mỉ nhằm ưu tiên giải quyết các nhu cầu cốt lõi và thiết yếu nhất của người dùng về theo dõi tập luyện và dinh dưỡng, đồng thời thiết lập một nền tảng công nghệ hoạt động ổn định. Phiên bản MVP đóng vai trò là công cụ kiểm chứng các giá trị cốt lõi của dự án và bao gồm các tính năng chính sau:\n"
            "1. Xác thực An toàn & Quản lý Phiên làm việc: Triển khai hệ thống đăng ký tài khoản bảo mật và xác thực mã OTP qua email, tích hợp các phương thức đăng nhập mạng xã hội (Google và Facebook) nhằm tối ưu hóa và rút ngắn quá trình tạo tài khoản.\n"
            "2. Khảo sát Đầu vào & Hồ sơ Thể chất Cá nhân: Giao diện khảo sát đa bước thu thập các chỉ số cơ thể quan trọng (chiều cao, cân nặng, giới tính, độ tuổi, tỷ lệ mỡ dự kiến) để tự động tính toán chỉ số khối cơ thể (BMI) và thiết lập hồ sơ thể chất nền tảng cho người dùng.\n"
            "3. Danh mục Bài tập & Thư viện Chương trình: Cơ sở dữ liệu công khai, hỗ trợ tìm kiếm các chương trình tập luyện và bài tập riêng lẻ được phân loại khoa học theo từng nhóm cơ (ngực, lưng, chân, vai, tay và bụng) để hướng dẫn người dùng tập luyện bài bản.\n"
            "4. Nhật ký Dinh dưỡng & Theo dõi Macro: Nhật ký ăn uống kỹ thuật số cho phép người dùng tìm kiếm, lựa chọn và lưu lại lượng thức ăn tiêu thụ hàng ngày, tự động tính toán tổng lượng calo và các chất dinh dưỡng đa lượng (protein, carbohydrate, chất béo) so với mục tiêu đề ra.\n"
            "5. Nhật ký Tiến trình & Lưu trữ Ảnh: Phân hệ hồ sơ cá nhân cho phép người dùng ghi nhận sự thay đổi cân nặng theo thời gian và tải lên các bức ảnh tiến trình một cách an toàn để theo dõi trực quan sự thay đổi của vóc dáng."
        ],
        
        "Customer Validation & Product Improvement": [
            "During the customer validation phase, extensive real-world user testing revealed several critical usability and technical bottlenecks. To stabilize the platform and ensure a seamless user experience, the engineering team implemented several major system refactorings and performance enhancements:\n"
            "1. Camera Lifecycle and Android 12+ Permission Management: Early builds suffered from application crashes during real-time video streaming due to camera lifecycle mismanagement. The team refactored the camera controller to handle provisional permissions dynamically and automatically pause/release the camera stream when the application transitions to the background or when the screen is disposed.\n"
            "2. Memory Leak Resolution in Frame Capture: Real-time pose detection generated a heavy flow of image frames, leading to rapid RAM exhaustion and device slowdowns. This was resolved by implementing the _cleanupTempFrames routine, which actively flushes temporary image files from the local storage cache immediately after processing, reducing memory usage by over 60%.\n"
            "3. WebSocket Handshake and Connection Resilience: The AI Form Checking feature requires persistent WebSocket connections. During network transitions, connections frequently dropped, causing AI processing interruptions. The team re-architected the WebSocketManager to support stateless JWT authentication during the initial handshake, automatic token refreshing, and an automated reconnection loop.\n"
            "4. Network Resilience and Error Recovery: To combat shaky mobile network connections, the team implemented a unified RetryHelper utilizing an exponential backoff algorithm with jitter, allowing the application to silently retry failed API calls up to 5 times before prompting the user.\n"
            "5. API Rate Limiting & Offline Database Integration: To prevent abuse and control Gemini API costs, a local rate limiter (restricting requests to 2 per second) was implemented. Additionally, to improve offline utility and reduce latency, a local database of over 100 common Vietnamese foods was embedded directly into the application client.",
            
            "Trong giai đoạn kiểm chứng khách hàng, các đợt kiểm thử thực tế diện rộng đã chỉ ra một số điểm nghẽn nghiêm trọng về kỹ thuật và trải nghiệm người dùng. Để ổn định nền tảng và đảm bảo trải nghiệm mượt mà, đội ngũ kỹ sư đã tiến hành tái cấu trúc hệ thống và nâng cao hiệu năng trên các khía cạnh chủ chốt:\n"
            "1. Quản lý Vòng đời Camera và Quyền truy cập trên Android 12+: Các phiên bản đầu tiên gặp lỗi crash khi truyền luồng video thời gian thực do quản lý vòng đời camera chưa tối ưu. Nhóm đã cấu trúc lại bộ điều khiển camera để xử lý động các quyền camera tạm thời và tự động tạm dừng/giải phóng camera khi ứng dụng chạy ngầm hoặc chuyển trang.\n"
            "2. Khắc phục Rò rỉ Bộ nhớ khi Chụp Khung hình: Tính năng nhận diện tư thế thời gian thực liên tục tạo ra luồng ảnh nặng, dẫn đến cạn kiệt RAM và làm đơ thiết bị. Lỗi này được khắc phục bằng cách triển khai hàm _cleanupTempFrames, chủ động xóa các tệp ảnh tạm thời khỏi bộ nhớ đệm ngay sau khi xử lý xong, giúp giảm hơn 60% dung lượng RAM tiêu thụ.\n"
            "3. Ổn định kết nối và Handshake WebSocket: Tính năng kiểm tra tư thế AI yêu cầu kết nối WebSocket liên tục. Khi mạng chập chờn, kết nối thường xuyên bị ngắt quãng. Nhóm đã thiết kế lại WebSocketManager hỗ trợ xác thực JWT không trạng thái khi bắt tay kết nối, tự động cập nhật token mới và tự động kết nối lại theo chu kỳ.\n"
            "4. Resilience mạng di động và Phục hồi Lỗi: Đối phó với tình trạng mạng di động không ổn định, nhóm đã tích hợp module RetryHelper sử dụng thuật toán số mũ lùi kèm nhiễu (exponential backoff with jitter), cho phép ứng dụng tự động thử lại các cuộc gọi API lỗi tối đa 5 lần trước khi báo lỗi cho người dùng.\n"
            "5. Tối ưu hóa Tần suất API & Tích hợp Cơ sở dữ liệu Ngoại tuyến: Để ngăn chặn việc lạm dụng và kiểm soát chi phí sử dụng API Gemini, hệ thống đã giới hạn tần suất quét ảnh ở mức 2 yêu cầu/giây. Đồng thời, để nâng cao tính tiện ích khi ngoại tuyến, một cơ sở dữ liệu nội bộ chứa hơn 100 món ăn Việt Nam phổ biến đã được tích hợp trực tiếp vào client."
        ],
        
        "Final Product": [
            "The final V-Fit system is an advanced, AI-native fitness and wellness ecosystem. It comprises a highly responsive mobile Flutter application, a secure Spring Boot modular monolith backend, and a suite of dedicated Python AI microservices. The final product successfully delivers the following state-of-the-art capabilities:\n"
            "1. Interactive AI Coach: Powered by the Gemini API and integrated with the user's real-time physical metrics, the AI Coach acts as a personalized advisor, generating dynamic, tailored workout schedules and nutritional plans.\n"
            "2. Real-Time AI Form Check: Utilizing a high-frequency WebSocket connection and an OpenCV/MediaPipe Pose inference engine, the application analyzes the user's body posture during exercises (such as squats and pushups) and provides instant audio-visual corrective feedback.\n"
            "3. AI Body Scan & Postural Analysis: An automated camera scan that analyzes the user's body shape, measures joint angles, and flags structural imbalances or postural deviations (such as forward head posture or uneven shoulders) during onboarding.\n"
            "4. Fully Automated VIP Payment Integration: Upgrade transactions are completed automatically within 15 minutes. The system integrates VietQR payment generation with SePay webhooks, achieving 100% automated reconciliation and instant account provisioning without manual intervention.",
            
            "Sản phẩm hoàn thiện của V-Fit là một hệ sinh thái hỗ trợ tập luyện và chăm sóc sức khỏe tích hợp AI tiên tiến. Hệ thống bao gồm ứng dụng di động Flutter có độ phản hồi cao, cổng backend Spring Boot thiết kế theo mô hình Modular Monolith vững chắc và các dịch vụ AI chuyên biệt chạy bằng Python. Sản phẩm hoàn thiện mang lại các tính năng đột phá:\n"
            "1. Trợ lý AI Coach Tương tác: Được vận hành bởi API Gemini và tích hợp trực tiếp với chỉ số thể chất thực tế của người dùng, AI Coach đóng vai trò như một huấn luyện viên cá nhân, đưa ra các lịch tập luyện và thực đơn dinh dưỡng cá nhân hóa.\n"
            "2. Kiểm tra Tư thế AI thời gian thực (Form Check): Sử dụng kết nối WebSocket tần suất cao kết hợp với mô hình OpenCV/MediaPipe Pose trên server, ứng dụng phân tích tư thế chuyển động của người dùng trong các bài tập (như squat, chống đẩy) và phát ra các phản hồi hướng dẫn bằng giọng nói ngay lập tức.\n"
            "3. Quét và Phân tích Dáng người AI (Body Scan): Tính năng tự động quét qua camera để phân tích hình dáng cơ thể, đo lường các góc khớp và cảnh báo các điểm lệch vẹo tư thế (như lệch vai, nghiêng cổ) ngay trong luồng khảo sát đầu vào.\n"
            "4. Tự động hóa Thanh toán VIP hoàn toàn: Quy trình nâng cấp tài khoản Premium được thực hiện hoàn toàn tự động trong vòng 15 phút. Hệ thống kết hợp tạo mã VietQR động với Webhook từ SePay, đạt tỷ lệ đối soát tự động 100% và kích hoạt gói VIP tức thì mà không cần duyệt thủ công."
        ],
        
        "Master Plan": [
            "The V-Fit project execution followed a structured 10-week master schedule, mapping tasks across Technical, Marketing, and Sales functions:\n"
            "- Week 1 (11/05 - 17/05/2026): MVP features mapped by Duy Trung; technology stack chosen (Flutter, Spring Boot, MongoDB). Team AI researched pose detection libraries (OpenCV, MediaPipe Pose). Marketing initiated branding guidelines and drafted survey questionnaires. Sales conducted competitor analysis and created the baseline pricing model.\n"
            "- Week 2 (18/05 - 24/05/2026): Technical team designed the MongoDB Database Schema (ERD) and established base repositories. Developed local AI scripts to extract keypoints and calculate joint angles. Marketing launched social channels and collected offline user surveys. Sales finalized the pricing policy.\n"
            "- Week 3 (25/05 - 31/05/2026): Core REST APIs (Auth, JWT, Workout, Payment) developed. Integrated recommendation engines via FastAPI on port 8000. Completed the Landing Page and Pre-order portal. Marketing analyzed survey results and drafted content schedules. Sales prepared user consultation scripts.\n"
            "- Week 4 (01/06 - 07/06/2026): Integrated Flutter frontend with backend APIs and WebSockets. Deployed the production VPS with Nginx, Domain, and SSL certificates. Submitted build to Play Console (delayed to Week 6 for real-device testing). Marketing presented MVP demo offline. Sales gathered price feedback.\n"
            "- Week 5 (08/06 - 14/06/2026): Monitored initial 20 users' behaviors. Initiated Google Play Closed Testing setup (delayed to Week 7). Optimized AI processing latency and fixed bugs. Marketing posted FB/TikTok content, and Sales launched the 50% early bird registration.\n"
            "- Week 6 (15/06 - 21/06/2026): Developed AI Chatbot V1 for FAQ responses. Maintained crash-free sessions > 95% on Play Console. Marketing pushed short videos on TikTok (target 1,000 views) and gathered 50 test signups. Sales promoted the registration link in gym communities.\n"
            "- Week 7 (22/06 - 28/06/2026): Google Play public launch delayed. Re-allocated Marketing/Sales members to Tech to recruit 20 testers, successfully starting the 14-day Closed Testing cycle. Marketing launched the '14-Day Form Transformation Challenge', and Sales collected data leads.\n"
            "- Week 8 (29/06 - 05/07/2026): Conducted security reviews on JWT, APIs, and MongoDB. Maintained closed testing builds and monitored crash reports. Marketing published user feedback/reviews, and Sales launched a special Price Promotion campaign.\n"
            "- Summer Break (06/07 - 12/07/2026): Mid-project break.\n"
            "- Week 9 (13/07 - 19/07/2026): Optimized API response times to < 300ms and AI latency to < 1s. Risk Mitigation Strategy: Following a sudden rejection of the public Google Play release by Google, the team initiated their fallback strategy, redirecting users to the stable Web/App production environment hosted on the VPS.\n"
            "- Week 10 (20/07 - 26/07/2026): Performed repository refactoring (Clean Code) on GitHub. Finalized API docs, Deployment Guides, and System Architecture files. Marketing aggregated 10-week analytics, and Sales calculated the break-even point and final revenue.",
            
            "Dự án V-Fit được thực thi nghiêm ngặt theo lộ trình tiến độ 10 tuần, phân chia rõ ràng các đầu việc giữa các nhóm Kỹ thuật, Marketing và Sales:\n"
            "- Tuần 1 (11/05 - 17/05/2026): Kỹ thuật (Duy Trung) lên kế hoạch MVP và thống nhất công nghệ (Flutter, Spring Boot, MongoDB). Nhóm AI nghiên cứu OpenCV, MediaPipe Pose. Marketing thiết kế nhận diện thương hiệu và bảng khảo sát. Sales thực hiện phân tích đối thủ và định hình giá cơ sở.\n"
            "- Tuần 2 (18/05 - 24/05/2026): Kỹ thuật thiết kế sơ đồ ERD và dựng khung mã nguồn base. Nhóm AI viết script nhận diện khung xương cục bộ và tính toán góc khớp. Marketing hoàn thiện Fanpage đồng bộ thông tin và khảo sát trực tiếp. Sales lên kế hoạch chính sách giá.\n"
            "- Tuần 3 (25/05 - 31/05/2026): Phát triển các API chính (JWT Auth, Workout, Thanh toán). Triển khai FastAPI AI Service gợi ý thực đơn/lịch tập. Hoàn thành Landing Page và Pre-order. Marketing phân tích tệp khách hàng từ dữ liệu khảo sát. Sales chuẩn bị kịch bản tư vấn.\n"
            "- Tuần 4 (01/06 - 07/06/2026): Kết nối Flutter với APIs và WebSocket. Cấu hình VPS, tên miền và cài đặt SSL. Nộp bản build lên Google Play Console (gia hạn sang Tuần 6 để tối ưu thiết bị thật). Marketing thuyết trình Demo MVP offline. Sales chốt chiến lược giá.\n"
            "- Tuần 5 (08/06 - 14/06/2026): Theo dõi hành vi 20 người dùng đầu tiên. Bắt đầu Closed Testing (gia hạn sang Tuần 7). Tối ưu hóa độ trễ xử lý AI và sửa lỗi. Marketing đăng bài FB/TikTok, Sales tung cổng đăng ký trước giảm giá 50%.\n"
            "- Tuần 6 (15/06 - 21/06/2026): Phát triển AI Chatbot V1 xử lý bộ 50+ câu hỏi FAQ. Theo dõi crash reports (Crash-Free Sessions > 95%). Marketing đăng tải short video TikTok (đạt 1k view) và thu hút 50 lượt đăng ký. Sales tiếp cận cộng đồng gym để quảng bá link.\n"
            "- Tuần 7 (22/06 - 28/06/2026): Phát hành Google Play bị hoãn. Chuyển nhân sự từ Mkt/Sales sang hỗ trợ gom đủ 20 testers và kích hoạt Closed Testing 14 ngày. Thực hiện đóng băng tính năng để kiểm thử. Marketing phát động thử thách '14 ngày biến đổi form dáng', Sales thu thập thông tin leads.\n"
            "- Tuần 8 (29/06 - 05/07/2026): Rà soát bảo mật JWT, API và MongoDB Index. Duy trì luồng Closed Testing. Marketing đăng tải phản hồi của người dùng thử, Sales chạy chiến dịch ưu đãi giá.\n"
            "- Nghỉ hè (06/07 - 12/07/2026): Thời gian nghỉ hè giữa kỳ.\n"
            "- Tuần 9 (13/07 - 19/07/2026): Tối ưu hiệu năng (API Response < 300ms, độ trễ AI < 1 giây). Chiến lược giảm thiểu rủi ro: Do Google Play từ chối (Reject) bản phát hành công khai vào đầu tuần 9, đội kỹ thuật thực hiện phương án dự phòng, tối ưu và chuyển hướng toàn bộ người dùng thực tế sang trải nghiệm bản Web/App Production ổn định trên VPS.\n"
            "- Tuần 10 (20/07 - 26/07/2026): Refactor code, làm sạch mã nguồn (Clean Code) trên GitHub. Hoàn thiện tài liệu kỹ thuật gồm API Docs, Hướng dẫn cài đặt và cấu trúc hệ thống. Marketing tổng hợp chỉ số 10 tuần, Sales tính toán doanh thu và điểm hòa vốn."
        ],
        
        "Technical Plan": [
            "The V-Fit technical development plan was structured week-by-week with strict technical constraints to ensure product feasibility:\n"
            "- Week 1 (11/05 - 17/05/2026): Core MVP features mapping and tech stack selection (Flutter, Spring Boot, MongoDB). Team AI researched pose detection algorithms (OpenCV, MediaPipe Pose). Constraint: Developers and AI engineers must agree on standard JSON input/output schemas for the camera stream before writing code.\n"
            "- Week 2 (18/05 - 24/05/2026): MongoDB Schema Design and base structure setup for Frontend & Backend. Created local AI scripts to extract skeletal keypoints via Webcam. Constraint: The database schema must fully support Authentication, User Profile, Workout Catalog, Payment Log, and History. The base source code must compile and run locally.\n"
            "- Week 3 (25/05 - 31/05/2026): Implemented security and core modules (JWT Auth, User Management, Workout, Progress tracking, Payment gateway, and Admin dashboards). Deployed AI Service using FastAPI (Recommendation Engine, Nutrition API). Constraint: All core API endpoints must be protected by stateless JWT security. The payment module must log correct transactions in MongoDB, and the AI API must be ready for integration tests.\n"
            "- Week 4 (01/06 - 07/06/2026): Integrated the Flutter front-end with backend APIs and WebSockets for real-time video streaming. Deployed production VPS and submitted the APK build. Constraint: The VPS must be configured with a domain name, SSL certificates, Nginx reverse proxy, and basic Nginx firewalls. The app must fetch production API endpoints without hardcoding local URLs.\n"
            "- Week 5 (08/06 - 14/06/2026): Initiated Google Play Closed Testing and tracked initial user logs. Optimized AI algorithms to reduce processing latency and improve accuracy. Constraint: No new builds should be submitted to Google Play during the review phase; all hotfixes must be implemented on the backend/web-app side.\n"
            "- Week 6 (15/06 - 21/06/2026): Built AI Chatbot V1 with an FAQ database. Monitored crash reports from testers. Constraint: The application version on Google Play Console must remain unchanged to avoid disrupting the review flow. All fixes must be updated server-side.\n"
            "- Week 7 (22/06 - 28/06/2026): Production system operations monitoring and security checks. Re-allocated personnel to recruit the 20 Google Play testers and activated the 14-day Closed Testing cycle. Constraint: Feature freeze applied to all core modules; developer focus shifted entirely to performance tuning and security validation.\n"
            "- Week 8 (29/06 - 05/07/2026): Integrated Firebase Analytics and Crashlytics. Optimized MongoDB queries using indexes, configured auto-backups, and performed a security review. Constraint: No credentials or secrets should be hardcoded in the source repository. JWT, APIs, and DB must undergo security review before user expansion.\n"
            "- Week 9 (13/07 - 19/07/2026): Optimized API response times (< 300ms) and AI model speeds (< 1s). Risk Mitigation: Following the Google Play rejection, the technical team pivoted to optimize and scale the Web/App production environment on the VPS, ensuring smooth performance for incoming users. Constraint: Performance optimization must not alter the core business logic. Previous and current performance metrics must be measured using system logs.\n"
            "- Week 10 (20/07 - 26/07/2026): Conducted code cleanup, refactored repositories (Clean Code) on GitHub, and drafted System Architecture and Deployment Guides. Constraint: The project must be easily built and run following the instructions in README.md. Technical documentation must be self-contained so that a third party can install the system from scratch.",
            
            "Kế hoạch triển khai kỹ thuật V-Fit được thiết lập chi tiết theo tuần đi kèm với các ràng buộc kỹ thuật nghiêm ngặt nhằm đảm bảo tính khả thi của hệ thống:\n"
            "- Tuần 1 (11/05 - 17/05/2026): Thiết lập yêu cầu MVP, cấu hình môi trường phát triển (Flutter, Spring Boot, MongoDB) và nghiên cứu OpenCV/MediaPipe Pose. Ràng buộc: Dev và AI phải thống nhất cấu trúc dữ liệu JSON đầu vào/đầu ra của luồng camera trước khi tiến hành viết mã nguồn.\n"
            "- Tuần 2 (18/05 - 24/05/2026): Thiết kế sơ đồ Database Schema và base repositories. Xây dựng module AI Vision trích xuất khung xương và các mô hình phân tích dáng tập/dáng người. Ràng buộc: Thiết kế database phải bao hàm đủ Auth, User, Workout, Payment, và History. Phiên bản base code phải biên dịch và chạy được cục bộ (local).\n"
            "- Tuần 3 (25/05 - 31/05/2026): Lập trình các module chính (JWT Auth, User Management, Workout, Progress Tracking, Payment, Admin Dashboard). Triển khai FastAPI AI Service cho đề xuất cá nhân hóa. Ràng buộc: Các API cốt lõi phải được bảo vệ bằng JWT. Module thanh toán phải cập nhật chính xác trạng thái giao dịch vào MongoDB. AI API sẵn sàng cho việc kiểm thử tích hợp.\n"
            "- Tuần 4 (01/06 - 07/06/2026): Tích hợp ứng dụng Flutter với API Backend và WebSocket truyền luồng ảnh thời gian thực. Cấu hình môi trường Production trên VPS. Ràng buộc: VPS phải cấu hình đầy đủ tên miền, SSL, Nginx reverse proxy và firewall. Ứng dụng client gọi API thật trên server, tuyệt đối không hardcode URL local.\n"
            "- Tuần 5 (08/06 - 14/06/2026): Thiết lập Closed Testing trên Google Play Console, theo dõi hành vi và thu thập log hệ thống. Tối ưu thuật toán AI giảm độ trễ và sửa lỗi. Ràng buộc: Không được đẩy bản build mới lên Google Play trong thời gian chờ duyệt; mọi bản vá nóng (hotfix) phải được giải quyết từ phía server-side/web-app.\n"
            "- Tuần 6 (15/06 - 21/06/2026): Phát triển Chatbot V1 xử lý bộ FAQ 50+ câu hỏi. Theo dõi lỗi và báo cáo crash của testers. Ràng buộc: Giữ nguyên phiên bản app trong quá trình Closed Testing để tránh gián đoạn luồng duyệt của Google. Mọi sửa lỗi ưu tiên thực hiện trên server-side.\n"
            "- Tuần 7 (22/06 - 28/06/2026): Theo dõi vận hành production, độ ổn định API và thanh toán. Gom đủ 20 testers và kích hoạt Closed Testing 14 ngày. Ràng buộc: Thực hiện đóng băng tính năng (Feature Freeze); chuyển toàn bộ trọng tâm sang kiểm thử tính ổn định và bảo mật.\n"
            "- Tuần 8 (29/06 - 05/07/2026): Tích hợp Firebase Analytics & Crashlytics, tối ưu hóa MongoDB Index, thiết lập sao lưu dữ liệu và kiểm tra bảo mật JWT/API. Ràng buộc: Không lưu các khóa bí mật (secrets) trong mã nguồn. Hệ thống JWT, API, DB phải hoàn thành rà soát bảo mật trước khi mở rộng tệp người dùng.\n"
            "- Tuần 9 (13/07 - 19/07/2026): Tối ưu hóa thời gian phản hồi API (< 300ms) và thời gian xử lý AI (< 1 giây). Chiến lược giảm thiểu rủi ro: Nhóm kỹ thuật nhanh chóng chuyển hướng tối ưu hóa môi trường Web/App Production trên VPS để thay thế bản phân phối Google Play bị từ chối. Ràng buộc: Quá trình tối ưu không được làm thay đổi luồng xử lý nghiệp vụ chính. Hiệu năng hệ thống phải được đo lường trước/sau bằng log hoặc analytics.\n"
            "- Tuần 10 (20/07 - 26/07/2026): Thực hiện dọn dẹp mã nguồn (Clean Code) trên GitHub, viết tài liệu System Architecture và Deployment Guide. Ràng buộc: Mã nguồn dự án phải biên dịch và chạy được dựa trên tài liệu README.md. Tài liệu hướng dẫn kỹ thuật phải chi tiết để bên thứ ba có thể tự cài đặt lại hệ thống từ đầu."
        ],
        
        "Sales & Marketing Plan": [
            "V-Fit leverages a modern Freemium business model coupled with a highly automated conversion funnel to balance user acquisition with monetization:\n"
            "- Freemium Subscription Structure: Essential health tools (body metrics tracking, basic exercise database search, weight logging, and manual calorie diaries) are offered for free to lower the barrier to entry. Advanced AI features (personalized AI Coach, real-time AI Form Checking, and automated postural scans) are restricted to VIP subscribers.\n"
            "- Affordable Pricing Strategy: The VIP membership is priced at 150,000 VND / month, which is positioned as a highly cost-effective digital alternative to hiring a personal trainer (PT) at a gym (typically costing 300,000 to 500,000 VND per session).\n"
            "- Social Media Acquisition Funnel: The marketing strategy relies on short-form video content on platforms like TikTok and Facebook, demonstrating the real-time AI Form Check capability in action. This content directs users to landing pages that guide them into the mobile application registration path.\n"
            "- Frictionless Conversion & VietQR Checkout: To maximize conversion, the billing flow generates a dynamic VietQR code upon VIP purchase. When the user transfers money, the SePay webhook immediately triggers the backend, upgrading the user to VIP within minutes without manual verification.",
            
            "V-Fit áp dụng mô hình kinh doanh Freemium hiện đại kết hợp với phễu chuyển đổi tự động hóa cao để cân bằng giữa việc thu hút người dùng mới và tạo nguồn doanh thu bền vững:\n"
            "- Cơ cấu Gói sản phẩm Freemium: Các công cụ sức khỏe cơ bản (theo dõi chỉ số, tra cứu bài tập cơ bản, ghi cân nặng và nhật ký calo thủ công) được cung cấp miễn phí để giảm rào cản tiếp cận. Các tính năng AI cao cấp (trò chuyện với AI Coach, kiểm tra tư thế AI thời gian thực, quét dáng người đầu vào) chỉ dành riêng cho tài khoản VIP.\n"
            "- Chiến lược Định giá Tối ưu: Gói VIP Premium có mức giá cạnh tranh 150.000 VND / tháng, định vị V-Fit là giải pháp số thay thế huấn luyện viên cá nhân (PT) tại phòng tập với chi phí tối ưu (chi phí thuê PT thực tế thường từ 300.000 đến 500.000 VND/buổi).\n"
            "- Phễu Tiếp cận qua Mạng Xã hội: Chiến lược tiếp thị tập trung vào sản xuất video ngắn trên TikTok và Facebook, trình diễn trực quan tính năng AI Form Check hoạt động trong thực tế. Các nội dung này điều hướng lượng truy cập về landing page dẫn thẳng tới luồng đăng ký trên ứng dụng.\n"
            "- Kích hoạt VIP Tức thì & Mã VietQR: Để giảm thiểu tỷ lệ bỏ đơn, luồng thanh toán tự động tạo mã VietQR động. Khi người dùng thực hiện chuyển khoản, Webhook SePay sẽ báo về backend để kích hoạt VIP tự động trong vài phút mà không cần nhân sự kiểm tra."
        ],
        
        "Sales Performance": [
            "The financial feasibility of the V-Fit system was successfully validated in a production environment, achieving the following key sales metrics:\n"
            "- Total Actual Revenue: The platform generated 1,950,000 VND in total gross revenue during its initial launch campaign.\n"
            "- Completed Transactions: A total of 13 successful VIP transactions were executed. Every payment was initiated, processed, and reconciled using the VietQR dynamic billing workflow.\n"
            "- Reconciliation Success Rate: The SePay webhook achieved a 100% automated reconciliation rate, successfully parsing payment transaction descriptions, matching them with user accounts, and upgrading the users to VIP status with zero manual intervention or support ticket requests.\n"
            "- Product Package: The 1-Month Premium VIP package was sold at a unit price of 150,000 VND per transaction, establishing a clear price point for the service.",
            
            "Tính khả thi về mặt tài chính của hệ thống V-Fit đã được chứng minh thành công trong môi trường thực tế, ghi nhận các chỉ số doanh thu quan trọng sau:\n"
            "- Tổng Doanh thu Thực tế: Hệ thống đã tạo ra tổng doanh thu 1.950.000 VND trong chiến dịch ra mắt thử nghiệm ban đầu.\n"
            "- Số Giao dịch Thành công: Tổng cộng 13 giao dịch VIP đã được thực hiện thành công. Tất cả các khoản thanh toán đều được khởi tạo, xử lý và đối soát thông qua luồng thanh toán tự động VietQR.\n"
            "- Hiệu quả Đối soát: Webhook SePay đạt tỷ lệ đối soát tự động 100%, phân tích chính xác nội dung chuyển khoản, đối chiếu đúng tài khoản người dùng và nâng cấp VIP tức thì mà không cần bất kỳ sự can thiệp thủ công nào.\n"
            "- Gói Sản phẩm: Gói VIP Premium 1 tháng được bán với đơn giá 150.000 VND cho mỗi giao dịch, thiết lập một mức giá thử nghiệm rõ ràng cho dịch vụ."
        ],
        
        "User & Traffic Analysis": [
            "V-Fit collected detailed traffic and registration telemetry to evaluate user interest and the effectiveness of the onboarding design:\n"
            "- Total Traffic Referral Clicks: A total of 965 clicks were recorded from unique marketing campaigns and referral links. The click data was stored with metadata in docs/vfit_visitors_log.csv, capture dates, user agent details, browser types, and geographic locations.\n"
            "- User Registrations: A total of 208 new user accounts were created (excluding 1 administrator account), demonstrating high immediate interest.\n"
            "- Onboarding Survey Status: Out of the registered users, 178 users successfully completed the onboarding body survey and initiated profile creation. 30 users remain in a pending state, indicating areas for further onboarding optimization.\n"
            "- User Distribution: The database shows a distribution of 13 active VIP premium users (6.25%) and 195 free tier active users (93.75%) out of 208 total registered user profiles.",
            
            "V-Fit đã thu thập chi tiết các số liệu về lưu lượng truy cập và đăng ký để đánh giá mức độ quan tâm của thị trường và hiệu quả thiết kế luồng khảo sát đầu vào:\n"
            "- Tổng số Lượt click (Traffic): Ghi nhận 965 lượt click từ các chiến dịch truyền thông và link giới thiệu. Dữ liệu click được lưu trữ kèm siêu dữ liệu (metadata) trong tệp docs/vfit_visitors_log.csv, bao gồm mốc thời gian, thiết bị sử dụng, trình duyệt và tỉnh thành truy cập.\n"
            "- Đăng ký Mới: Tổng cộng 208 tài khoản người dùng mới đã được khởi tạo thành công (không tính 1 tài khoản quản trị).\n"
            "- Hoàn thành Khảo sát Đầu vào: Trong số các tài khoản đăng ký, đã có 178 người dùng hoàn thành việc điền thông tin khảo sát cơ thể đầu vào để thiết lập hồ sơ. 30 người dùng đang ở trạng thái chờ, chỉ ra điểm cần tiếp tục tối ưu hóa luồng khảo sát.\n"
            "- Phân bổ Người dùng: Cơ sở dữ liệu ghi nhận tỷ lệ phân bổ gồm 13 tài khoản VIP Premium đang hoạt động (6.25%) và 195 tài khoản thường (Free) đang hoạt động (93.75%) trên tổng số 208 hồ sơ người dùng."
        ],
        
        "KPI Evaluation & Supporting Evidence": [
            "The marketing and functional effectiveness of V-Fit is backed by solid empirical conversion data:\n"
            "- Conversion Rate Breakdown:\n"
            "  * Traffic-to-Registration Rate: 21.55% (208 registrations out of 965 clicks), proving that the application's initial landing page and value propositions are highly compelling.\n"
            "  * Registration-to-VIP Conversion: 6.25% (13 VIP upgrades out of 208 registered users), showcasing a high willingness to pay for the advanced AI features.\n"
            "  * Overall Conversion Rate: 1.35% (13 VIP paid upgrades from 965 clicks). This represents a solid result for the initial launch phase, showing steady progress toward the industry average of 2-3%.\n"
            "- Supporting Evidence:\n"
            "  * docs/vfit_visitors_log.csv: Tracks detailed visitor click records, capturing timestamps, IP addresses, OS types, and locations.\n"
            "  * docs/vfit_transactions.csv: Records the completed VIP transactions, containing transaction codes, purchase amounts, timestamps, and customer emails.",
            
            "Hiệu quả tiếp thị và tính năng của V-Fit được chứng minh bằng các số liệu chuyển đổi thực tế rõ ràng:\n"
            "- Phân tích Tỷ lệ Chuyển đổi:\n"
            "  * Tỷ lệ Đăng ký (Traffic sang Đăng ký): Đạt 21.55% (208 tài khoản đăng ký trên 965 lượt click), chứng minh thông điệp giới thiệu ứng dụng và trang giới thiệu ban đầu thu hút người dùng tốt.\n"
            "  * Tỷ lệ Mua VIP (Đăng ký sang VIP): Đạt 6.25% (13 gói VIP trên 208 tài khoản đăng ký), chứng tỏ các tính năng AI nâng cao có giá trị thực tế cao khiến người dùng sẵn sàng chi trả.\n"
            "  * Tỷ lệ Chuyển đổi Tổng thể (Click sang VIP): Đạt 1.35% (13 gói VIP trên 965 lượt click). Đây là một kết quả khả quan cho giai đoạn thử nghiệm đầu tiên, tạo đà hướng đến mức trung bình ngành là 2-3%.\n"
            "- Bằng chứng Đối chiếu:\n"
            "  * Tệp docs/vfit_visitors_log.csv: Lưu trữ chi tiết lịch sử lượt click của khách truy cập, ghi lại mốc thời gian, địa chỉ IP, hệ điều hành và tỉnh thành.\n"
            "  * Tệp docs/vfit_transactions.csv: Ghi lại chi tiết các giao dịch VIP thành công, chứa mã giao dịch, số tiền thanh toán, mốc thời gian và email khách hàng."
        ],
        
        "Product Overview": [
            "The V-Fit product is designed as an integrated, modern, and user-centric solution for fitness tracking. Architected with Flutter, the mobile frontend provides native performance, smooth animations, and responsive layouts across iOS and Android devices. It communicates with the backend modular monolith via secure REST APIs and real-time WebSockets, while the Python-based AI services process complex computer vision and natural language tasks asynchronously, delivering an interface that feels alive and highly reactive.",
            
            "Ứng dụng V-Fit mang lại giải pháp theo dõi sức khỏe và tập luyện tích hợp hiện đại và hướng tới người dùng. Được xây dựng trên Flutter, giao diện di động đảm bảo hiệu năng gốc, các chuyển động mượt mà và tương thích tốt trên cả thiết bị iOS và Android. Ứng dụng kết nối với backend thông qua các cổng REST API bảo mật và kênh truyền WebSocket thời gian thực, trong khi các dịch vụ AI bằng Python xử lý bất đồng bộ các tác vụ thị giác máy tính phức tạp, mang lại một giao diện linh hoạt và phản hồi nhanh chóng."
        ],
        
        "Product Features": [
            "The feature architecture of V-Fit is systematically divided to deliver baseline value to all users while gating premium AI capabilities:\n"
            "- Secure User Management (Free): Offers complete registration, OTP verification via email, social logins, and secure token refresh rotation.\n"
            "- Body Metric Profiles (Free): Features onboarding survey inputs, BMI calculation, and historical weight logging.\n"
            "- Exercise Catalog (Free): A library of fitness programs and detailed exercises grouped by muscle groups.\n"
            "- Nutrition Diary (Free): Daily calorie food logging with search capabilities and macronutrient breakdowns.\n"
            "- Gamified Achievements (Free): Streak counting, custom badges, and fitness challenges.\n"
            "- Interactive AI Coach (VIP): Personalized chat advice for workouts and nutrition based on body metrics.\n"
            "- AI Form Check (VIP): Real-time joint angle analysis and voice-guided posture correction during squats/pushups.\n"
            "- AI Body Scan (VIP): Automated posture scan detecting imbalance issues.\n"
            "- VietQR Checkout (VIP Upgrade): Dynamic QR generation and instant VIP upgrade matched automatically via webhooks.",
            
            "Kiến trúc tính năng của V-Fit được phân cấp rõ ràng để mang lại giá trị cốt lõi cho mọi người dùng và cung cấp các đặc quyền AI nâng cao cho tài khoản VIP:\n"
            "- Quản lý Người dùng Bảo mật (Free): Cung cấp tính năng đăng ký, xác thực OTP qua email, đăng nhập mạng xã hội và tự động làm mới phiên làm việc.\n"
            "- Hồ sơ Chỉ số Cơ thể (Free): Khảo sát đầu vào, tính toán chỉ số BMI tự động và lưu trữ lịch sử cân nặng.\n"
            "- Danh mục Bài tập (Free): Thư viện bài tập chi tiết và chương trình tập luyện phân loại theo nhóm cơ.\n"
            "- Nhật ký Dinh dưỡng (Free): Ghi chép lượng calo tiêu thụ hàng ngày, hỗ trợ tìm kiếm món ăn và phân tích tỷ lệ các chất dinh dưỡng.\n"
            "- Gamification & Thử thách (Free): Theo dõi chuỗi ngày tập luyện, nhận huy hiệu thành tích và tham gia thử thách tập luyện.\n"
            "- Trợ lý AI Coach (VIP): Chat tư vấn dinh dưỡng và tập luyện cá nhân hóa theo thời gian thực dựa trên hồ sơ thể chất.\n"
            "- AI Form Check (VIP): Phân tích góc khớp xương và hướng dẫn sửa lỗi động tác bằng giọng nói thời gian thực qua camera khi tập Squat/Pushup.\n"
            "- AI Body Scan (VIP): Quét dáng người tự động phát hiện lệch vẹo tư thế.\n"
            "- Thanh toán VietQR (VIP Upgrade): Tạo mã QR động thanh toán và nâng cấp gói VIP tự động 100% qua webhook."
        ],
        
        "Product Demonstration": [
            "The V-Fit product demonstration provides a step-by-step walkthrough of the user journey:\n"
            "1. Registration & Profile Setup: The user signs up, verifies their account via email OTP, and completes the body survey, landing on a customized home dashboard.\n"
            "2. AI Coach Consultation: The user opens the AI Coach chat and asks for a weight loss plan. The AI analyzes their profile (e.g., BMI 26.5) and generates a custom diet and workout plan.\n"
            "3. Real-Time Exercise Check: The user starts a squat session. The app requests camera access, streams video frames via WebSockets to the Flask server, and the AI voice engine issues immediate audio warnings (e.g., 'Keep your back straight') as the user exercises.\n"
            "4. Calorie Food Scan: The user takes a photo of their plate, and the AI engine automatically estimates the food weight, calories, and macro split.\n"
            "5. VietQR Payment Automation: The user upgrades to premium, scans the generated VietQR, transfers the payment, and the SePay webhook registers the transaction, instantly activating the VIP badge.",
            
            "Kịch bản trình diễn (demo) sản phẩm V-Fit đi qua từng bước cụ thể của hành trình khách hàng:\n"
            "1. Đăng ký & Thiết lập Hồ sơ: Người dùng đăng ký, xác thực tài khoản qua OTP email và hoàn thành khảo sát cơ thể đầu vào để mở khóa giao diện chính.\n"
            "2. Tư vấn cùng AI Coach: Người dùng mở phòng chat AI Coach, yêu cầu lập kế hoạch giảm cân. Trợ lý AI phân tích chỉ số hồ sơ (ví dụ: BMI 26.5) để đưa ra thực đơn và lịch tập phù hợp.\n"
            "3. Tập luyện cùng AI Form Check: Người dùng bắt đầu bài tập squat. Ứng dụng bật camera, truyền luồng ảnh qua WebSocket tới máy chủ Flask, hệ thống AI phát hiện lỗi sai và phát âm thanh cảnh báo lập tức (ví dụ: 'Hãy giữ lưng thẳng').\n"
            "4. Quét calo Bữa ăn: Người dùng chụp ảnh đĩa thức ăn, hệ thống AI tự động phân tích và trả về ước tính trọng lượng, calo và chất dinh dưỡng của bữa ăn.\n"
            "5. Thanh toán Tự động VietQR: Người dùng bấm nâng cấp Premium, quét mã VietQR chuyển khoản, SePay webhook ghi nhận giao dịch và kích hoạt ngay huy hiệu VIP tức thì."
        ],
        
        "VII. Conclusion": [
            "In conclusion, V-Fit has successfully bridged the gap between advanced artificial intelligence and practical health management, progressing from an early concept in EXE101 to a robust, functional software product in EXE201. By utilizing a modular monolith backend architecture (Spring Boot 3.3.5), modern cross-platform frontend components (Flutter), low-latency WebSocket communication pipelines, and automated webhook-based financial reconciliation, the project has proved its technical feasibility. Furthermore, the outstanding conversion rates (1.35% overall conversion click-to-VIP) validate strong market demand. This established codebase and business model provide a stable foundation for future scaling and production-level launch.",
            
            "Tóm lại, dự án V-Fit đã thu hẹp thành công khoảng cách giữa trí tuệ nhân tạo tiên tiến và thực tiễn quản lý sức khỏe, chuyển mình từ một ý tưởng ban đầu trong học phần EXE101 thành một sản phẩm phần mềm hoàn thiện và hoạt động ổn định trong học phần EXE201. Bằng việc kết hợp kiến trúc backend Modular Monolith (Spring Boot 3.3.5), giao diện di động đa nền tảng hiện đại (Flutter), luồng kết nối WebSocket thời gian thực độ trễ thấp và tự động hóa đối soát tài chính qua Webhook SePay, dự án đã chứng minh được tính khả thi kỹ thuật vượt trội. Hơn thế nữa, tỷ lệ chuyển đổi ấn tượng (tỷ lệ chuyển đổi tổng thể 1.35%) cho thấy nhu cầu thực tế mạnh mẽ từ thị trường. Nền tảng mã nguồn và mô hình kinh doanh đã được thiết lập này sẽ là cơ sở vững chắc cho việc mở rộng quy mô sản phẩm trong tương lai."
        ]
    }
    
    # 1. Clean the document
    print("Step 1: Cleaning document headings...")
    clean_document_headings(doc)
    
    # 2. Fill the document
    print("Step 2: Filling document content...")
    updated_headings = set()
    for heading, paragraphs in content_map.items():
        found = False
        for idx, para in enumerate(doc.paragraphs):
            if para.text.strip() == heading and heading not in updated_headings:
                print(f"Found heading: {heading} at index {idx}")
                found = True
                updated_headings.add(heading)
                
                current_target = para
                for item in paragraphs:
                    lines = item.split('\n')
                    for line in lines:
                        new_p = insert_paragraph_after(current_target, line)
                        current_target = new_p
                    current_target = insert_paragraph_after(current_target, "")
                break
        if not found:
            print(f"Warning: Heading '{heading}' not found in document.")
            
    doc.save(output_path)
    print(f"Saved processed document to {output_path}")

if __name__ == '__main__':
    src = r"d:\EXE_PRM\OC3.docx"
    temp_workspace = r"C:\Users\ADMIN\.gemini\antigravity\brain\fdf784f8-1c7d-4df0-98b4-c08eeb106f23\scratch\OC3_temp.docx"
    final_output = r"C:\Users\ADMIN\.gemini\antigravity\brain\fdf784f8-1c7d-4df0-98b4-c08eeb106f23\scratch\OC3_filled.docx"
    
    # Copy from src to temp_workspace to perform work
    print(f"Copying {src} to {temp_workspace}...")
    shutil.copy2(src, temp_workspace)
    
    # Process
    doc = docx.Document(temp_workspace)
    fill_document_content(doc, temp_workspace)
    
    # Copy processed to final_output
    shutil.copy2(temp_workspace, final_output)
    
    # Attempt to copy back to source
    try:
        shutil.copy2(final_output, src)
        print("SUCCESS: Copied filled document back to d:\\EXE_PRM\\OC3.docx")
    except PermissionError:
        print("WARNING: Cannot write back to d:\\EXE_PRM\\OC3.docx because the file is locked (probably open in Word).")
        print("Please ask the user to close Word, then run the copy command.")
