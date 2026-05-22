package com.vfit.modules.user.mapper;

import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.enums.RoleName;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.response.BodyMetricResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import org.springframework.stereotype.Component;

@Component
public class UserMapper {
    public UserResponse toResponse(User user) {
        if (user == null) {
            return null;
        }

        User.UserProgress progress = user.getProgress();
        User.SubscriptionSnapshot subscription = user.getSubscription();

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
                .subscriptionStatus(subscription == null ? null : subscription.getStatus())
                .subscriptionPlanCode(subscription == null ? null : subscription.getPlanCode())
                .createdAt(user.getCreatedAt())
                .build();
    }

    private OnboardingStatus resolveOnboardingStatus(User user) {
        if (user.getOnboardingStatus() != null) {
            return user.getOnboardingStatus();
        }
        return user.isActive() ? OnboardingStatus.COMPLETED : OnboardingStatus.PENDING;
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
