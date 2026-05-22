package com.vfit.modules.gamification.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChallengeReward {
    private int points;
    private String badgeId;
    private String voucherTemplateId;
    @Builder.Default
    private int premiumDaysGranted = 0;
}
