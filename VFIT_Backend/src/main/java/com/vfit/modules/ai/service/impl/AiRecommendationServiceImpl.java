package com.vfit.modules.ai.service.impl;

import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.modules.ai.service.AiRecommendationService;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.security.model.CustomUserDetails;
import java.time.LocalDate;
import java.time.Period;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AiRecommendationServiceImpl implements AiRecommendationService {
    private static final Set<String> ACTIVITY_LEVELS = Set.of("low", "moderate", "high");

    private final AiClient aiClient;
    private final UserRepository userRepository;

    @Override
    public Map<String, Object> askCoach(Map<String, Object> request) {
        requireText(request, "question");
        return aiClient.askCoach(copy(request));
    }

    @Override
    public Map<String, Object> createWorkoutPlan(Map<String, Object> request) {
        requireText(request, "goal");
        return aiClient.createWorkoutPlan(copy(request));
    }

    @Override
    public Map<String, Object> createMealPlan(Map<String, Object> request) {
        Map<String, Object> enrichedRequest = copy(request);
        String activityLevel = String.valueOf(enrichedRequest.getOrDefault("activity_level", "")).trim().toLowerCase();
        if (!ACTIVITY_LEVELS.contains(activityLevel)) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Activity level must be one of: low, moderate, high");
        }

        User user = currentUser();
        User.BodyMetrics metrics = user.getBodyMetrics();
        if (user.getDateOfBirth() == null
                || user.getGender() == null
                || user.getGoalType() == null
                || metrics == null
                || metrics.getWeightKg() == null
                || metrics.getHeightCm() == null) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Please complete your profile and body metrics before using AI meal planner");
        }

        enrichedRequest.put("age", age(user.getDateOfBirth()));
        enrichedRequest.put("gender", user.getGender().name().toLowerCase());
        enrichedRequest.put("weight", metrics.getWeightKg());
        enrichedRequest.put("height", metrics.getHeightCm());
        enrichedRequest.put("goal", user.getGoalType().name().toLowerCase());
        enrichedRequest.put("activity_level", activityLevel);
        enrichedRequest.remove("meals_per_day");
        return aiClient.createMealPlan(enrichedRequest);
    }

    private Map<String, Object> copy(Map<String, Object> request) {
        if (request == null || request.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "AI request payload is required");
        }
        return new LinkedHashMap<>(request);
    }

    private void requireText(Map<String, Object> request, String field) {
        Object value = request == null ? null : request.get(field);
        if (value == null || value.toString().isBlank()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Missing required AI field: " + field);
        }
    }

    private User currentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof CustomUserDetails details)) {
            throw new AppException(ErrorCode.UNAUTHORIZED, "Authentication is required");
        }
        return userRepository.findById(details.getId())
                .orElseThrow(() -> new AppException(ErrorCode.UNAUTHORIZED, "Authenticated user no longer exists"));
    }

    private int age(LocalDate dateOfBirth) {
        return Math.max(13, Period.between(dateOfBirth, LocalDate.now()).getYears());
    }
}
