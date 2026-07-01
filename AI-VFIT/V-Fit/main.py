import cv2
import math
import mediapipe as mp

from shared.pose_estimation import PoseEstimator
from shared.angle_calculator import calculate_body_angles
from shared.drawing_utils import (
    draw_pose_landmarks,
    draw_form_result,
    draw_unicode_text,
)

from form_check.form_checker import FormChecker
from form_check.exercise_registry import (
    EXERCISES,
    EXERCISE_SLUGS,
    get_exercise_name,
)
from body_analysis.body_analyzer import BodyAnalyzer


# ============================================================
# Config & State
# ============================================================
DISPLAY_WIDTH = 1280
DISPLAY_HEIGHT = 720
CAMERA_WIDTH = 1280
CAMERA_HEIGHT = 720
WINDOW_NAME = "V-FIT AI Coach"

# --- CÁC HÀM VÀ BIẾN TỪ CODE LOCAL (HEAD) ĐƯỢC GIỮ LẠI ĐỂ DỰ PHÒNG ---
APP_STAGE = "SCAN_BODY" 
SAVED_BODY_TYPE = None
SAVED_BODY_DESC = None
RECOMMENDED_EXERCISES = []

frame_counter = 0 
COUNTDOWN_TOTAL_FRAMES = 90 

def get_recommendations(body_type):
    """
    Hàm gợi ý bài tập khớp chuẩn xác với kết quả từ AI Model Deep Learning
    """
    recommendations = []
    if not body_type:
        return ["squat", "bicep_curl", "barbell_bench_press", "pull_up"]
        
    body_type_upper = body_type.upper()
    
    if "CHU V" in body_type_upper:
        recommendations = ["squat", "dumbbell_lateral_raise", "romanian_deadlift"]
    elif "QUA LE" in body_type_upper:
        recommendations = ["squat", "deadlift", "leg_press", "pull_up"]
    elif "CHU NHAT" in body_type_upper:
        recommendations = ["squat", "bicep_curl", "barbell_bench_press", "pull_up"]
    else:
        recommendations = ["squat", "bicep_curl", "barbell_bench_press", "pull_up"]
        
    return recommendations

def extract_keypoints(results, width, height):
    """ Hàm này được giữ lại vì code Pull về vẫn sử dụng trong main loop """
    if getattr(results, 'pose_landmarks', None) is None:
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

# --- CÁC HÀM TỪ CODE PULL VỀ (INCOMING) ---
def print_exercise_list():
    print("\n===== EXERCISE LIST =====")
    for i, item in enumerate(EXERCISES):
        print(f"{i + 1:02d}. {item['display_name']} ({item['slug']})")
    print("=========================\n")


def draw_body_analysis_panel(
    frame,
    current_body_type,
    current_desc,
    current_imbalances,
):
    """
    Draw Người 2: Body Analysis result.
    """

    x = 20
    y = 280

    draw_unicode_text(
        frame,
        f"Body Shape: {current_body_type}",
        (x, y),
        font_size=22,
        color=(255, 255, 0),
        bold=True,
    )

    if current_desc:
        draw_unicode_text(
            frame,
            f"Body Note: {current_desc}",
            (x, y + 35),
            font_size=18,
            color=(0, 255, 255),
            bold=False,
        )

    y_offset = y + 75

    if current_imbalances:
        for issue in current_imbalances:
            color = (0, 255, 0) if ("THANG" in issue or "CAN" in issue) else (0, 0, 255)

            draw_unicode_text(
                frame,
                f"- {issue}",
                (x, y_offset),
                font_size=18,
                color=color,
                bold=False,
            )

            y_offset += 32
    else:
        draw_unicode_text(
            frame,
            "- Tư thế: CÂN ĐỐI",
            (x, y_offset),
            font_size=18,
            color=(0, 255, 0),
            bold=True,
        )


def draw_control_panel(
    frame,
    exercise_index,
    current_exercise,
    camera_view,
    height,
):
    """
    Draw current exercise and keyboard controls.
    """

    current_name = get_exercise_name(current_exercise)

    draw_unicode_text(
        frame,
        f"Bài hiện tại: {exercise_index + 1}/{len(EXERCISE_SLUGS)} - {current_name}",
        (20, height - 105),
        font_size=22,
        color=(0, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        f"View: {camera_view} | N: bài tiếp | P: bài trước | R: reset | F: front | S: side | L: list | Q: thoát",
        (20, height - 72),
        font_size=18,
        color=(255, 255, 255),
        bold=False,
    )


def main():
    global APP_STAGE, SAVED_BODY_TYPE, SAVED_BODY_DESC, RECOMMENDED_EXERCISES, frame_counter
    
    # ========================================================
    # KHỞI ĐỘNG V-FIT AI COACH (Thuần Computer Vision)
    # ========================================================
    print("\n" + "="*50)
    print(" 🚀 CHÀO MỪNG ĐẾN VỚI V-FIT AI COACH ")
    print("="*50)
    print("⏳ Đang khởi động Camera và tải AI Model, vui lòng chờ...\n")
    # ========================================================
    
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Could not open camera.")
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)

    cv2.namedWindow(WINDOW_NAME, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(WINDOW_NAME, DISPLAY_WIDTH, DISPLAY_HEIGHT)

    # ⚠️ Nhớ import module này ở đầu file nếu chưa có
    pose_estimator = PoseEstimator()
    body_analyzer = BodyAnalyzer()
    
    exercise_index = 0
    current_exercise = EXERCISE_SLUGS[exercise_index]
    camera_view = "side"
    
    form_checker = FormChecker(
        exercise=current_exercise,
        camera_view=camera_view,
    )

    frame_counter = 0
    current_body_type = "Analyzing..."
    current_desc = ""
    current_imbalances = []
    countdown_counter = COUNTDOWN_TOTAL_FRAMES

    print("\n>>> UNG DUNG KHIEN HANH: GIAI DOAN 1 - QUET DANG NGUOI <<<")

    print("Controls:")
    print("N = next exercise")
    print("P = previous exercise")
    print("R = reset reps")
    print("F = front view mode")
    print("S = side view mode")
    print("L = print exercise list")
    print("Q = quit")

    while True:
        ret, frame = cap.read()
        if not ret:
            print("Could not read frame.")
            break

        frame = cv2.flip(frame, 1)
        height, width, _ = frame.shape

        # ====================================================
        # 1. Pose Estimation
        # ====================================================
        results = pose_estimator.detect(frame)

        keypoints = extract_keypoints(
            results,
            width,
            height,
        )

        angles = None

        if keypoints is not None:
            angles = calculate_body_angles(keypoints)

            # Người 1: Form Check
            form_result = form_checker.check(keypoints, angles)

            # Người 2: Realtime imbalance check
            if hasattr(body_analyzer, "imbalance_detector"):
                current_imbalances = body_analyzer.imbalance_detector.detect_imbalance(
                    keypoints
                )

            # Người 2: Body shape analysis, run every 30 frames
            if frame_counter % 30 == 0:
                report = body_analyzer.generate_report(
                    frame=frame,
                    keypoints=keypoints,
                )

                if report and report.get("status") == "success":
                    current_body_type = report.get("body_type", "Unknown")
                    current_desc = report.get("general_description", "")

        else:
            form_result = form_checker.check(None, None)
            current_imbalances = []
            current_body_type = "Không có người..."
            current_desc = ""

        frame_counter += 1

        # ====================================================
        # 2. Draw UI
        # ====================================================

        draw_pose_landmarks(frame, results)

        # Người 1: form check panel
        draw_form_result(frame, form_result)

        # Người 2: body analysis panel
        draw_body_analysis_panel(
            frame,
            current_body_type,
            current_desc,
            current_imbalances,
        )

        # Controls
        draw_control_panel(
            frame,
            exercise_index,
            current_exercise,
            camera_view,
            height,
        )

        # ====================================================
        # 3. Show frame
        # ====================================================

        display_frame = cv2.resize(
            frame,
            (DISPLAY_WIDTH, DISPLAY_HEIGHT),
        )

        cv2.imshow(WINDOW_NAME, display_frame)

        # ====================================================
        # 4. Keyboard controls
        # ====================================================

        key = cv2.waitKey(1) & 0xFF
        if key == ord("q"):
            break

        elif key == ord("r"):
            form_checker.reset()
            print("Reset reps.")

        elif key == ord("l"):
            print_exercise_list()

        elif key == ord("f"):
            camera_view = "front"
            form_checker.set_camera_view(camera_view)
            print("Switched to front view.")

        elif key == ord("s"):
            camera_view = "side"
            form_checker.set_camera_view(camera_view)
            print("Switched to side view.")

        elif key == ord("n"):
            exercise_index = (exercise_index + 1) % len(EXERCISE_SLUGS)
            current_exercise = EXERCISE_SLUGS[exercise_index]

            form_checker = FormChecker(
                exercise=current_exercise,
                camera_view=camera_view,
            )

            print(
                f"Switched to: {exercise_index + 1}. "
                f"{get_exercise_name(current_exercise)}"
            )

        elif key == ord("p"):
            exercise_index = (exercise_index - 1) % len(EXERCISE_SLUGS)
            current_exercise = EXERCISE_SLUGS[exercise_index]

            form_checker = FormChecker(
                exercise=current_exercise,
                camera_view=camera_view,
            )

            print(
                f"Switched to: {exercise_index + 1}. "
                f"{get_exercise_name(current_exercise)}"
            )

    pose_estimator.close()
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
