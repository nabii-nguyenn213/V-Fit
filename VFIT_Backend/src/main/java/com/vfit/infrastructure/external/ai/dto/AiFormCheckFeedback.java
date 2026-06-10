package com.vfit.infrastructure.external.ai.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record AiFormCheckFeedback(
        int score,
        String summary,
        List<FormError> formErrors,
        List<String> affectedJoints,
        String cue,
        String severity,
        boolean fallback,
        @JsonProperty("rep_count") int repCount,
        String phase,
        @JsonProperty("rep_label") String repLabel,
        @JsonProperty("rep_confidence") double repConfidence,
        @JsonProperty("rep_counter_enabled") boolean repCounterEnabled) {

    public record FormError(String code, String severity, String message, List<String> affectedJoints) {
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
                false);
    }
}
