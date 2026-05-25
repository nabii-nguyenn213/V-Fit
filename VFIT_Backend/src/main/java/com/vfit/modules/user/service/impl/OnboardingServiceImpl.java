package com.vfit.modules.user.service.impl;

import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.exception.AppException;
import com.vfit.common.exception.ErrorCode;
import com.vfit.common.exception.ResourceNotFoundException;
import com.vfit.common.util.SecurityUtil;
import com.vfit.infrastructure.config.AppProperties;
import com.vfit.infrastructure.external.ai.AiClient;
import com.vfit.bootstrap.storage.FileStorageService;
import com.vfit.modules.ai.document.BodyAnalysisResult;
import com.vfit.modules.ai.repository.BodyAnalysisRepository;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.request.OnboardingMetricsRequest;
import com.vfit.modules.user.dto.request.OnboardingProfileRequest;
import com.vfit.modules.user.dto.response.OnboardingResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.mapper.UserMapper;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.user.service.OnboardingService;
import java.time.Instant;
import java.util.LinkedHashMap;
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
    private final FileStorageService fileStorageService;
    private final AiClient aiClient;
    private final BodyAnalysisRepository bodyAnalysisRepository;
    private final AppProperties appProperties;

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

        String scanPath = fileStorageService.store(file, "body-scans");
        String scanUrl = appProperties.getBaseUrl() + "/uploads/" + scanPath;
        Map<String, Object> aiResult = aiClient.analyzeBody(
                user.getId(),
                scanUrl,
                Map.of("heightCm", metrics.getHeightCm(), "weightKg", metrics.getWeightKg()));

        Map<String, Object> posture = mapValue(aiResult, "posture");
        Map<String, Object> imbalance = mapValue(aiResult, "imbalance");
        Map<String, Object> estimate = mapValue(aiResult, "estimate");
        Map<String, Object> recommendation = mapValue(aiResult, "recommendation");

        bodyAnalysisRepository.save(BodyAnalysisResult.builder()
                .userId(user.getId())
                .imageUrl(scanPath)
                .metadata(Map.of("source", "onboarding", "scanUrl", scanUrl))
                .posture(posture)
                .imbalance(imbalance)
                .estimate(estimate)
                .recommendation(recommendation)
                .result(aiResult)
                .build());

        user.setOnboardingStatus(OnboardingStatus.COMPLETED);
        user.setActive(true);
        User saved = userRepository.save(user);

        return OnboardingResponse.builder()
                .onboardingStatus(saved.getOnboardingStatus())
                .user(userMapper.toResponse(saved))
                .posture(posture)
                .imbalance(imbalance)
                .estimate(estimate)
                .recommendation(recommendation)
                .build();
    }

    private User currentUser() {
        return userRepository.findById(SecurityUtil.requireCurrentUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private Map<String, Object> mapValue(Map<String, Object> source, String key) {
        Object value = source.get(key);
        if (!(value instanceof Map<?, ?> map)) {
            return Map.of();
        }
        Map<String, Object> typed = new LinkedHashMap<>();
        map.forEach((entryKey, entryValue) -> {
            if (entryKey instanceof String stringKey) {
                typed.put(stringKey, entryValue);
            }
        });
        return typed;
    }

    private Double calculateBmi(Double heightCm, Double weightKg) {
        if (heightCm == null || weightKg == null || heightCm <= 0) {
            return null;
        }
        double meters = heightCm / 100.0;
        return Math.round((weightKg / (meters * meters)) * 10.0) / 10.0;
    }
}
