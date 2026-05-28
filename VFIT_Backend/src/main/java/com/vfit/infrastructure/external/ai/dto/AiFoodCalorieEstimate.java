package com.vfit.infrastructure.external.ai.dto;

public record AiFoodCalorieEstimate(
        String foodName,
        String servingSize,
        int calories,
        double proteinGrams,
        double carbGrams,
        double fatGrams,
        double confidence,
        String notes,
        boolean fallback) {

    public static AiFoodCalorieEstimate safeFallback() {
        return new AiFoodCalorieEstimate(
                "Unknown food",
                "1 serving",
                0,
                0.0,
                0.0,
                0.0,
                0.0,
                "AI nutrition scan is temporarily unavailable.",
                true);
    }
}
