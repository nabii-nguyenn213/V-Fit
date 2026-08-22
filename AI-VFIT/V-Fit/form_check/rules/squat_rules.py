import math

def valid_angle(angle):
    return angle is not None and not math.isnan(angle)


def avg_valid(values):
    valid = [v for v in values if valid_angle(v)]
    if not valid:
        return None
    return sum(valid) / len(valid)


def point(keypoints, name):
    p = keypoints.get(name)
    if p is None:
        return None
    return [p["x"], p["y"]]


def midpoint(a, b):
    if a is None or b is None:
        return None
    return [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2]


def torso_lean_from_vertical(keypoints):
    left_shoulder = point(keypoints, "left_shoulder")
    right_shoulder = point(keypoints, "right_shoulder")
    left_hip = point(keypoints, "left_hip")
    right_hip = point(keypoints, "right_hip")

    shoulder_center = midpoint(left_shoulder, right_shoulder)
    hip_center = midpoint(left_hip, right_hip)

    if shoulder_center is None or hip_center is None:
        return None

    dx = shoulder_center[0] - hip_center[0]
    dy = shoulder_center[1] - hip_center[1]

    if dy == 0:
        return 90.0

    return math.degrees(math.atan2(abs(dx), abs(dy)))


def knee_inward_check(keypoints):
    left_knee = point(keypoints, "left_knee")
    right_knee = point(keypoints, "right_knee")
    left_ankle = point(keypoints, "left_ankle")
    right_ankle = point(keypoints, "right_ankle")

    if left_knee is None or right_knee is None or left_ankle is None or right_ankle is None:
        return False

    knee_distance = abs(left_knee[0] - right_knee[0])
    ankle_distance = abs(left_ankle[0] - right_ankle[0])

    if ankle_distance < 40:
        return False

    return knee_distance < ankle_distance * 0.75


def calculate_score(errors):
    score = 100

    for error in errors:
        severity = error.get("severity", "low")

        if severity == "high":
            score -= 25
        elif severity == "medium":
            score -= 15
        else:
            score -= 5

    return max(score, 0)


class SquatRules:
    def __init__(self, camera_view="side"):
        self.camera_view = camera_view

    def check(self, keypoints, angles):
        errors = []

        if keypoints is None or angles is None:
            return self._result(
                errors=[{"code": "no_pose", "severity": "high"}],
                metrics={},
            )

        left_knee = angles.get("left_knee")
        right_knee = angles.get("right_knee")
        left_hip = angles.get("left_hip")
        right_hip = angles.get("right_hip")

        knee_avg = avg_valid([left_knee, right_knee])
        hip_avg = avg_valid([left_hip, right_hip])
        torso_lean = torso_lean_from_vertical(keypoints)

        if knee_avg is None:
            return self._result(
                errors=[{"code": "no_pose", "severity": "high"}],
                metrics={},
            )

        # Squat depth
        if knee_avg > 120:
            errors.append(
                {
                    "code": "squat_not_deep_enough",
                    "severity": "medium",
                }
            )

        # Torso leaning
        if torso_lean is not None and torso_lean > 45:
            errors.append(
                {
                    "code": "squat_back_leaning",
                    "severity": "medium",
                }
            )

        # Leg imbalance
        if valid_angle(left_knee) and valid_angle(right_knee):
            if abs(left_knee - right_knee) > 22:
                errors.append(
                    {
                        "code": "squat_leg_imbalance",
                        "severity": "medium",
                    }
                )

        # Knee inward is best in front view
        if self.camera_view == "front":
            if knee_inward_check(keypoints):
                errors.append(
                    {
                        "code": "squat_knee_inward",
                        "severity": "high",
                    }
                )

        return self._result(
            errors=errors,
            metrics={
                "knee_avg": knee_avg,
                "hip_avg": hip_avg,
                "torso_lean": torso_lean,
            },
        )

    def _result(self, errors, metrics):
        return {
            "exercise": "squat",
            "errors": errors,
            "metrics": metrics,
            "score": calculate_score(errors),
        }
