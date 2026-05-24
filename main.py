import cv2

from shared.pose_estimation import PoseEstimator
from shared.keypoint_utils import extract_keypoints
from shared.angle_calculator import calculate_body_angles
from shared.drawing_utils import (
    draw_pose_landmarks,
    draw_unicode_text,
)

from form_check.form_checker import FormChecker
from form_check.exercise_registry import (
    EXERCISES,
    EXERCISE_SLUGS,
    get_exercise_name,
)
from body_analysis.body_analyzer import BodyAnalyzer


DISPLAY_WIDTH = 1280
DISPLAY_HEIGHT = 720

CAMERA_WIDTH = 1280
CAMERA_HEIGHT = 720

WINDOW_NAME = "V-FIT AI Coach"


def print_exercise_list():
    print("\n===== EXERCISE LIST =====")
    for i, item in enumerate(EXERCISES):
        print(f"{i+1:02d}. {item['display_name']} ({item['slug']})")
    print("=========================\n")


def draw_clean_ui(
    frame,
    form_result,
    current_name,
    camera_view,
    body_type,
    body_note,
):
    h, w, _ = frame.shape

    overlay = frame.copy()

    # Left top panel
    cv2.rectangle(overlay, (20, 20), (520, 210), (18, 18, 18), -1)

    # Bottom panel
    cv2.rectangle(overlay, (20, h - 140), (760, h - 20), (18, 18, 18), -1)

    # Right feedback panel
    cv2.rectangle(
        overlay,
        (w - 520, 20),
        (w - 20, 135),
        (20, 30, 45),
        -1,
    )

    cv2.addWeighted(
        overlay,
        0.72,
        frame,
        0.28,
        0,
        frame,
    )

    reps = form_result.get(
        "rep_count",
        form_result.get("reps", 0),
    )

    score = form_result.get("score", "--")
    stage = form_result.get("stage", "--")

    feedback = (
        form_result.get("feedback")
        or form_result.get("message")
        or form_result.get("correction")
        or "Keep your form stable"
    )

    # Header
    draw_unicode_text(
        frame,
        "V-FIT AI COACH",
        (40, 55),
        font_size=28,
        color=(0, 255, 180),
        bold=True,
    )

    draw_unicode_text(
        frame,
        f"Exercise: {current_name}",
        (40, 95),
        font_size=22,
        color=(255, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        f"View: {camera_view.upper()} | Reps: {reps}",
        (40, 130),
        font_size=18,
        color=(200, 220, 255),
        bold=False,
    )

    draw_unicode_text(
        frame,
        f"Score: {score} | Stage: {stage}",
        (40, 162),
        font_size=18,
        color=(255, 230, 120),
        bold=False,
    )

    draw_unicode_text(
        frame,
        "N Next | P Prev | R Reset | F/S View | Q Quit",
        (40, 192),
        font_size=16,
        color=(200, 200, 200),
        bold=False,
    )

    # Right feedback
    draw_unicode_text(
        frame,
        "FORM FEEDBACK",
        (w - 500, 55),
        font_size=23,
        color=(0, 255, 180),
        bold=True,
    )

    draw_unicode_text(
        frame,
        str(feedback)[:65],
        (w - 500, 92),
        font_size=17,
        color=(255, 255, 255),
        bold=False,
    )

    # Bottom body analysis
    draw_unicode_text(
        frame,
        "BODY ANALYSIS",
        (40, h - 95),
        font_size=22,
        color=(0, 255, 255),
        bold=True,
    )

    draw_unicode_text(
        frame,
        body_type,
        (40, h - 63),
        font_size=18,
        color=(255, 255, 255),
        bold=True,
    )

    if body_note:
        draw_unicode_text(
            frame,
            body_note,
            (40, h - 35),
            font_size=16,
            color=(190, 240, 210),
            bold=False,
        )


def main():
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("Could not open camera.")
        return

    cap.set(
        cv2.CAP_PROP_FRAME_WIDTH,
        CAMERA_WIDTH,
    )
    cap.set(
        cv2.CAP_PROP_FRAME_HEIGHT,
        CAMERA_HEIGHT,
    )

    cv2.namedWindow(
        WINDOW_NAME,
        cv2.WINDOW_NORMAL,
    )

    cv2.resizeWindow(
        WINDOW_NAME,
        DISPLAY_WIDTH,
        DISPLAY_HEIGHT,
    )

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

    print_exercise_list()

    while True:
        ret, frame = cap.read()

        if not ret:
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
            angles = calculate_body_angles(
                keypoints
            )

            form_result = form_checker.check(
                keypoints,
                angles,
            )

            if frame_counter % 30 == 0:
                report = body_analyzer.generate_report(
                    landmarks=keypoints,
                    body_measurements=None,
                )

                if (
                    report
                    and report.get("status")
                    == "success"
                ):
                    current_body_type = report.get(
                        "body_type",
                        "Unknown",
                    )

                    current_desc = report.get(
                        "general_description",
                        "",
                    )
        else:
            form_result = form_checker.check(
                None,
                None,
            )

        frame_counter += 1

        # Draw skeleton only
        draw_pose_landmarks(
            frame,
            results,
        )

        # New UI
        current_name = get_exercise_name(
            current_exercise
        )

        draw_clean_ui(
            frame,
            form_result,
            current_name,
            camera_view,
            current_body_type,
            current_desc,
        )

        display_frame = cv2.resize(
            frame,
            (
                DISPLAY_WIDTH,
                DISPLAY_HEIGHT,
            ),
        )

        cv2.imshow(
            WINDOW_NAME,
            display_frame,
        )

        key = cv2.waitKey(1) & 0xFF

        if key == ord("q"):
            break

        elif key == ord("r"):
            form_checker.reset()

        elif key == ord("f"):
            camera_view = "front"
            form_checker.set_camera_view(
                camera_view
            )

        elif key == ord("s"):
            camera_view = "side"
            form_checker.set_camera_view(
                camera_view
            )

        elif key == ord("n"):
            exercise_index = (
                exercise_index + 1
            ) % len(EXERCISE_SLUGS)

            current_exercise = EXERCISE_SLUGS[
                exercise_index
            ]

            form_checker = FormChecker(
                exercise=current_exercise,
                camera_view=camera_view,
            )

        elif key == ord("p"):
            exercise_index = (
                exercise_index - 1
            ) % len(EXERCISE_SLUGS)

            current_exercise = EXERCISE_SLUGS[
                exercise_index
            ]

            form_checker = FormChecker(
                exercise=current_exercise,
                camera_view=camera_view,
            )

    pose_estimator.close()
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()