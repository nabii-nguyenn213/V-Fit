# ai_rep_counter/realtime_rep_counter.py

from collections import Counter, deque
from pathlib import Path

import torch
import torch.nn.functional as F

from ai_rep_counter.features import keypoints_to_feature_vector
from ai_rep_counter.phase_model import PhaseMLP


class AIRealtimeRepCounter:
    def __init__(
        self,
        model_path="ai_rep_counter/models/phase_model.pt",
        smoothing_window=7,
        min_confidence=0.55,
        device=None,
    ):
        self.model_path = Path(model_path)
        self.smoothing_window = smoothing_window
        self.min_confidence = min_confidence

        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")

        self.enabled = False
        self.model = None
        self.id_to_label = None

        self.label_history = deque(maxlen=smoothing_window)

        self.rep_counts = {
            "squat": 0,
            "pushup": 0,
        }

        self.was_down = {
            "squat": False,
            "pushup": False,
        }

        self.last_phase = {
            "squat": "unknown",
            "pushup": "unknown",
        }

        self._load_model()

    def _load_model(self):
        if not self.model_path.exists():
            print(f"[AIRepCounter] Model not found: {self.model_path}")
            print("[AIRepCounter] Rep counting disabled until model is trained.")
            return

        checkpoint = torch.load(
            self.model_path,
            map_location=self.device,
        )

        self.id_to_label = checkpoint["id_to_label"]

        self.model = PhaseMLP(
            input_size=checkpoint["input_size"],
            num_classes=checkpoint["num_classes"],
        )

        self.model.load_state_dict(checkpoint["model_state"])
        self.model.to(self.device)
        self.model.eval()

        self.enabled = True

        print(f"[AIRepCounter] Loaded model: {self.model_path}")
        print(f"[AIRepCounter] Device: {self.device}")

    def reset(self, exercise=None):
        if exercise is None:
            for key in self.rep_counts:
                self.rep_counts[key] = 0
                self.was_down[key] = False
                self.last_phase[key] = "unknown"
        else:
            self.rep_counts[exercise] = 0
            self.was_down[exercise] = False
            self.last_phase[exercise] = "unknown"

        self.label_history.clear()

    def _predict_label(self, keypoints):
        if not self.enabled:
            return "model_missing", 0.0

        features = keypoints_to_feature_vector(keypoints)

        if features is None:
            return "no_pose", 0.0

        x = torch.tensor(
            features,
            dtype=torch.float32,
        ).unsqueeze(0).to(self.device)

        with torch.no_grad():
            logits = self.model(x)
            probs = F.softmax(logits, dim=1)

            conf, pred_id = probs.max(dim=1)

        label = self.id_to_label[int(pred_id.item())]
        confidence = float(conf.item())

        return label, confidence

    def _smooth_label(self, label):
        self.label_history.append(label)

        counter = Counter(self.label_history)
        smoothed_label, _ = counter.most_common(1)[0]

        return smoothed_label

    def _label_to_phase(self, label, exercise):
        if exercise == "squat":
            if label == "squat_down":
                return "down"
            if label == "squat_up":
                return "up"
            return "other"

        if exercise == "pushup":
            if label == "pushup_down":
                return "down"
            if label == "pushup_up":
                return "up"
            return "other"

        return "other"

    def update(self, keypoints, exercise):
        label, confidence = self._predict_label(keypoints)

        if confidence < self.min_confidence:
            phase = "unknown"
        else:
            smooth_label = self._smooth_label(label)
            phase = self._label_to_phase(smooth_label, exercise)
            label = smooth_label

        if exercise not in self.rep_counts:
            return {
                "rep_count": 0,
                "phase": "unsupported",
                "label": label,
                "confidence": confidence,
                "enabled": self.enabled,
            }

        # Count a rep when the athlete goes down AND successfully stands back up.
        # This aligns with the user expectation where one full rep equals down + up.
        if phase == "down":
            self.was_down[exercise] = True

        elif phase == "up":
            if self.was_down[exercise]:
                self.rep_counts[exercise] += 1
                self.was_down[exercise] = False

        self.last_phase[exercise] = phase

        return {
            "rep_count": self.rep_counts[exercise],
            "phase": phase,
            "label": label,
            "confidence": confidence,
            "enabled": self.enabled,
        }
