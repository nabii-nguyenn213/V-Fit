package com.vfit.infrastructure.external.ai;

import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import com.vfit.infrastructure.external.ai.dto.AiFoodCalorieEstimate;
import com.vfit.infrastructure.external.ai.dto.AiFormCheckFeedback;
import java.util.Map;

public interface AiClient {
    AiFormCheckFeedback analyzeForm(String userId, String videoUrl, Map<String, Object> metadata);

    AiBodyAnalysisResult analyzeBody(String userId, String imageUrl, Map<String, Object> metadata);

    AiFoodCalorieEstimate estimateFoodCalories(String imageReference, byte[] imageBytes, Map<String, Object> metadata);

    Map<String, Object> askCoach(Map<String, Object> request);

    Map<String, Object> createWorkoutPlan(Map<String, Object> request);

    Map<String, Object> createMealPlan(Map<String, Object> request);
}
