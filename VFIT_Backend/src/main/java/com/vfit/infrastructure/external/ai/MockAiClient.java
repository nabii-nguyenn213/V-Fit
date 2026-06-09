package com.vfit.infrastructure.external.ai;

import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import com.vfit.infrastructure.external.ai.dto.AiFoodCalorieEstimate;
import com.vfit.infrastructure.external.ai.dto.AiFormCheckFeedback;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import java.util.List;
import java.util.Map;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(prefix = "app.ai", name = "client-mode", havingValue = "mock", matchIfMissing = true)
public class MockAiClient implements AiClient {
    @Override
    @CircuitBreaker(name = "aiCore", fallbackMethod = "analyzeFormFallback")
    public AiFormCheckFeedback analyzeForm(String userId, String videoUrl, Map<String, Object> metadata) {
        return new AiFormCheckFeedback(
                82,
                "Form is stable with minor knee alignment improvements suggested.",
                List.of(new AiFormCheckFeedback.FormError(
                        "KNEE_ALIGNMENT",
                        "WARN",
                        "Keep knees aligned with toes.",
                        List.of("left_knee", "right_knee"))),
                List.of("left_knee", "right_knee"),
                "Keep knees tracking over toes.",
                "WARN",
                false,
                3);
    }

    @Override
    @CircuitBreaker(name = "aiCore", fallbackMethod = "analyzeBodyFallback")
    public AiBodyAnalysisResult analyzeBody(String userId, String imageUrl, Map<String, Object> metadata) {
        return new AiBodyAnalysisResult(
                new AiBodyAnalysisResult.Posture("Neutral posture baseline", 18),
                new AiBodyAnalysisResult.Imbalance("Minor left-right shoulder imbalance", "LOW"),
                new AiBodyAnalysisResult.BodyEstimate(22.0, 58.5, 0.78, null),
                new AiBodyAnalysisResult.Recommendation("mobility and recomposition", 4),
                false);
    }

    @Override
    @CircuitBreaker(name = "aiCore", fallbackMethod = "estimateFoodCaloriesFallback")
    public AiFoodCalorieEstimate estimateFoodCalories(
            String imageReference,
            byte[] imageBytes,
            Map<String, Object> metadata) {
        return new AiFoodCalorieEstimate(
                "Grilled chicken breast with rice",
                "1 plate",
                520,
                42.0,
                58.0,
                12.0,
                0.78,
                "Realtime estimate only. Portion size can change the final calories.",
                false);
    }

    public AiFormCheckFeedback analyzeFormFallback(
            String userId,
            String videoUrl,
            Map<String, Object> metadata,
            Throwable throwable) {
        return AiFormCheckFeedback.safeFallback();
    }

    public AiBodyAnalysisResult analyzeBodyFallback(
            String userId,
            String imageUrl,
            Map<String, Object> metadata,
            Throwable throwable) {
        return AiBodyAnalysisResult.safeFallback();
    }

    public AiFoodCalorieEstimate estimateFoodCaloriesFallback(
            String imageReference,
            byte[] imageBytes,
            Map<String, Object> metadata,
            Throwable throwable) {
        return AiFoodCalorieEstimate.safeFallback();
    }
}
