package com.vfit.modules.user.dto.response;

import com.vfit.common.enums.OnboardingStatus;
import com.vfit.infrastructure.external.ai.dto.AiBodyAnalysisResult;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class OnboardingResponse {
    private final OnboardingStatus onboardingStatus;
    private final UserResponse user;
    private final AiBodyAnalysisResult.Posture posture;
    private final AiBodyAnalysisResult.Imbalance imbalance;
    private final AiBodyAnalysisResult.BodyEstimate estimate;
    private final AiBodyAnalysisResult.Recommendation recommendation;
    private final boolean fallback;
}
