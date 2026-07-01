package com.vfit.modules.user.dto.response;

import com.vfit.common.enums.Gender;
import com.vfit.common.enums.GoalType;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.enums.RoleName;
import com.vfit.common.enums.SubscriptionStatus;
import java.time.Instant;
import java.time.LocalDate;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserResponse {
    private final String id;
    private final String email;
    private final String fullName;
    private final String avatarUrl;
    private final Gender gender;
    private final LocalDate dateOfBirth;
    private final GoalType goalType;
    private final RoleName role;
    private final OnboardingStatus onboardingStatus;
    private final boolean active;
    private final int xp;
    private final int level;
    private final SubscriptionStatus subscriptionStatus;
    private final String subscriptionPlanCode;
    private final boolean premiumActive;
    private final String premiumPlan;
    private final Instant premiumStartedAt;
    private final Instant premiumExpiredAt;
    private final long premiumRemainingDays;
    private final boolean canRenewPremium;
    private final Instant createdAt;
}
