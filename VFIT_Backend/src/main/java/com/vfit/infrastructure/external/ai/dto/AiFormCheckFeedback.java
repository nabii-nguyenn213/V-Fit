package com.vfit.infrastructure.external.ai.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;
import java.util.Map;

public record AiFormCheckFeedback(
        int score,
        String summary,
        @JsonProperty("errors")
        List<FormError> formErrors,
        @JsonProperty("affected_joints")
        List<String> affectedJoints,
        String cue,
        String severity,
        boolean fallback,
        @JsonProperty("rep_count") int repCount,
        String phase,
        @JsonProperty("rep_label") String repLabel,
        @JsonProperty("rep_confidence") double repConfidence,
        @JsonProperty("rep_counter_enabled") boolean repCounterEnabled,
        @JsonProperty("feedback_details") Object feedbackDetails,
        Map<String, Object> metrics,
        @JsonProperty("keypoints_count") int keypointsCount,
        boolean realtime,
        @JsonProperty("frame_index") int frameIndex) {

    public record FormError(
            String code,
            String severity,
            String message,
            @JsonProperty("affected_joints") List<String> affectedJoints) {
    }

    public static AiFormCheckFeedback safeFallback() {
        return new AiFormCheckFeedback(
                0,
                "AI Form Check is temporarily unavailable.",
                List.of(),
                List.of(),
                "Pause and retry when the camera view is clear.",
                "UNKNOWN",
                true,
                0,
                "unknown",
                "unknown",
                0.0,
                false,
                List.of(),
                Map.of(),
                0,
                true,
                0);
    }
}
