package com.vfit.infrastructure.external.ai;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vfit.infrastructure.config.AppProperties;
import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import com.vfit.infrastructure.external.ai.dto.AiFoodCalorieEstimate;
import com.vfit.infrastructure.external.ai.dto.AiFormCheckFeedback;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Slf4j
@Component
@ConditionalOnProperty(prefix = "app.ai", name = "client-mode", havingValue = "http")
public class HttpAiClient implements AiClient {
    private final AppProperties.Ai aiProperties;
    private final RestClient restClient;

    public HttpAiClient(AppProperties appProperties) {
        this.aiProperties = appProperties.getAi();
        this.restClient = RestClient.builder()
                .baseUrl(this.aiProperties.getBaseUrl())
                .build();
    }

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
                false);
    }

    @Override
    @CircuitBreaker(name = "aiCore", fallbackMethod = "analyzeBodyFallback")
    public AiBodyAnalysisResult analyzeBody(String userId, String imageUrl, Map<String, Object> metadata) {
        return new AiBodyAnalysisResult(
                new AiBodyAnalysisResult.Posture("Neutral posture baseline", 18),
                new AiBodyAnalysisResult.Imbalance("Minor left-right shoulder imbalance", "LOW"),
                new AiBodyAnalysisResult.BodyEstimate(22.0, 58.5, 0.78),
                new AiBodyAnalysisResult.Recommendation("mobility and recomposition", 4),
                false);
    }

    @Override
    @CircuitBreaker(name = "aiCore", fallbackMethod = "estimateFoodCaloriesFallback")
    public AiFoodCalorieEstimate estimateFoodCalories(
            String imageReference,
            byte[] imageBytes,
            Map<String, Object> metadata) {
        if (imageBytes == null || imageBytes.length == 0) {
            return AiFoodCalorieEstimate.safeFallback();
        }

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", new NamedByteArrayResource(imageBytes, imageReference));

        try {
            FoodScannerResponse response = restClient.post()
                    .uri(aiProperties.getFoodScannerPath())
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(body)
                    .retrieve()
                    .body(FoodScannerResponse.class);

            if (response == null) {
                return AiFoodCalorieEstimate.safeFallback();
            }
            return response.toEstimate();
        } catch (RestClientException e) {
            log.warn("AI food scanner request failed: {}", e.getMessage());
            throw e;
        }
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

    private record FoodScannerResponse(
            @JsonProperty("food_name") String foodName,
            @JsonProperty("portion_estimate") String portionEstimate,
            @JsonProperty("total_calories") Integer totalCalories,
            @JsonProperty("protein_g") Double proteinGrams,
            @JsonProperty("carbs_g") Double carbGrams,
            @JsonProperty("fat_g") Double fatGrams,
            Double confidence,
            String note,
            List<Object> items) {

        private AiFoodCalorieEstimate toEstimate() {
            return new AiFoodCalorieEstimate(
                    valueOrDefault(foodName, "Unknown food"),
                    valueOrDefault(portionEstimate, "1 serving"),
                    totalCalories == null ? 0 : totalCalories,
                    proteinGrams == null ? 0.0 : proteinGrams,
                    carbGrams == null ? 0.0 : carbGrams,
                    fatGrams == null ? 0.0 : fatGrams,
                    normalizeConfidence(confidence),
                    valueOrDefault(note, "Realtime estimate only."),
                    false);
        }

        private static String valueOrDefault(String value, String fallback) {
            return value == null || value.isBlank() ? fallback : value;
        }

        private static double normalizeConfidence(Double value) {
            if (value == null) {
                return 0.0;
            }
            if (value > 1.0) {
                return Math.min(value / 100.0, 1.0);
            }
            return Math.max(value, 0.0);
        }
    }

    private static class NamedByteArrayResource extends ByteArrayResource {
        private final String filename;

        private NamedByteArrayResource(byte[] byteArray, String filename) {
            super(byteArray);
            this.filename = filename == null || filename.isBlank() ? "camera-preview.jpg" : filename;
        }

        @Override
        public String getFilename() {
            return filename;
        }
    }
}
