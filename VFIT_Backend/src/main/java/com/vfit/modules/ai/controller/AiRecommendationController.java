package com.vfit.modules.ai.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.ai.service.AiRecommendationService;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
@Slf4j
public class AiRecommendationController {
    private final AiRecommendationService aiRecommendationService;

    @PostMapping("/coach")
    @PreAuthorize("@featureGate.isPremium(authentication)")
    public ApiResponse<Map<String, Object>> askCoach(@RequestBody Map<String, Object> request) {
        log.info("[AI RECOMMENDATION] Coach request received");
        return ApiResponse.ok(aiRecommendationService.askCoach(request));
    }

    @PostMapping("/workout-planner")
    @PreAuthorize("@featureGate.isPremium(authentication)")
    public ApiResponse<Map<String, Object>> createWorkoutPlan(@RequestBody Map<String, Object> request) {
        log.info("[AI RECOMMENDATION] Workout planner request received");
        return ApiResponse.ok(aiRecommendationService.createWorkoutPlan(request));
    }

    @PostMapping("/meal-planner")
    public ApiResponse<Map<String, Object>> createMealPlan(@RequestBody Map<String, Object> request) {
        log.info("[AI RECOMMENDATION] Meal planner request received");
        return ApiResponse.ok(aiRecommendationService.createMealPlan(request));
    }
}
