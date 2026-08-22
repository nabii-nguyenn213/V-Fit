# ai_rep_counter/features.py

import math
import numpy as np


SELECTED_KEYPOINTS = [
    "nose",

    "left_shoulder",
    "right_shoulder",
    "left_elbow",
    "right_elbow",
    "left_wrist",
    "right_wrist",

    "left_hip",
    "right_hip",
    "left_knee",
    "right_knee",
    "left_ankle",
    "right_ankle",
]


def _point(keypoints, name):
    if keypoints is None:
        return None

    p = keypoints.get(name)

    if p is None:
        return None

    return [
        float(p.get("x", 0.0)),
        float(p.get("y", 0.0)),
        float(p.get("visibility", 0.0)),
    ]


def _distance(p1, p2):
    if p1 is None or p2 is None:
        return None

    return math.sqrt((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2)


def _midpoint(p1, p2):
    if p1 is None or p2 is None:
        return None

    return [
        (p1[0] + p2[0]) / 2.0,
        (p1[1] + p2[1]) / 2.0,
    ]


def get_feature_size():
    return len(SELECTED_KEYPOINTS) * 3


def keypoints_to_feature_vector(keypoints):
    """
    Convert MediaPipe keypoints dict into normalized feature vector.

    Output:
        numpy array shape = [39]
    """

    if keypoints is None:
        return None

    left_hip = _point(keypoints, "left_hip")
    right_hip = _point(keypoints, "right_hip")
    left_shoulder = _point(keypoints, "left_shoulder")
    right_shoulder = _point(keypoints, "right_shoulder")

    hip_center = _midpoint(left_hip, right_hip)

    if hip_center is None:
        return None

    shoulder_width = _distance(left_shoulder, right_shoulder)
    hip_width = _distance(left_hip, right_hip)

    scale_candidates = [
        v for v in [shoulder_width, hip_width]
        if v is not None and v > 1e-6
    ]

    if not scale_candidates:
        return None

    scale = max(scale_candidates)

    features = []

    for name in SELECTED_KEYPOINTS:
        p = _point(keypoints, name)

        if p is None:
            features.extend([0.0, 0.0, 0.0])
            continue

        x, y, visibility = p

        x_norm = (x - hip_center[0]) / scale
        y_norm = (y - hip_center[1]) / scale

        features.extend([x_norm, y_norm, visibility])

    return np.array(features, dtype=np.float32)
