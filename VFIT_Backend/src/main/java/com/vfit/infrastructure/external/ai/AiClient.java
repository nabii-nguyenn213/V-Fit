package com.vfit.infrastructure.external.ai;

import java.util.Map;

public interface AiClient {
    Map<String, Object> analyzeForm(String userId, String videoUrl, Map<String, Object> metadata);

    Map<String, Object> analyzeBody(String userId, String imageUrl, Map<String, Object> metadata);

    Map<String, Object> estimateFoodCalories(String imageReference, Map<String, Object> metadata);
}
