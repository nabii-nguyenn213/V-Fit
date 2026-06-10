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
        try {
            // Extract frame data from request
            // In real-time WebSocket, frame comes as part of the message
            byte[] frameBytes = frameBytes(metadata);
            String exercise = (String) metadata.getOrDefault("exercise", "squat");
            String cameraView = (String) metadata.getOrDefault("cameraView", "side");
            String sessionId = (String) metadata.getOrDefault("sessionId", userId);
            
            if (frameBytes == null || frameBytes.length == 0) {
                return AiFormCheckFeedback.safeFallback();
            }
            
            // Convert bytes to base64 for sending to Python API
            String frameBase64 = java.util.Base64.getEncoder().encodeToString(frameBytes);
            
            // Call Python AI API
            FormCheckRequest apiRequest = new FormCheckRequest(frameBase64, exercise, cameraView, sessionId);
            FormCheckResponse response = restClient.post()
                    .uri(aiProperties.getBaseUrl() + "/api/ai/form-check")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(apiRequest)
                    .retrieve()
                    .body(FormCheckResponse.class);
            
            if (response == null || !response.success()) {
                return AiFormCheckFeedback.safeFallback();
            }
            
            return response.toAiFeedback();
        } catch (RestClientException e) {
            log.warn("AI form check request failed: {}", e.getMessage());
            throw e;
        }
    }

    @Override
    @CircuitBreaker(name = "aiCore", fallbackMethod = "analyzeBodyFallback")
    public AiBodyAnalysisResult analyzeBody(String userId, String imageUrl, Map<String, Object> metadata) {
        try {
            // Extract frame data
            byte[] frameBytes = frameBytes(metadata);
            
            if (frameBytes == null || frameBytes.length == 0) {
                return AiBodyAnalysisResult.safeFallback();
            }
            
            // Convert bytes to base64
            String frameBase64 = java.util.Base64.getEncoder().encodeToString(frameBytes);
            
            // Call Python AI API
            BodyAnalysisRequest apiRequest = new BodyAnalysisRequest(frameBase64);
            BodyAnalysisResponse response = restClient.post()
                    .uri(aiProperties.getBaseUrl() + "/api/ai/body-analysis")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(apiRequest)
                    .retrieve()
                    .body(BodyAnalysisResponse.class);
            
            if (response == null || !response.success()) {
                return AiBodyAnalysisResult.safeFallback();
            }
            
            return response.toAiResult();
        } catch (RestClientException e) {
            log.warn("AI body analysis request failed: {}", e.getMessage());
            throw e;
        }
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

    private byte[] frameBytes(Map<String, Object> metadata) {
        Object value = metadata.get("frameBytes");
        if (value instanceof byte[] bytes) {
            return bytes;
        }
        log.warn("AI frame payload has invalid type: {}", value == null ? "null" : value.getClass().getSimpleName());
        return new byte[0];
    }
}
