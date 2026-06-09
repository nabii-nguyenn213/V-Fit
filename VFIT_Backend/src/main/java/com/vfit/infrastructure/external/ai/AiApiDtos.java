package com.vfit.infrastructure.external.ai;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import com.vfit.infrastructure.external.ai.dto.AiFormCheckFeedback;
import java.util.List;

/**
 * DTOs for communicating with Python AI API
 */

// ============================================================
// Form Check DTOs
// ============================================================

record FormCheckRequest(
        @JsonProperty("frame") String frame,
        @JsonProperty("exercise") String exercise,
        @JsonProperty("camera_view") String cameraView) {}

record FormCheckResponse(
        @JsonProperty("success") boolean success,
        @JsonProperty("score") int score,
        @JsonProperty("errors") List<FormErrorDto> errors,
        @JsonProperty("feedback") String feedback,
        @JsonProperty("metrics") java.util.Map<String, Object> metrics) {
    
    public AiFormCheckFeedback toAiFeedback() {
        List<FormErrorDto> safeErrors = errors == null ? List.of() : errors;
        List<AiFormCheckFeedback.FormError> formErrors = safeErrors.stream()
                .map(e -> new AiFormCheckFeedback.FormError(
                        valueOrDefault(e.code(), "FORM_CHECK"),
                        valueOrDefault(e.severity(), "WARN"),
                        valueOrDefault(e.message(), "Form check needs attention."),
                        e.landmarks() == null ? List.of() : e.landmarks()))
                .toList();
        
        List<String> affectedLandmarks = safeErrors.stream()
                .flatMap(e -> (e.landmarks() == null ? List.<String>of() : e.landmarks()).stream())
                .distinct()
                .toList();
        
        String severity = safeErrors.isEmpty() ? "OK" : valueOrDefault(safeErrors.get(0).severity(), "WARN");
        
        return new AiFormCheckFeedback(
                score,
                valueOrDefault(feedback, "No form feedback available."),
                formErrors,
                affectedLandmarks,
                valueOrDefault(feedback, "Keep moving under control."),
                severity,
                false);
    }

    private static String valueOrDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
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
        @JsonProperty("metrics") java.util.Map<String, Object> metrics,
        @JsonProperty("recommendations") List<String> recommendations) {
    
    public AiBodyAnalysisResult toAiResult() {
        // Map body type to posture assessment
        String postureDesc = determinePostureFromBodyType(bodyType);
        
        // Map imbalances
        List<String> safeImbalances = imbalances == null ? List.of() : imbalances;
        List<String> safeRecommendations = recommendations == null ? List.of() : recommendations;
        String imbalanceDesc = safeImbalances.isEmpty() ? "No significant imbalances" : safeImbalances.get(0);
        String imbalanceSeverity = safeImbalances.isEmpty() ? "OK" : "LOW";
        
        // Extract metrics (simplified)
        double bmi = extractMetric(metrics, "bmi", 22.0);
        double fatPercentage = extractMetric(metrics, "fat_percentage", 20.0);
        double symmetryScore = extractMetric(metrics, "symmetry_score", 0.85);
        
        return new AiBodyAnalysisResult(
                new AiBodyAnalysisResult.Posture(postureDesc, 85),
                new AiBodyAnalysisResult.Imbalance(imbalanceDesc, imbalanceSeverity),
                new AiBodyAnalysisResult.BodyEstimate(bmi, fatPercentage, symmetryScore),
                new AiBodyAnalysisResult.Recommendation(
                        safeRecommendations.isEmpty() ? "Continue current routine" : safeRecommendations.get(0),
                        3),
                false);
    }
    
    private String determinePostureFromBodyType(String bodyType) {
        if (bodyType == null || bodyType.isBlank()) {
            return "Body type analysis pending";
        }
        return switch (bodyType.toUpperCase()) {
            case "CHU V" -> "V-shaped upper body - well-developed shoulders";
            case "QUA LE" -> "Pear-shaped - weight distributed to lower body";
            case "CHU NHAT" -> "Rectangular shape - athletic build";
            default -> "Body type analysis pending";
        };
    }
    
    private double extractMetric(java.util.Map<String, Object> metrics, String key, double defaultValue) {
        if (metrics == null || !metrics.containsKey(key)) {
            return defaultValue;
        }
        Object value = metrics.get(key);
        if (value instanceof Number) {
            return ((Number) value).doubleValue();
        }
        return defaultValue;
    }
}
