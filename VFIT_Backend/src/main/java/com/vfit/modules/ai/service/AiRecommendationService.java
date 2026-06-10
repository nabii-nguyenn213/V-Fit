package com.vfit.modules.ai.service;

import java.util.Map;

public interface AiRecommendationService {
    Map<String, Object> askCoach(Map<String, Object> request);

    Map<String, Object> createWorkoutPlan(Map<String, Object> request);

    Map<String, Object> createMealPlan(Map<String, Object> request);
}
