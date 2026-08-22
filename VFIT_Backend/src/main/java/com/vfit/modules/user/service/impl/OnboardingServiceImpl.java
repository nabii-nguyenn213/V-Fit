package com.vfit.modules.user.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vfit.common.enums.GoalType;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.common.exception.ResourceNotFoundException;
import com.vfit.common.util.SecurityUtil;
import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import com.vfit.modules.ai.document.BodyAnalysisResult;
import com.vfit.modules.ai.mapper.AiResultMapper;
import com.vfit.modules.ai.repository.BodyAnalysisRepository;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.request.OnboardingMetricsRequest;
import com.vfit.modules.user.dto.request.OnboardingProfileRequest;
import com.vfit.modules.user.dto.response.OnboardingResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.OnboardingService;
import java.io.IOException;
import java.time.Instant;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class OnboardingServiceImpl implements OnboardingService {
    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final AiClient aiClient;
    private final BodyAnalysisRepository bodyAnalysisRepository;
    private final AiResultMapper aiResultMapper;
    private final ObjectMapper objectMapper;

    @Override
    public UserResponse updatePhysicalProfile(OnboardingProfileRequest request) {
        User user = currentUser();
        User.BodyMetrics metrics = user.getBodyMetrics() == null ? new User.BodyMetrics() : user.getBodyMetrics();
        metrics.setHeightCm(request.getHeightCm());
        metrics.setWeightKg(request.getWeightKg());
        metrics.setBodyFatPercent(request.getBodyFatPercent());
        metrics.setBmi(calculateBmi(request.getHeightCm(), request.getWeightKg()));
        metrics.setMeasuredAt(Instant.now());
        user.setBodyMetrics(metrics);
        return userMapper.toResponse(userRepository.save(user));
    }

    @Override
    @CacheEvict(value = "personalized_workouts", key = "T(com.vfit.common.util.SecurityUtil).requireCurrentUserId()")
    public UserResponse updateOnboardingMetrics(OnboardingMetricsRequest request) {
        User user = currentUser();
        user.setGoalType(request.getGoalType());

        User.BodyMetrics metrics = user.getBodyMetrics() == null ? new User.BodyMetrics() : user.getBodyMetrics();
        if (request.getHeightCm() != null) {
            metrics.setHeightCm(request.getHeightCm());
        }
        if (request.getWeightKg() != null) {
            metrics.setWeightKg(request.getWeightKg());
        }
        if (request.getBodyFatPercent() != null) {
            metrics.setBodyFatPercent(request.getBodyFatPercent());
        }
        if (metrics.getHeightCm() != null && metrics.getWeightKg() != null) {
            metrics.setBmi(calculateBmi(metrics.getHeightCm(), metrics.getWeightKg()));
        }
        metrics.setMeasuredAt(Instant.now());
        user.setBodyMetrics(metrics);

        user.setOnboardingStatus(OnboardingStatus.COMPLETED);
        user.setActive(true);

        return userMapper.toResponse(userRepository.save(user));
    }

    @Override
    public OnboardingResponse completeBodyScan(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Body scan image or video is required");
        }

        User user = currentUser();
        User.BodyMetrics metrics = user.getBodyMetrics();
        if (metrics == null || metrics.getHeightCm() == null || metrics.getWeightKg() == null) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Physical profile must be completed before body scan");
        }

        AiBodyAnalysisResult aiResult = aiClient.analyzeBody(
                user.getId(),
                "transient-body-scan",
                Map.of(
                        "heightCm", metrics.getHeightCm(),
                        "weightKg", metrics.getWeightKg(),
                        "contentType", file.getContentType() == null ? "unknown" : file.getContentType(),
                        "sizeBytes", file.getSize(),
                        "frameBytes", readBodyScanBytes(file)));
        GoalType inferredGoal = inferGoalType(metrics, aiResult);

        bodyAnalysisRepository.save(BodyAnalysisResult.builder()
                .userId(user.getId())
                .metadata(Map.of(
                        "source", "onboarding",
                        "storage", "transient",
                        "inferredGoalType", inferredGoal.name()))
                .posture(aiResultMapper.toMap(objectMapper, aiResult.posture()))
                .imbalance(aiResultMapper.toMap(objectMapper, aiResult.imbalance()))
                .estimate(aiResultMapper.toMap(objectMapper, aiResult.estimate()))
                .recommendation(aiResultMapper.toMap(objectMapper, aiResult.recommendation()))
                .result(aiResultMapper.toMap(objectMapper, aiResult))
                .build());

        user.setGoalType(inferredGoal);
        user.setOnboardingStatus(OnboardingStatus.COMPLETED);
        user.setActive(true);
        User saved = userRepository.save(user);

        return aiResultMapper.toOnboardingResponse(
                saved.getOnboardingStatus(),
                userMapper.toResponse(saved),
                aiResult);
    }

    @Override
    @CacheEvict(value = "personalized_workouts", key = "T(com.vfit.common.util.SecurityUtil).requireCurrentUserId()")
    public OnboardingResponse completeRealtimeBodyScan(AiBodyAnalysisResult aiResult) {
        if (aiResult == null) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Body analysis result is required");
        }

        User user = currentUser();
        User.BodyMetrics metrics = user.getBodyMetrics();
        if (metrics == null || metrics.getHeightCm() == null || metrics.getWeightKg() == null) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Physical profile must be completed before body scan");
        }

        GoalType inferredGoal = inferGoalType(metrics, aiResult);

        bodyAnalysisRepository.save(BodyAnalysisResult.builder()
                .userId(user.getId())
                .metadata(Map.of(
                        "source", "onboarding-realtime",
                        "inferredGoalType", inferredGoal.name()))
                .posture(aiResultMapper.toMap(objectMapper, aiResult.posture()))
                .imbalance(aiResultMapper.toMap(objectMapper, aiResult.imbalance()))
                .estimate(aiResultMapper.toMap(objectMapper, aiResult.estimate()))
                .recommendation(aiResultMapper.toMap(objectMapper, aiResult.recommendation()))
                .result(aiResultMapper.toMap(objectMapper, aiResult))
                .build());

        user.setGoalType(inferredGoal);
        user.setOnboardingStatus(OnboardingStatus.COMPLETED);
        user.setActive(true);
        User saved = userRepository.save(user);

        return aiResultMapper.toOnboardingResponse(
                saved.getOnboardingStatus(),
                userMapper.toResponse(saved),
                aiResult);
    }

    private User currentUser() {
        return userRepository.findById(SecurityUtil.requireCurrentUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private byte[] readBodyScanBytes(MultipartFile file) {
        try {
            return file.getBytes();
        } catch (IOException e) {
            throw new AppException(ErrorCode.BAD_REQUEST, "Could not read body scan image");
        }
    }

    private Double calculateBmi(Double heightCm, Double weightKg) {
        if (heightCm == null || weightKg == null || heightCm <= 0) {
            return null;
        }
        double meters = heightCm / 100.0;
        return Math.round((weightKg / (meters * meters)) * 10.0) / 10.0;
    }

    private GoalType inferGoalType(User.BodyMetrics metrics, AiBodyAnalysisResult aiResult) {
        Double bodyFatPercent = firstNonNull(
                metrics.getBodyFatPercent(),
                aiResult.estimate() == null ? null : aiResult.estimate().bodyFatPercent());
        if (bodyFatPercent != null) {
            if (bodyFatPercent >= 25.0) {
                return GoalType.LOSE_WEIGHT;
            }
            if (bodyFatPercent <= 18.0) {
                return GoalType.GAIN_MUSCLE;
            }
        }

        Double bmi = metrics.getBmi();
        if (bmi != null) {
            if (bmi >= 23.0) {
                return GoalType.LOSE_WEIGHT;
            }
            if (bmi < 18.5) {
                return GoalType.GAIN_MUSCLE;
            }
        }

        String focus = aiResult.recommendation() == null ? "" : aiResult.recommendation().focus();
        if (focus != null) {
            String normalizedFocus = focus.toLowerCase();
            if (normalizedFocus.contains("weight")
                    || normalizedFocus.contains("fat")
                    || normalizedFocus.contains("cut")) {
                return GoalType.LOSE_WEIGHT;
            }
        }

        return GoalType.GAIN_MUSCLE;
    }

    private Double firstNonNull(Double primary, Double fallback) {
        return primary != null ? primary : fallback;
    }

    @Override
    @CacheEvict(value = "personalized_workouts", key = "T(com.vfit.common.util.SecurityUtil).requireCurrentUserId()")
    public UserResponse resetOnboarding() {
        User user = currentUser();
        user.setOnboardingStatus(OnboardingStatus.PENDING);
        user.setGoalType(null);
        return userMapper.toResponse(userRepository.save(user));
    }
}
