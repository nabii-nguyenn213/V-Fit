from shared.constants import IMPORTANT_LANDMARKS

def extract_keypoints(results, frame_width, frame_height):
    """
    Convert MediaPipe landmarks into a clean dictionary.

    Output example:
    {
        "left_shoulder": {
            "x": 320,
            "y": 240,
            "z": -0.12,
            "visibility": 0.99
        }
    }
    """

    if not results.pose_landmarks:
        return None

    landmarks = results.pose_landmarks.landmark
    keypoints = {}

    for name, index in IMPORTANT_LANDMARKS.items():
        lm = landmarks[index]

        keypoints[name] = {
            "x": int(lm.x * frame_width),
            "y": int(lm.y * frame_height),
            "z": lm.z,
            "visibility": lm.visibility,
        }

    return keypoints


def get_point(keypoints, name):
    """
    Return only x, y for angle calculation.
    """
    point = keypoints.get(name)

    if point is None:
        return None

    return [point["x"], point["y"]]
