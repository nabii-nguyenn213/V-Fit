# form_check/feedback_stabilizer.py

import time


class FeedbackStabilizer:
    """
    Stabilize form feedback so warning text does not change every frame.

    Logic:
    - A new error must appear for several continuous frames before it is shown.
    - Once shown, it is kept on screen for a short time so the user can read it.
    """

    def __init__(
        self,
        stable_frames=8,
        hold_seconds=2.0,
    ):
        self.stable_frames = stable_frames
        self.hold_seconds = hold_seconds

        self.candidate_code = None
        self.candidate_count = 0

        self.current_feedback = None
        self.last_update_time = 0.0

    def reset(self):
        self.candidate_code = None
        self.candidate_count = 0
        self.current_feedback = None
        self.last_update_time = 0.0

    def update(self, feedback):
        """
        Args:
            feedback: dict or None

        Returns:
            stable feedback dict or None
        """

        now = time.time()

        # No current raw error
        if feedback is None:
            # Keep old feedback for a short time
            if self.current_feedback is not None:
                if now - self.last_update_time < self.hold_seconds:
                    return self.current_feedback

            self.candidate_code = None
            self.candidate_count = 0
            self.current_feedback = None
            return None

        code = feedback.get("code", "unknown")

        # Same candidate error appears repeatedly
        if code == self.candidate_code:
            self.candidate_count += 1
        else:
            self.candidate_code = code
            self.candidate_count = 1

        # Only update displayed feedback if the new error is stable
        if self.candidate_count >= self.stable_frames:
            self.current_feedback = feedback
            self.last_update_time = now

        return self.current_feedback
