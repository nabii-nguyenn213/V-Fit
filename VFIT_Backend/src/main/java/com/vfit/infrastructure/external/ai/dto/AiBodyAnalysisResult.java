package com.vfit.infrastructure.external.ai.dto;

public record AiBodyAnalysisResult(
        Posture posture,
        Imbalance imbalance,
        BodyEstimate estimate,
        Recommendation recommendation,
        boolean fallback) {

    public record Posture(String summary, int riskScore) {
    }

    public record Imbalance(String summary, String severity) {
    }

    public record BodyEstimate(Double bodyFatPercent, Double leanMassKg, double confidence) {
    }

    public record Recommendation(String focus, int weeklySessions) {
    }

    public static AiBodyAnalysisResult safeFallback() {
        return new AiBodyAnalysisResult(
                new Posture("Body analysis is temporarily unavailable.", 0),
                new Imbalance("No imbalance estimate available.", "UNKNOWN"),
                new BodyEstimate(null, null, 0.0),
                new Recommendation("general fitness", 3),
                true);
    }
}
