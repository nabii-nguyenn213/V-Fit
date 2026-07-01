import numpy as np

def calculate_angle(a, b, c):
    """
    Calculate angle ABC.
    b is the center point.

    Example:
        angle(hip, knee, ankle) = knee angle
    """

    if a is None or b is None or c is None:
        return None

    a = np.array(a)
    b = np.array(b)
    c = np.array(c)

    radians = np.arctan2(c[1] - b[1], c[0] - b[0]) - \
              np.arctan2(a[1] - b[1], a[0] - b[0])

    angle = abs(radians * 180.0 / np.pi)

    if angle > 180:
        angle = 360 - angle

    return angle


def calculate_body_angles(keypoints):
    """
    Calculate common body angles used by form check.
    """

    from shared.keypoint_utils import get_point

    left_shoulder = get_point(keypoints, "left_shoulder")
    right_shoulder = get_point(keypoints, "right_shoulder")

    left_elbow = get_point(keypoints, "left_elbow")
    right_elbow = get_point(keypoints, "right_elbow")

    left_wrist = get_point(keypoints, "left_wrist")
    right_wrist = get_point(keypoints, "right_wrist")

    left_hip = get_point(keypoints, "left_hip")
    right_hip = get_point(keypoints, "right_hip")

    left_knee = get_point(keypoints, "left_knee")
    right_knee = get_point(keypoints, "right_knee")

    left_ankle = get_point(keypoints, "left_ankle")
    right_ankle = get_point(keypoints, "right_ankle")

    angles = {
        "left_elbow": calculate_angle(left_shoulder, left_elbow, left_wrist),
        "right_elbow": calculate_angle(right_shoulder, right_elbow, right_wrist),

        "left_shoulder": calculate_angle(left_elbow, left_shoulder, left_hip),
        "right_shoulder": calculate_angle(right_elbow, right_shoulder, right_hip),

        "left_hip": calculate_angle(left_shoulder, left_hip, left_knee),
        "right_hip": calculate_angle(right_shoulder, right_hip, right_knee),

        "left_knee": calculate_angle(left_hip, left_knee, left_ankle),
        "right_knee": calculate_angle(right_hip, right_knee, right_ankle),
    }

    return angles
