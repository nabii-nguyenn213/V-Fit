import time
from collections import Counter, deque

import cv2

from shared.pose_estimation import PoseEstimator
from shared.keypoint_utils import extract_keypoints
from shared.angle_calculator import calculate_body_angles
from shared.drawing_utils import (
    draw_pose_landmarks,
    draw_unicode_text,
)

from form_check.form_checker import FormChecker
from form_check.feedback_stabilizer import FeedbackStabilizer
from ai_rep_counter.realtime_rep_counter import AIRealtimeRepCounter


# ============================================================
# Config
# ============================================================

WINDOW_NAME = "V-FIT AI Coach"

DISPLAY_WIDTH = 1280
DISPLAY_HEIGHT = 720

CAMERA_WIDTH = 1280
CAMERA_HEIGHT = 720

SHOW_SKELETON = True

COUNTDOWN_SECONDS = 3

# AI confidence required for start pose
START_CONFIDENCE_THRESHOLD = 0.65

# Number of recent frames used to confirm start pose
START_HISTORY_SIZE = 15
STABLE_FRAMES_REQUIRED = 10

# Stabilize form warning text
FEEDBACK_STABLE_FRAMES = 8
FEEDBACK_HOLD_SECONDS = 2.0


EXERCISES = {
    "1": "squat",
    "2": "pushup",
}

EXERCISE_NAMES = {
    "squat": "Squat",
    "pushup": "Push-up",
}

EXERCISE_START_LABEL = {
    "squat": "squat_up",
    "pushup": "pushup_up",
}


# ============================================================
# AI helpers
# ============================================================

def predict_raw_label(rep_counter, keypoints):
    """
    Use AI phase model only to detect preparation pose.
    This does NOT increase rep count.
    """

    if not rep_counter.enabled:
        return "model_missing", 0.0

    if keypoints is None:
        return "no_pose", 0.0

    label, confidence = rep_counter._predict_label(keypoints)
    return label, confidence


def is_start_pose_stable(history, target_label):
    """
    Check if target start label appears enough times in recent frames.
    """

    if len(history) < START_HISTORY_SIZE:
        return False

    counter = Counter(history)
    count = counter.get(target_label, 0)

    return count >= STABLE_FRAMES_REQUIRED


def get_first_error_feedback(form_result, current_exercise=None, rep_result=None):
    """
    Keep old form-check logic, but only display depth-related errors
    when the AI has detected the bottom phase.

    Squat:
    - Only show squat_not_deep_enough after AI detects squat_down.

    Push-up:
    - Only show pushup_not_low_enough after AI detects pushup_down.

    This prevents warnings from appearing while the user is still moving down.
    """

    if form_result is None:
        return None

    feedback_list = form_result.get("feedback", [])

    if not feedback_list:
        return None

    phase = "unknown"
    ai_label = "unknown"

    if rep_result is not None:
        phase = rep_result.get("phase", "unknown")
        ai_label = rep_result.get("label", "unknown")

    for fb in feedback_list:
        code = fb.get("code", "")

        if code in ["good_form", "no_pose"]:
            continue

        # ====================================================
        # Squat depth warning
        # Only check after AI detects bottom squat phase.
        # ====================================================
        if current_exercise == "squat" and code == "squat_not_deep_enough":
            if ai_label != "squat_down":
                continue

        # ====================================================
        # Push-up depth warning
        # Only check after AI detects bottom push-up phase.
        # ====================================================
        if current_exercise == "pushup" and code == "pushup_not_low_enough":
            if ai_label != "pushup_down":
                continue

        return fb

    return None

# ============================================================
# UI
# ============================================================

def draw_choose_exercise_ui(frame):
    height, width = frame.shape[:2]

    draw_unicode_text(
        frame,
        "V-FIT AI COACH",
        (40, 45),
        font_size=38,
        color=(255, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        "Chọn bài tập",
        (40, 105),
        font_size=32,
        color=(0, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        "1 = Squat",
        (40, 160),
        font_size=28,
        color=(255, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        "2 = Push-up",
        (40, 205),
        font_size=28,
        color=(255, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        "Q: thoát",
        (40, height - 45),
        font_size=20,
        color=(255, 255, 255),
        bold=False,
    )


def draw_wait_start_pose_ui(frame, current_exercise, label, confidence):
    height, width = frame.shape[:2]

    exercise_name = EXERCISE_NAMES.get(current_exercise, current_exercise)
    target_label = EXERCISE_START_LABEL.get(current_exercise, "")

    if current_exercise == "squat":
        instruction = "Đứng thẳng ở tư thế chuẩn bị squat"
    elif current_exercise == "pushup":
        instruction = "Vào tư thế push-up trên, tay gần thẳng"
    else:
        instruction = "Vào tư thế chuẩn bị"

    draw_unicode_text(
        frame,
        exercise_name,
        (40, 45),
        font_size=38,
        color=(0, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        "Chuẩn bị tư thế bắt đầu",
        (40, 105),
        font_size=30,
        color=(255, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        instruction,
        (40, 150),
        font_size=24,
        color=(255, 255, 255),
        bold=False,
    )

    color = (
        (0, 255, 0)
        if label == target_label and confidence >= START_CONFIDENCE_THRESHOLD
        else (0, 255, 255)
    )

    draw_unicode_text(
        frame,
        f"AI: {label} ({confidence:.2f})",
        (40, 195),
        font_size=22,
        color=color,
        bold=True,
    )

    draw_unicode_text(
        frame,
        "C: chọn lại bài | Q: thoát",
        (40, height - 45),
        font_size=20,
        color=(255, 255, 255),
        bold=False,
    )


def draw_countdown_ui(frame, current_exercise, remaining):
    height, width = frame.shape[:2]

    exercise_name = EXERCISE_NAMES.get(current_exercise, current_exercise)

    draw_unicode_text(
        frame,
        exercise_name,
        (40, 50),
        font_size=38,
        color=(0, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        "Bắt đầu sau",
        (40, 105),
        font_size=30,
        color=(255, 255, 255),
        bold=True,
    )

    number = max(1, int(remaining) + 1)

    draw_unicode_text(
        frame,
        str(number),
        (width // 2 - 45, height // 2 - 110),
        font_size=130,
        color=(0, 255, 255),
        bold=True,
    )


def draw_active_ui(frame, current_exercise, rep_result, stable_feedback):
    height, width = frame.shape[:2]

    exercise_name = EXERCISE_NAMES.get(current_exercise, current_exercise)

    rep_count = rep_result.get("rep_count", 0)
    phase = rep_result.get("phase", "unknown")
    label = rep_result.get("label", "unknown")
    confidence = rep_result.get("confidence", 0.0)
    enabled = rep_result.get("enabled", False)

    ai_status = "ON" if enabled else "NO MODEL"

    draw_unicode_text(
        frame,
        exercise_name,
        (40, 40),
        font_size=34,
        color=(255, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        f"REPS: {rep_count}",
        (40, 95),
        font_size=64,
        color=(0, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        f"{phase} | {label} | {confidence:.2f} | AI {ai_status}",
        (40, 170),
        font_size=18,
        color=(255, 255, 255),
        bold=False,
    )

    if stable_feedback is None:
        draw_unicode_text(
            frame,
            "FORM: OK",
            (40, 225),
            font_size=34,
            color=(0, 255, 0),
            bold=True,
        )
    else:
        warning = stable_feedback.get("warning", "")
        correction = stable_feedback.get("correction", "")
        severity = stable_feedback.get("severity", "medium")

        color = (0, 0, 255) if severity == "high" else (0, 255, 255)

        draw_unicode_text(
            frame,
            f"LỖI: {warning}",
            (40, 225),
            font_size=28,
            color=color,
            bold=True,
        )

        draw_unicode_text(
            frame,
            f"SỬA: {correction}",
            (40, 265),
            font_size=22,
            color=(255, 255, 255),
            bold=False,
        )

    draw_unicode_text(
        frame,
        "R: reset | C: chọn lại bài | Q: thoát",
        (40, height - 45),
        font_size=20,
        color=(255, 255, 255),
        bold=False,
    )


# ============================================================
# Main
# ============================================================

def main():
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("Could not open camera.")
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)

    cv2.namedWindow(WINDOW_NAME, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(WINDOW_NAME, DISPLAY_WIDTH, DISPLAY_HEIGHT)

    pose_estimator = PoseEstimator()

    rep_counter = AIRealtimeRepCounter(
        model_path="ai_rep_counter/models/phase_model.pt",
    )

    feedback_stabilizer = FeedbackStabilizer(
        stable_frames=FEEDBACK_STABLE_FRAMES,
        hold_seconds=FEEDBACK_HOLD_SECONDS,
    )

    app_state = "choose_exercise"
    # choose_exercise  = user chooses squat/pushup with keyboard
    # wait_start_pose  = app waits until AI detects squat_up/pushup_up
    # countdown        = 3-second countdown
    # active           = count reps + form check

    current_exercise = None
    camera_view = "front"
    form_checker = None

    start_label_history = deque(maxlen=START_HISTORY_SIZE)
    countdown_start_time = None

    print("V-FIT AI Coach started")
    print("Controls:")
    print("1 = Squat")
    print("2 = Push-up")
    print("R = reset")
    print("C = choose exercise again")
    print("Q = quit")

    while True:
        ret, frame = cap.read()

        if not ret:
            print("Could not read frame.")
            break

        frame = cv2.flip(frame, 1)
        height, width, _ = frame.shape

        results = pose_estimator.detect(frame)

        keypoints = extract_keypoints(
            results,
            width,
            height,
        )

        angles = None

        if keypoints is not None:
            angles = calculate_body_angles(keypoints)

        if SHOW_SKELETON:
            draw_pose_landmarks(frame, results)

        # ====================================================
        # State 1: choose exercise
        # ====================================================

        if app_state == "choose_exercise":
            draw_choose_exercise_ui(frame)

        # ====================================================
        # State 2: wait start pose
        # ====================================================

        elif app_state == "wait_start_pose":
            label, confidence = predict_raw_label(rep_counter, keypoints)

            target_label = EXERCISE_START_LABEL[current_exercise]

            if confidence >= START_CONFIDENCE_THRESHOLD:
                start_label_history.append(label)
            else:
                start_label_history.append("low_confidence")

            if is_start_pose_stable(start_label_history, target_label):
                rep_counter.reset(current_exercise)
                feedback_stabilizer.reset()

                countdown_start_time = time.time()
                app_state = "countdown"
                start_label_history.clear()

                print(f"Start pose detected: {target_label}")
                print("Countdown started.")

            draw_wait_start_pose_ui(
                frame,
                current_exercise=current_exercise,
                label=label,
                confidence=confidence,
            )

        # ====================================================
        # State 3: countdown
        # ====================================================

        elif app_state == "countdown":
            elapsed = time.time() - countdown_start_time
            remaining = COUNTDOWN_SECONDS - elapsed

            if remaining <= 0:
                rep_counter.reset(current_exercise)
                feedback_stabilizer.reset()
                app_state = "active"
                print("Start training.")

            draw_countdown_ui(
                frame,
                current_exercise=current_exercise,
                remaining=remaining,
            )

        # ====================================================
        # State 4: active
        # ====================================================

        elif app_state == "active":
            if keypoints is not None:
                rep_result = rep_counter.update(
                    keypoints=keypoints,
                    exercise=current_exercise,
                )

                form_result = form_checker.check(
                    keypoints,
                    angles,
                )

                raw_feedback = get_first_error_feedback(
                    form_result=form_result,
                    current_exercise=current_exercise,
                    rep_result=rep_result,
                )

                stable_feedback = feedback_stabilizer.update(raw_feedback)

            else:
                rep_result = {
                    "rep_count": 0,
                    "phase": "no_pose",
                    "label": "no_pose",
                    "confidence": 0.0,
                    "enabled": rep_counter.enabled,
                }

                stable_feedback = feedback_stabilizer.update(None)

            draw_active_ui(
                frame,
                current_exercise=current_exercise,
                rep_result=rep_result,
                stable_feedback=stable_feedback,
            )

        # ====================================================
        # Show
        # ====================================================

        display_frame = cv2.resize(
            frame,
            (DISPLAY_WIDTH, DISPLAY_HEIGHT),
        )

        cv2.imshow(WINDOW_NAME, display_frame)

        # ====================================================
        # Keyboard controls
        # ====================================================

        key = cv2.waitKey(1) & 0xFF

        if key == ord("q"):
            break

        elif key == ord("c"):
            current_exercise = None
            form_checker = None
            start_label_history.clear()
            feedback_stabilizer.reset()
            rep_counter.reset()
            app_state = "choose_exercise"
            print("Back to exercise selection.")

        elif key == ord("r"):
            if current_exercise is not None:
                rep_counter.reset(current_exercise)
                feedback_stabilizer.reset()
                start_label_history.clear()
                app_state = "wait_start_pose"
                print(f"Reset {current_exercise}. Waiting for start pose.")
            else:
                app_state = "choose_exercise"
                print("Reset. Choose exercise.")

        elif key != 255:
            key_char = chr(key)

            if app_state == "choose_exercise" and key_char in EXERCISES:
                current_exercise = EXERCISES[key_char]

                form_checker = FormChecker(
                    exercise=current_exercise,
                    camera_view=camera_view,
                )

                rep_counter.reset(current_exercise)
                feedback_stabilizer.reset()
                start_label_history.clear()

                app_state = "wait_start_pose"

                print(f"Selected exercise: {current_exercise}")
                print("Waiting for correct start pose.")

    pose_estimator.close()
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
