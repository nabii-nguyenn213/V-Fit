package com.vfit.modules.user.service;

import com.vfit.modules.user.dto.request.OnboardingMetricsRequest;
import com.vfit.modules.user.dto.request.OnboardingProfileRequest;
import com.vfit.modules.user.dto.response.OnboardingResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import org.springframework.web.multipart.MultipartFile;

public interface OnboardingService {
    UserResponse updatePhysicalProfile(OnboardingProfileRequest request);

    OnboardingResponse completeBodyScan(MultipartFile file);

    UserResponse updateOnboardingMetrics(OnboardingMetricsRequest request);
}
