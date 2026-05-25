package com.vfit.modules.user.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.user.dto.request.OnboardingMetricsRequest;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.service.OnboardingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class OnboardingMetricsController {
    private final OnboardingService onboardingService;

    @PutMapping("/onboarding-metrics")
    public ApiResponse<UserResponse> updateOnboardingMetrics(@Valid @RequestBody OnboardingMetricsRequest request) {
        return ApiResponse.ok(onboardingService.updateOnboardingMetrics(request));
    }
}
