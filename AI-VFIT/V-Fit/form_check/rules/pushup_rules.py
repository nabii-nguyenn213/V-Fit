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


def distance_point_to_line(p, a, b):
    if p is None or a is None or b is None:
        return None

    px, py = p
    ax, ay = a
    bx, by = b

    line_len = math.sqrt((bx - ax) ** 2 + (by - ay) ** 2)

    if line_len == 0:
        return None

    return abs((by - ay) * px - (bx - ax) * py + bx * ay - by * ax) / line_len


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


class PushupRules:
    def __init__(self, camera_view="side"):
        self.camera_view = camera_view

    def check(self, keypoints, angles):
        errors = []

        if keypoints is None or angles is None:
            return self._result(
                errors=[{"code": "no_pose", "severity": "high"}],
                metrics={},
            )

        left_elbow = angles.get("left_elbow")
        right_elbow = angles.get("right_elbow")
        elbow_avg = avg_valid([left_elbow, right_elbow])

        left_shoulder = point(keypoints, "left_shoulder")
        right_shoulder = point(keypoints, "right_shoulder")
        left_hip = point(keypoints, "left_hip")
        right_hip = point(keypoints, "right_hip")
        left_ankle = point(keypoints, "left_ankle")
        right_ankle = point(keypoints, "right_ankle")

        shoulder = left_shoulder or right_shoulder
        hip = left_hip or right_hip
        ankle = left_ankle or right_ankle

        if elbow_avg is None:
            return self._result(
                errors=[{"code": "no_pose", "severity": "high"}],
                metrics={},
            )

        # Push-up depth
        if elbow_avg > 110:
            errors.append(
                {
                    "code": "pushup_not_low_enough",
                    "severity": "medium",
                }
            )

        # Body alignment: shoulder - hip - ankle should be almost straight
        hip_line_distance = distance_point_to_line(
            hip,
            shoulder,
            ankle,
        )

        if hip_line_distance is not None:
            if hip_line_distance > 45:
                # Since image y-axis increases downward:
                # if hip is below line => sagging, if above line => hip too high
                errors.append(
                    {
                        "code": "pushup_hip_sag",
                        "severity": "high",
                    }
                )

        # Elbow flare approximation
        left_shoulder_angle = angles.get("left_shoulder")
        right_shoulder_angle = angles.get("right_shoulder")
        shoulder_avg = avg_valid([left_shoulder_angle, right_shoulder_angle])

        if shoulder_avg is not None and shoulder_avg > 150:
            errors.append(
                {
                    "code": "pushup_elbow_flare",
                    "severity": "medium",
                }
            )

        return self._result(
            errors=errors,
            metrics={
                "elbow_avg": elbow_avg,
                "hip_line_distance": hip_line_distance,
                "shoulder_avg": shoulder_avg,
            },
        )

    def _result(self, errors, metrics):
        return {
            "exercise": "pushup",
            "errors": errors,
            "metrics": metrics,
            "score": calculate_score(errors),
        }
