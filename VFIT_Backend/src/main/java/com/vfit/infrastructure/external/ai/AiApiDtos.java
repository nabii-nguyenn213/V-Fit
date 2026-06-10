package com.vfit.infrastructure.external.ai;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import com.vfit.infrastructure.external.ai.dto.AiFormCheckFeedback;
import java.util.List;
import java.util.Map;

/**
 * DTOs for communicating with Python AI API
 */

// ============================================================
// Form Check DTOs
// ============================================================

record FormCheckRequest(
        @JsonProperty("frame") String frame,
        @JsonProperty("exercise") String exercise,
        @JsonProperty("camera_view") String cameraView,
        @JsonProperty("session_id") String sessionId) {}

record FormCheckResponse(
        @JsonProperty("success") boolean success,
        @JsonProperty("score") int score,
        @JsonProperty("errors") List<FormErrorDto> errors,
        @JsonProperty("feedback") Object feedback,
        @JsonProperty("summary") String summary,
        @JsonProperty("cue") String cue,
        @JsonProperty("severity") String severity,
        @JsonProperty("metrics") Map<String, Object> metrics,
        @JsonProperty("keypoints_count") Integer keypointsCount,
        @JsonProperty("realtime") Boolean realtime,
        @JsonProperty("frame_index") Integer frameIndex,
        @JsonProperty("rep_count") int repCount,
        @JsonProperty("phase") String phase,
        @JsonProperty("rep_phase") String repPhase,
        @JsonProperty("rep_label") String repLabel,
        @JsonProperty("rep_confidence") Double repConfidence,
        @JsonProperty("rep_counter_enabled") Boolean repCounterEnabled) {
    
    public AiFormCheckFeedback toAiFeedback() {
        List<FormErrorDto> safeErrors = errors == null ? List.of() : errors;
        FeedbackPayload feedbackPayload = parseFeedback(feedback);
        List<AiFormCheckFeedback.FormError> formErrors = safeErrors.stream()
                .map(e -> new AiFormCheckFeedback.FormError(
                        valueOrDefault(e.code(), "FORM_CHECK"),
                        normalizeSeverity(e.severity()),
                        valueOrDefault(e.message(), feedbackPayload.summary()),
                        e.landmarks() == null ? List.of() : e.landmarks()))
                .toList();
        
                List<String> affectedLandmarks = safeErrors.stream()
                .flatMap(e -> (e.landmarks() == null ? List.<String>of() : e.landmarks()).stream())
                .distinct()
                .toList();
        
        String feedbackSeverity = valueOrDefault(
                severity,
                safeErrors.isEmpty() ? "OK" : normalizeSeverity(safeErrors.get(0).severity()));
        String feedbackSummary = valueOrDefault(summary, feedbackPayload.summary());
        String feedbackCue = valueOrDefault(cue, feedbackPayload.cue());
        
        return new AiFormCheckFeedback(
                score,
                feedbackSummary,
                formErrors,
                affectedLandmarks,
                feedbackCue,
                normalizeSeverity(feedbackSeverity),
                false,
                repCount,
                valueOrDefault(valueOrDefault(phase, repPhase), "unknown"),
                valueOrDefault(repLabel, "unknown"),
                repConfidence == null ? 0.0 : repConfidence,
                Boolean.TRUE.equals(repCounterEnabled),
                feedback == null ? List.of() : feedback,
                metrics == null ? Map.of() : metrics,
                keypointsCount == null ? 0 : keypointsCount,
                !Boolean.FALSE.equals(realtime),
                frameIndex == null ? 0 : frameIndex);
    }

    private static String valueOrDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    private static FeedbackPayload parseFeedback(Object feedback) {
        if (feedback instanceof String value && !value.isBlank()) {
            return new FeedbackPayload(value, value);
        }
        if (feedback instanceof List<?> values && !values.isEmpty()) {
            Object first = values.get(0);
            if (first instanceof Map<?, ?> map) {
                String warning = stringValue(map.get("warning"));
                String correction = stringValue(map.get("correction"));
                return new FeedbackPayload(
                        valueOrDefault(warning, "Form check needs attention."),
                        valueOrDefault(correction, "Keep moving under control."));
            }
        }
        return new FeedbackPayload("No form feedback available.", "Keep moving under control.");
    }

    private static String stringValue(Object value) {
        return value == null ? null : value.toString();
    }

    private static String normalizeSeverity(String value) {
        if (value == null || value.isBlank()) {
            return "WARN";
        }
        return switch (value.toLowerCase()) {
            case "high", "error" -> "ERROR";
            case "medium", "low", "warn", "warning" -> "WARN";
            case "ok", "info" -> value.toUpperCase();
            default -> "WARN";
        };
    }

    private record FeedbackPayload(String summary, String cue) {}
}

record FormErrorDto(
        @JsonProperty("code") String code,
        @JsonProperty("severity") String severity,
        @JsonProperty("message") String message,
        @JsonProperty("landmarks") List<String> landmarks) {}

// ============================================================
// Body Analysis DTOs
// ============================================================

record BodyAnalysisRequest(
        @JsonProperty("frame") String frame) {}

record BodyAnalysisResponse(
        @JsonProperty("success") boolean success,
        @JsonProperty("body_type") String bodyType,
        @JsonProperty("body_description") String bodyDescription,
        @JsonProperty("imbalances") List<String> imbalances,
        @JsonProperty("metrics") Map<String, Object> metrics,
        @JsonProperty("recommendations") List<String> recommendations) {
    
    public AiBodyAnalysisResult toAiResult() {
        String postureDesc = valueOrDefault(bodyType, "Body type analysis pending");
        if (bodyDescription != null && !bodyDescription.isBlank()) {
            postureDesc = postureDesc + " - " + bodyDescription;
        }
        
        List<String> safeImbalances = imbalances == null ? List.of() : imbalances;
        List<String> safeRecommendations = recommendations == null ? List.of() : recommendations;
        String imbalanceDesc = safeImbalances.isEmpty() ? "No significant imbalances" : safeImbalances.get(0);
        String imbalanceSeverity = safeImbalances.isEmpty() ? "OK" : "LOW";
        
        Double waistShoulderRatio = extractMetric(metrics, "fat_ratio");
        double confidence = waistShoulderRatio == null ? 0.0 : 0.85;
        
        return new AiBodyAnalysisResult(
                new AiBodyAnalysisResult.Posture(postureDesc, 15),
                new AiBodyAnalysisResult.Imbalance(imbalanceDesc, imbalanceSeverity),
                new AiBodyAnalysisResult.BodyEstimate(null, null, confidence, waistShoulderRatio),
                new AiBodyAnalysisResult.Recommendation(
                        safeRecommendations.isEmpty() ? "Continue current routine" : safeRecommendations.get(0),
                        3),
                false);
    }

    private static String valueOrDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    private Double extractMetric(Map<String, Object> metrics, String key) {
        if (metrics == null || !metrics.containsKey(key)) {
            return null;
        }
        Object value = metrics.get(key);
        if (value instanceof Number) {
            return ((Number) value).doubleValue();
        }
        return null;
    }
}
