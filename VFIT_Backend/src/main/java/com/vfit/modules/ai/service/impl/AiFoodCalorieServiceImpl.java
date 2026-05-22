package com.vfit.modules.ai.service.impl;

import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.modules.ai.dto.response.FoodCalorieEstimateResponse;
import com.vfit.modules.ai.service.AiFoodCalorieService;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class AiFoodCalorieServiceImpl implements AiFoodCalorieService {
    private final AiClient aiClient;

    @Override
    public FoodCalorieEstimateResponse estimate(MultipartFile image) {
        String fileName = image == null || image.getOriginalFilename() == null
                ? "camera-preview"
                : image.getOriginalFilename();
        String contentType = image == null || image.getContentType() == null
                ? "unknown"
                : image.getContentType();
        Map<String, Object> metadata = Map.of(
                "source", "camera",
                "fileName", fileName,
                "contentType", contentType,
                "sizeBytes", image == null ? 0L : image.getSize());

        Map<String, Object> result = aiClient.estimateFoodCalories("realtime-camera-frame", metadata);

        return FoodCalorieEstimateResponse.builder()
                .foodName(text(result.get("foodName"), "Unknown food"))
                .servingSize(text(result.get("servingSize"), "1 serving"))
                .calories(number(result.get("calories")).intValue())
                .proteinGrams(number(result.get("proteinGrams")).doubleValue())
                .carbGrams(number(result.get("carbGrams")).doubleValue())
                .fatGrams(number(result.get("fatGrams")).doubleValue())
                .confidence(number(result.get("confidence")).doubleValue())
                .notes(List.of(text(result.get("notes"), "Realtime estimate only.")))
                .estimatedAt(Instant.now())
                .build();
    }

    private String text(Object value, String fallback) {
        if (value == null) {
            return fallback;
        }
        return value.toString();
    }

    private Number number(Object value) {
        if (value instanceof Number number) {
            return number;
        }
        return 0;
    }
}
