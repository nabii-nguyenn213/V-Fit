from shared.angle_calculator import calculate_body_angles
from form_check.feedback_generator import generate_feedback
from form_check.rules.squat_rules import SquatRules
from form_check.rules.pushup_rules import PushupRules


class FormChecker:
    def __init__(self, exercise="squat", camera_view="side"):
        self.exercise = exercise
        self.camera_view = camera_view
        self.rule_checker = self._create_rule_checker()

    def _create_rule_checker(self):
        if self.exercise == "squat":
            return SquatRules(camera_view=self.camera_view)

        if self.exercise == "pushup":
            return PushupRules(camera_view=self.camera_view)

        raise ValueError(f"Unsupported exercise: {self.exercise}")

    def set_exercise(self, exercise):
        self.exercise = exercise
        self.rule_checker = self._create_rule_checker()

    def set_camera_view(self, camera_view):
        self.camera_view = camera_view
        self.rule_checker = self._create_rule_checker()

    def check(self, keypoints, angles=None):
        if keypoints is None:
            result = {
                "exercise": self.exercise,
                "errors": [{"code": "no_pose", "severity": "high"}],
                "metrics": {},
                "score": 0,
            }
            result["feedback"] = generate_feedback(result["errors"])
            return result

        if angles is None:
            angles = calculate_body_angles(keypoints)

        result = self.rule_checker.check(keypoints, angles)
        result["feedback"] = generate_feedback(result.get("errors", []))

        return result
