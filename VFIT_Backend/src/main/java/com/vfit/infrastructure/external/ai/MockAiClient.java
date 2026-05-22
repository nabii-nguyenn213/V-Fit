package com.vfit.infrastructure.external.ai;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
public class MockAiClient implements AiClient {
    @Override
    @CircuitBreaker(name = "aiCore", fallbackMethod = "analyzeFormFallback")
    public Map<String, Object> analyzeForm(String userId, String videoUrl, Map<String, Object> metadata) {
        return Map.of("score", 82, "summary", "Form is stable with minor knee alignment improvements suggested.");
    }

    @Override
    @CircuitBreaker(name = "aiCore", fallbackMethod = "analyzeBodyFallback")
    public Map<String, Object> analyzeBody(String userId, String imageUrl, Map<String, Object> metadata) {
        return Map.of(
                "posture", Map.of("summary", "Neutral posture baseline", "riskScore", 18),
                "imbalance", Map.of("summary", "Minor left-right shoulder imbalance", "severity", "LOW"),
                "estimate", Map.of("bodyFatPercent", 22, "leanMassKg", 58.5, "confidence", 0.78),
                "recommendation", Map.of("focus", "mobility and recomposition", "weeklySessions", 4));
    }

    @Override
    @CircuitBreaker(name = "aiCore", fallbackMethod = "estimateFoodCaloriesFallback")
    public Map<String, Object> estimateFoodCalories(String imageReference, Map<String, Object> metadata) {
        return Map.of(
                "foodName", "Grilled chicken breast with rice",
                "servingSize", "1 plate",
                "calories", 520,
                "proteinGrams", 42.0,
                "carbGrams", 58.0,
                "fatGrams", 12.0,
                "confidence", 0.78,
                "notes", "Realtime estimate only. Portion size can change the final calories.");
    }

    public Map<String, Object> analyzeFormFallback(String userId, String videoUrl, Map<String, Object> metadata, Throwable throwable) {
        return Map.of(
                "score", 0,
                "summary", "AI Form Check is temporarily unavailable.",
                "fallback", true);
    }

    public Map<String, Object> analyzeBodyFallback(String userId, String imageUrl, Map<String, Object> metadata, Throwable throwable) {
        return Map.of(
                "posture", Map.of("summary", "Body analysis is temporarily unavailable", "riskScore", 0),
                "imbalance", Map.of("summary", "No imbalance estimate available", "severity", "UNKNOWN"),
                "estimate", Map.of("confidence", 0.0),
                "recommendation", Map.of("focus", "general fitness"),
                "fallback", true);
    }

    public Map<String, Object> estimateFoodCaloriesFallback(String imageReference, Map<String, Object> metadata, Throwable throwable) {
        return Map.of(
                "foodName", "Unknown food",
                "servingSize", "1 serving",
                "calories", 0,
                "proteinGrams", 0.0,
                "carbGrams", 0.0,
                "fatGrams", 0.0,
                "confidence", 0.0,
                "notes", "AI nutrition scan is temporarily unavailable.");
    }
}
