import cv2
import math
import mediapipe as mp

from shared.drawing_utils import draw_unicode_text
from body_analysis.body_analyzer import BodyAnalyzer

# ============================================================
# Config & State
# ============================================================
DISPLAY_WIDTH = 1280
DISPLAY_HEIGHT = 720
CAMERA_WIDTH = 1280
CAMERA_HEIGHT = 720
WINDOW_NAME = "V-FIT: Body Scanner Only"

COUNTDOWN_TOTAL_FRAMES = 90 

def extract_keypoints(results, width, height):
    if not results.pose_landmarks:
        return None
    keypoints = {}
    for landmark in mp.solutions.pose.PoseLandmark:
        pt = results.pose_landmarks.landmark[landmark.value]
        keypoints[landmark.name.lower()] = {
            'x': pt.x * width,
            'y': pt.y * height,
            'visibility': pt.visibility
        }
    return keypoints

def main():
    # ========================================================
    # KHỞI ĐỘNG V-FIT AI COACH (Chỉ Quét Dáng)
    # ========================================================
    print("\n" + "="*50)
    print(" 🚀 KHOI DONG MODULE: BODY SCANNER ")
    print("="*50)
    print("⏳ Đang khởi động Camera và tải AI Model, vui lòng chờ...\n")
    
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Could not open camera.")
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)
    cv2.namedWindow(WINDOW_NAME, cv2.WINDOW_NORMAL)

    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(
        model_complexity=2, 
        min_detection_confidence=0.6, 
        min_tracking_confidence=0.6,
        enable_segmentation=False 
    )
    mp_drawing = mp.solutions.drawing_utils
    
    body_analyzer = BodyAnalyzer()
    
    countdown_counter = COUNTDOWN_TOTAL_FRAMES
    
    # Trạng thái: "SCAN_BODY" -> "SHOW_RESULT"
    app_stage = "SCAN_BODY"
    saved_body_type = None
    saved_body_desc = None

    print("\n>>> UNG DUNG KHIEN HANH: QUET DANG NGUOI <<<")

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.flip(frame, 1)
        
        # Lưu lại frame gốc chưa bị vẽ xương để AI Model bóc dáng người
        clean_frame = frame.copy() 

        height, width, _ = frame.shape
        image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(image_rgb)
        keypoints = extract_keypoints(results, width, height)

        if results.pose_landmarks:
            mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)

        # =========================================================================
        # GIAI ĐOẠN 1: QUÉT DÁNG NGƯỜI (CÓ ĐO KHOẢNG CÁCH)
        # =========================================================================
        if app_stage == "SCAN_BODY":
            has_valid_points = False
            
            # Kiểm tra xem AI đã thấy đủ Vai và Hông chưa
            if keypoints is not None:
                l_shoulder = keypoints.get('left_shoulder')
                r_shoulder = keypoints.get('right_shoulder')
                l_hip = keypoints.get('left_hip')
                r_hip = keypoints.get('right_hip')
                if all([l_shoulder, r_shoulder, l_hip, r_hip]):
                    has_valid_points = True

            if has_valid_points:
                # TÍNH TOÁN KHOẢNG CÁCH NGẦM (Dựa vào bề ngang vai)
                current_shoulder_width = math.hypot(l_shoulder['x'] - r_shoulder['x'], l_shoulder['y'] - r_shoulder['y'])
                
                # Ngưỡng pixel
                MAX_SHOULDER = 380 
                MIN_SHOULDER = 250
                
                if current_shoulder_width > MAX_SHOULDER:
                    countdown_counter = COUNTDOWN_TOTAL_FRAMES
                    cv2.putText(frame, "QUAN SAT: QUA GAN", (50, 100), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 0, 255), 4, cv2.LINE_AA)
                    cv2.putText(frame, "-> YEU CAU: LUI LAI", (50, 180), cv2.FONT_HERSHEY_SIMPLEX, 2.0, (0, 0, 255), 5, cv2.LINE_AA)
                
                elif current_shoulder_width < MIN_SHOULDER:
                    countdown_counter = COUNTDOWN_TOTAL_FRAMES
                    cv2.putText(frame, "QUAN SAT: QUA XA", (50, 100), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 165, 255), 4, cv2.LINE_AA)
                    cv2.putText(frame, "-> YEU CAU: TIEN LEN", (50, 180), cv2.FONT_HERSHEY_SIMPLEX, 2.0, (0, 165, 255), 5, cv2.LINE_AA)
                
                else:
                    # KHI KHOẢNG CÁCH ĐÃ ĐÚNG TIÊU CHUẨN
                    countdown_counter -= 1
                    seconds_left = max(1, int(countdown_counter / 30) + 1)
                    
                    cv2.putText(frame, "KHOANG CACH CHUAN!", (50, 100), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 4, cv2.LINE_AA)
                    cv2.putText(frame, "GIU NGUYEN TU THE...", (50, 180), cv2.FONT_HERSHEY_SIMPLEX, 2.0, (0, 255, 255), 5, cv2.LINE_AA)
                    
                    # SỐ ĐẾM NGƯỢC
                    cv2.putText(frame, str(seconds_left), (int(width/2) - 50, int(height/2) + 80), 
                                cv2.FONT_HERSHEY_SIMPLEX, 8.0, (0, 255, 0), 15, cv2.LINE_AA)

                    if countdown_counter <= 0:
                        report = body_analyzer.generate_report(frame=clean_frame, keypoints=keypoints)
                        if report and report.get("status") == "success":
                            saved_body_type = report.get("body_type", report.get("body_shape", "Chua xac dinh"))
                            saved_body_desc = report.get("general_description", "Phan tich boi AI Model")
                            app_stage = "SHOW_RESULT"
                        else:
                            countdown_counter = COUNTDOWN_TOTAL_FRAMES
            else:
                # KHI KHÔNG THẤY NGƯỜI HOẶC CHƯA THẤY ĐỦ VAI/HÔNG
                countdown_counter = COUNTDOWN_TOTAL_FRAMES
                cv2.putText(frame, "HAY BUOC VAO CAMERA", (50, 100), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (200, 200, 200), 4, cv2.LINE_AA)
                cv2.putText(frame, "DE BAT DAU QUET", (50, 180), cv2.FONT_HERSHEY_SIMPLEX, 2.0, (255, 255, 255), 5, cv2.LINE_AA)

        # =========================================================================
        # GIAI ĐOẠN 2: HIỂN THỊ KẾT QUẢ ĐỨNG YÊN
        # =========================================================================
        elif app_stage == "SHOW_RESULT":
            # Phủ một lớp nền tối mờ để dễ đọc chữ
            cv2.rectangle(frame, (0, 0), (width, height), (30, 30, 30), -1)
            
            draw_unicode_text(frame, "--- KET QUA QUET DANG NGUOI ---", (20, 80), font_size=28, color=(0, 255, 255), bold=True)
            draw_unicode_text(frame, f"Dang cua ban: {saved_body_type}", (20, 140), font_size=24, color=(0, 255, 0), bold=True)
            draw_unicode_text(frame, f"Chi tiet: {saved_body_desc}", (20, 190), font_size=20, color=(255, 255, 255), bold=False)
            
            draw_unicode_text(frame, "An [R] de quet lai - An [Q] de thoat", (20, height - 50), font_size=18, color=(100, 255, 100), bold=False)

        # =========================================================================
        # HIỂN THỊ VÀ XỬ LÝ PHÍM TẮT
        # =========================================================================
        display_frame = cv2.resize(frame, (DISPLAY_WIDTH, DISPLAY_HEIGHT))
        cv2.imshow(WINDOW_NAME, display_frame)

        key = cv2.waitKey(1) & 0xFF
        if key == ord("q"):
            break
        elif key == ord("r") and app_stage == "SHOW_RESULT":
            app_stage = "SCAN_BODY"
            countdown_counter = COUNTDOWN_TOTAL_FRAMES
            saved_body_type = None
            saved_body_desc = None

    pose.close()
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()