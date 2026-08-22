# scripts/collect_phase_data.py

import csv
import sys
import time
from pathlib import Path

import cv2


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(PROJECT_ROOT))


from shared.pose_estimation import PoseEstimator
from shared.keypoint_utils import extract_keypoints
from shared.drawing_utils import draw_pose_landmarks, draw_unicode_text

from ai_rep_counter.features import (
    keypoints_to_feature_vector,
    get_feature_size,
)


OUTPUT_PATH = PROJECT_ROOT / "data" / "rep_counter" / "phase_dataset.csv"

WINDOW_NAME = "Collect Phase Data"

DISPLAY_WIDTH = 1280
DISPLAY_HEIGHT = 720

CAMERA_WIDTH = 1280
CAMERA_HEIGHT = 720


LABELS = {
    "0": "other",
    "1": "squat_up",
    "2": "squat_down",
    "3": "pushup_up",
    "4": "pushup_down",
}


# Thời gian chuẩn bị trước khi bắt đầu record
PREPARE_SECONDS = 5

# Thời gian record mặc định cho từng class
LABEL_RECORD_SECONDS = {
    "other": 60,
    "squat_up": 30,
    "squat_down": 30,
    "pushup_up": 30,
    "pushup_down": 30,
}


def create_csv_if_needed():
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    if OUTPUT_PATH.exists():
        return

    header = ["label"]
    header += [f"f_{i}" for i in range(get_feature_size())]

    with open(OUTPUT_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)


def append_sample(label, features):
    with open(OUTPUT_PATH, "a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([label] + features.tolist())


def count_existing_samples():
    counts = {label: 0 for label in LABELS.values()}

    if not OUTPUT_PATH.exists():
        return counts

    with open(OUTPUT_PATH, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        next(reader, None)

        for row in reader:
            if not row:
                continue

            label = row[0]

            if label in counts:
                counts[label] += 1

    return counts


def draw_label_counts(frame, counts, start_y):
    x = 20
    y = start_y

    draw_unicode_text(
        frame,
        "Dataset samples:",
        (x, y),
        font_size=20,
        color=(255, 255, 255),
        bold=True,
    )

    y += 30

    for label_name in ["other", "squat_up", "squat_down", "pushup_up", "pushup_down"]:
        draw_unicode_text(
            frame,
            f"{label_name}: {counts.get(label_name, 0)}",
            (x, y),
            font_size=18,
            color=(0, 255, 255),
            bold=False,
        )
        y += 26


def main():
    create_csv_if_needed()

    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("Could not open camera.")
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)

    cv2.namedWindow(WINDOW_NAME, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(WINDOW_NAME, DISPLAY_WIDTH, DISPLAY_HEIGHT)

    pose_estimator = PoseEstimator()

    current_label = None

    mode = "idle"
    # mode:
    # idle      = đang chờ chọn label / bấm SPACE
    # countdown = đang đếm ngược chuẩn bị
    # recording = đang thu data

    countdown_start_time = None
    recording_start_time = None
    record_seconds = 0

    saved_count_session = 0
    saved_count_current_clip = 0

    existing_counts = count_existing_samples()

    print("Controls:")
    print("0 = other")
    print("1 = squat_up")
    print("2 = squat_down")
    print("3 = pushup_up")
    print("4 = pushup_down")
    print("SPACE = start countdown + auto record")
    print("Q = quit")
    print(f"Saving to: {OUTPUT_PATH}")

    while True:
        ret, frame = cap.read()

        if not ret:
            print("Could not read frame.")
            break

        frame = cv2.flip(frame, 1)
        height, width, _ = frame.shape

        results = pose_estimator.detect(frame)
        keypoints = extract_keypoints(results, width, height)

        draw_pose_landmarks(frame, results)

        now = time.time()

        # ====================================================
        # State machine: countdown -> recording -> idle
        # ====================================================

        if mode == "countdown":
            elapsed = now - countdown_start_time
            remaining = PREPARE_SECONDS - elapsed

            if remaining <= 0:
                mode = "recording"
                recording_start_time = time.time()
                saved_count_current_clip = 0
                print(f"Recording started for label: {current_label}")

        elif mode == "recording":
            elapsed = now - recording_start_time
            remaining = record_seconds - elapsed

            if remaining <= 0:
                mode = "idle"
                recording_start_time = None
                existing_counts = count_existing_samples()

                print(
                    f"Recording finished. "
                    f"Label={current_label}, "
                    f"Saved clip samples={saved_count_current_clip}"
                )

            else:
                if keypoints is not None:
                    features = keypoints_to_feature_vector(keypoints)

                    if features is not None and current_label is not None:
                        append_sample(current_label, features)
                        saved_count_session += 1
                        saved_count_current_clip += 1

        # ====================================================
        # UI
        # ====================================================

        draw_unicode_text(
            frame,
            "AI Rep Counter Dataset Collection",
            (20, 25),
            font_size=26,
            color=(255, 255, 255),
            bold=True,
        )

        draw_unicode_text(
            frame,
            f"Current label: {current_label}",
            (20, 65),
            font_size=22,
            color=(0, 255, 255),
            bold=True,
        )

        if current_label is not None:
            draw_unicode_text(
                frame,
                f"Auto record duration: {LABEL_RECORD_SECONDS[current_label]}s",
                (20, 100),
                font_size=20,
                color=(255, 255, 255),
                bold=False,
            )

        # Mode display
        if mode == "idle":
            status_text = "IDLE - choose label, then press SPACE"
            status_color = (255, 255, 255)

        elif mode == "countdown":
            elapsed = now - countdown_start_time
            remaining = max(0, PREPARE_SECONDS - elapsed)
            status_text = f"GET READY: {remaining:.1f}s"
            status_color = (0, 255, 255)

            draw_unicode_text(
                frame,
                f"{int(remaining) + 1}",
                (width // 2 - 40, height // 2 - 80),
                font_size=90,
                color=(0, 255, 255),
                bold=True,
            )

        elif mode == "recording":
            elapsed = now - recording_start_time
            remaining = max(0, record_seconds - elapsed)
            status_text = f"RECORDING: {remaining:.1f}s left | Saved: {saved_count_current_clip}"
            status_color = (0, 0, 255)

            # Red recording indicator
            cv2.circle(frame, (width - 60, 50), 18, (0, 0, 255), -1)

        else:
            status_text = "UNKNOWN"
            status_color = (0, 0, 255)

        draw_unicode_text(
            frame,
            f"Status: {status_text}",
            (20, 135),
            font_size=22,
            color=status_color,
            bold=True,
        )

        draw_unicode_text(
            frame,
            f"Session saved: {saved_count_session}",
            (20, 170),
            font_size=20,
            color=(0, 255, 0),
            bold=True,
        )

        draw_label_counts(
            frame,
            existing_counts,
            start_y=215,
        )

        draw_unicode_text(
            frame,
            "0 other | 1 squat_up | 2 squat_down | 3 pushup_up | 4 pushup_down",
            (20, height - 70),
            font_size=18,
            color=(255, 255, 255),
            bold=False,
        )

        draw_unicode_text(
            frame,
            "SPACE start auto record | Q quit",
            (20, height - 40),
            font_size=18,
            color=(255, 255, 255),
            bold=False,
        )

        display_frame = cv2.resize(frame, (DISPLAY_WIDTH, DISPLAY_HEIGHT))
        cv2.imshow(WINDOW_NAME, display_frame)

        # ====================================================
        # Keyboard
        # ====================================================

        key = cv2.waitKey(1) & 0xFF

        if key == ord("q"):
            break

        key_char = chr(key) if key != 255 else ""

        # Chỉ cho đổi label khi không đang record/countdown
        if mode == "idle" and key_char in LABELS:
            current_label = LABELS[key_char]
            record_seconds = LABEL_RECORD_SECONDS[current_label]
            print(f"Current label: {current_label}")

        # SPACE: bắt đầu countdown rồi auto record
        if key == ord(" "):
            if mode == "idle":
                if current_label is None:
                    print("Choose label first: 0/1/2/3/4")
                else:
                    mode = "countdown"
                    countdown_start_time = time.time()
                    record_seconds = LABEL_RECORD_SECONDS[current_label]
                    print(
                        f"Countdown started. "
                        f"Label={current_label}, "
                        f"Record duration={record_seconds}s"
                    )
            else:
                print("Currently busy. Wait until current recording finishes.")

    pose_estimator.close()
    cap.release()
    cv2.destroyAllWindows()

    print(f"Saved {saved_count_session} new samples this session to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
