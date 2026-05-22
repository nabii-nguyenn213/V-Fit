package com.vfit.modules.gamification.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ChallengeResponse {
    private final String id;
    private final String title;
    private final String description;
    private final int targetValue;
    private final int xpReward;
    private final String badgeName;
    private final boolean active;
}
