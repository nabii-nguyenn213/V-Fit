package com.vfit.modules.user.mapper;

import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.enums.RoleName;
import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.modules.subscription.document.Subscription;
import com.vfit.modules.subscription.repository.SubscriptionRepository;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.response.BodyMetricResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class UserMapper {
    private final SubscriptionRepository subscriptionRepository;

    public UserResponse toResponse(User user) {
        if (user == null) {
            return null;
        }

        User.UserProgress progress = user.getProgress();
        User.SubscriptionSnapshot subscription = user.getSubscription();
        Subscription persistedSubscription = subscriptionRepository
                .findFirstByUserIdOrderByExpiresAtDesc(user.getId())
                .orElse(null);
        Instant now = Instant.now();
        Instant premiumUntil = resolvePremiumUntil(subscription, persistedSubscription);
        String planCode = resolvePlanCode(subscription, persistedSubscription);
        SubscriptionStatus status = resolveStatus(subscription, persistedSubscription);
        boolean premiumActive = status == SubscriptionStatus.ACTIVE
                && isPremiumPlan(planCode)
                && (premiumUntil == null || premiumUntil.isAfter(now));
        Duration remaining = premiumUntil == null || !premiumUntil.isAfter(now)
                ? Duration.ZERO
                : Duration.between(now, premiumUntil);

        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .avatarUrl(user.getAvatarUrl())
                .gender(user.getGender())
                .dateOfBirth(user.getDateOfBirth())
                .goalType(user.getGoalType())
                .role(user.getRole() == RoleName.ADMIN ? RoleName.ADMIN : RoleName.USER)
                .onboardingStatus(resolveOnboardingStatus(user))
                .active(user.isActive())
                .xp(progress == null ? 0 : progress.getXp())
                .level(progress == null ? 0 : progress.getLevel())
                .subscriptionStatus(status)
                .subscriptionPlanCode(planCode)
                .premiumActive(premiumActive)
                .premiumPlan(normalizePremiumPlan(planCode))
                .premiumStartedAt(resolvePremiumStartedAt(user, persistedSubscription))
                .premiumExpiredAt(premiumUntil)
                .premiumRemainingDays(remaining.toDays())
                .canRenewPremium(!premiumActive || (premiumUntil != null && remaining.compareTo(Duration.ofDays(3)) < 0))
                .createdAt(user.getCreatedAt())
                .build();
    }

    private OnboardingStatus resolveOnboardingStatus(User user) {
        if (user.getOnboardingStatus() != null) {
            return user.getOnboardingStatus();
        }
        return user.isActive() ? OnboardingStatus.COMPLETED : OnboardingStatus.PENDING;
    }

    private String normalizePremiumPlan(String planCode) {
        if (planCode == null || planCode.isBlank()) {
            return null;
        }
        return switch (planCode.toUpperCase(Locale.ROOT)) {
            case "VIP_MONTHLY", "MONTHLY" -> "MONTHLY";
            case "VIP_YEARLY", "YEARLY" -> "YEARLY";
            case "VIP_TRIAL" -> "VIP_TRIAL";
            default -> planCode;
        };
    }

    private Instant resolvePremiumUntil(User.SubscriptionSnapshot snapshot, Subscription persistedSubscription) {
        if (snapshot != null && snapshot.getPremiumUntil() != null) {
            return snapshot.getPremiumUntil();
        }
        return persistedSubscription == null ? null : persistedSubscription.getExpiresAt();
    }

    private Instant resolvePremiumStartedAt(User user, Subscription persistedSubscription) {
        if (persistedSubscription != null && persistedSubscription.getStartedAt() != null) {
            return persistedSubscription.getStartedAt();
        }
        return user.getCreatedAt();
    }

    private String resolvePlanCode(User.SubscriptionSnapshot snapshot, Subscription persistedSubscription) {
        if (snapshot != null && snapshot.getPlanCode() != null && !snapshot.getPlanCode().isBlank()) {
            return snapshot.getPlanCode();
        }
        return persistedSubscription == null ? null : persistedSubscription.getPlanCode();
    }

    private SubscriptionStatus resolveStatus(User.SubscriptionSnapshot snapshot, Subscription persistedSubscription) {
        if (snapshot != null && snapshot.getStatus() != null) {
            return snapshot.getStatus();
        }
        return persistedSubscription == null ? null : persistedSubscription.getStatus();
    }

    private boolean isPremiumPlan(String planCode) {
        if (planCode == null || planCode.isBlank()) {
            return false;
        }
        return switch (planCode.toUpperCase(Locale.ROOT)) {
            case "VIP_MONTHLY", "VIP_YEARLY", "MONTHLY", "YEARLY", "VIP_TRIAL" -> true;
            default -> false;
        };
    }

    public BodyMetricResponse toBodyMetricResponse(User.BodyMetrics bodyMetrics) {
        if (bodyMetrics == null) {
            return null;
        }

        return BodyMetricResponse.builder()
                .heightCm(bodyMetrics.getHeightCm())
                .weightKg(bodyMetrics.getWeightKg())
                .bodyFatPercent(bodyMetrics.getBodyFatPercent())
                .bmi(bodyMetrics.getBmi())
                .measuredAt(bodyMetrics.getMeasuredAt())
                .build();
    }
}
