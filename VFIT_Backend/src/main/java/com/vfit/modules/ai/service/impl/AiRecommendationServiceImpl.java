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
        enrichedRequest.put("activity_level", activityLevel);
        enrichedRequest.remove("meals_per_day");

        // Required profile fields for AI model (gender, weight, height, goal). Age is optional.
        boolean hasRequiredProfile = enrichedRequest.containsKey("gender")
                && enrichedRequest.containsKey("weight")
                && enrichedRequest.containsKey("height")
                && enrichedRequest.containsKey("goal");
        if (!hasRequiredProfile) {
            // Enrich missing fields from the authenticated user profile (if any)
            User user = currentUser();
            User.BodyMetrics metrics = user.getBodyMetrics();

            // Gender
            if (!enrichedRequest.containsKey("gender") && user.getGender() != null) {
                enrichedRequest.put("gender", user.getGender().name().toLowerCase());
            }
            // Weight
            if (!enrichedRequest.containsKey("weight") && metrics != null && metrics.getWeightKg() != null) {
                enrichedRequest.put("weight", metrics.getWeightKg());
            }
            // Height
            if (!enrichedRequest.containsKey("height") && metrics != null && metrics.getHeightCm() != null) {
                enrichedRequest.put("height", metrics.getHeightCm());
            }
            // Goal
            if (!enrichedRequest.containsKey("goal") && user.getGoalType() != null) {
                enrichedRequest.put("goal", user.getGoalType().name().toLowerCase());
            }
            // Age (optional) – add if DOB exists
            if (!enrichedRequest.containsKey("age") && user.getDateOfBirth() != null) {
                enrichedRequest.put("age", age(user.getDateOfBirth()));
            }
            // Body fat percent (optional)
            if (!enrichedRequest.containsKey("body_fat_percent") && metrics != null && metrics.getBodyFatPercent() != null) {
                enrichedRequest.put("body_fat_percent", metrics.getBodyFatPercent());
            }

            // After enrichment, verify required fields are now present
            if (!enrichedRequest.containsKey("gender")
                    || !enrichedRequest.containsKey("weight")
                    || !enrichedRequest.containsKey("height")
                    || !enrichedRequest.containsKey("goal")) {
                throw new AppException(ErrorCode.BAD_REQUEST,
                        "Please complete your profile (gender, weight, height, goal) before using AI meal planner");
            }
        }

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
