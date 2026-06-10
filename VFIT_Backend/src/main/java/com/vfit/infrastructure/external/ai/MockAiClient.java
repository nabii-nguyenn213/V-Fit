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
                3,
                "down",
                "squat_down",
                0.86,
                true,
                List.of(Map.of(
                        "code", "knee_alignment",
                        "warning", "Keep knees aligned with toes.",
                        "correction", "Track knees over toes.")),
                Map.of("knee_angle", 88, "hip_angle", 74),
                33,
                true,
                12);
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

    @Override
    public Map<String, Object> askCoach(Map<String, Object> request) {
        return Map.of(
                "answer",
                "Hãy bắt đầu bằng 5-10 phút khởi động, chọn mức tạ vừa sức và ưu tiên kỹ thuật ổn định trước khi tăng cường độ.",
                "fallback",
                false);
    }

    @Override
    public Map<String, Object> createWorkoutPlan(Map<String, Object> request) {
        return Map.of(
                "plan_name",
                "Lịch tập AI mẫu",
                "goal",
                request.getOrDefault("goal", "general fitness"),
                "days_per_week",
                request.getOrDefault("days_per_week", 4),
                "weekly_schedule",
                Map.of(
                        "day_1",
                        Map.of(
                                "focus",
                                "Full body strength",
                                "warm_up",
                                List.of("Đi bộ nhanh 5 phút", "Xoay khớp vai/hông"),
                                "main_workout",
                                List.of("Squat 3x10", "Push-up 3x8", "Row 3x10"),
                                "cool_down",
                                List.of("Giãn cơ đùi", "Thở chậm 2 phút"))),
                "note",
                "Mock plan for local development.",
                "fallback",
                false);
    }

    @Override
    public Map<String, Object> createMealPlan(Map<String, Object> request) {
        return Map.of(
                "daily_calories",
                2200,
                "protein_g",
                140,
                "carbs_g",
                240,
                "fat_g",
                65,
                "meal_plan",
                Map.of(
                        "breakfast",
                        List.of("Yến mạch, sữa chua, chuối"),
                        "lunch",
                        List.of("Cơm gạo lứt, ức gà, rau xanh"),
                        "dinner",
                        List.of("Cá hồi, khoai lang, salad"),
                        "snack",
                        List.of("Whey hoặc trứng luộc")),
                "note",
                "Mock meal plan for local development.",
                "fallback",
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
