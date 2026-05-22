package com.vfit.modules.user.dto.response;

import com.vfit.common.enums.OnboardingStatus;
import java.util.Map;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class OnboardingResponse {
    private final OnboardingStatus onboardingStatus;
    private final UserResponse user;
    private final Map<String, Object> posture;
    private final Map<String, Object> imbalance;
    private final Map<String, Object> estimate;
    private final Map<String, Object> recommendation;
}
