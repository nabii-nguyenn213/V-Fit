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
        List<AiFormCheckFeedback.FormError> formErrors = errors.stream()
                .map(e -> new AiFormCheckFeedback.FormError(
                        e.code,
                        e.severity,
                        e.message,
                        e.landmarks))
                .toList();
        
        List<String> affectedLandmarks = errors.stream()
                .flatMap(e -> e.landmarks.stream())
                .distinct()
                .toList();
        
        String severity = errors.isEmpty() ? "OK" : errors.get(0).severity;
        
        return new AiFormCheckFeedback(
                score,
                feedback,
                formErrors,
                affectedLandmarks,
                feedback,
                severity,
                false);
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
        String imbalanceDesc = imbalances.isEmpty() ? "No significant imbalances" : imbalances.get(0);
        String imbalanceSeverity = imbalances.isEmpty() ? "OK" : "LOW";
        
        // Extract metrics (simplified)
        double bmi = extractMetric(metrics, "bmi", 22.0);
        double fatPercentage = extractMetric(metrics, "fat_percentage", 20.0);
        double symmetryScore = extractMetric(metrics, "symmetry_score", 0.85);
        
        return new AiBodyAnalysisResult(
                new AiBodyAnalysisResult.Posture(postureDesc, 85),
                new AiBodyAnalysisResult.Imbalance(imbalanceDesc, imbalanceSeverity),
                new AiBodyAnalysisResult.BodyEstimate(bmi, fatPercentage, symmetryScore),
                new AiBodyAnalysisResult.Recommendation(
                        recommendations.isEmpty() ? "Continue current routine" : recommendations.get(0),
                        3),
                false);
    }
    
    private String determinePostureFromBodyType(String bodyType) {
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
