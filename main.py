import cv2

from shared.pose_estimation import PoseEstimator
from shared.keypoint_utils import extract_keypoints
from shared.angle_calculator import calculate_body_angles
from shared.drawing_utils import (
    draw_pose_landmarks,
    draw_keypoint_names,
    draw_angles,
)


def main():
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("Error: Could not open laptop camera.")
        return

    pose_estimator = PoseEstimator()

    while True:
        ret, frame = cap.read()

        if not ret:
            print("Error: Could not read frame.")
            break

        # Optional mirror effect, easier for webcam demo
        frame = cv2.flip(frame, 1)

        height, width, _ = frame.shape

        # 1. Pose estimation
        results = pose_estimator.detect(frame)

        # 2. Extract keypoints
        keypoints = extract_keypoints(results, width, height)

        # 3. Calculate angles
        angles = None
        if keypoints is not None:
            angles = calculate_body_angles(keypoints)

        # 4. Draw results
        draw_pose_landmarks(frame, results)
        draw_keypoint_names(frame, keypoints)
        draw_angles(frame, keypoints, angles)

        cv2.putText(
            frame,
            "Press Q to quit",
            (20, 40),
            cv2.FONT_HERSHEY_SIMPLEX,
            1,
            (0, 255, 0),
            2,
            cv2.LINE_AA,
        )

        cv2.imshow("AI Fitness App - Pose Detection", frame)

        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    pose_estimator.close()
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
