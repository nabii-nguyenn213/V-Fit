package com.vfit.security;

import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.modules.subscription.document.Subscription;
import com.vfit.modules.subscription.repository.SubscriptionRepository;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.security.model.CustomUserDetails;
import java.time.Instant;
import java.util.Locale;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

@Component("featureGate")
@RequiredArgsConstructor
public class FeatureGate {
    private final UserRepository userRepository;
    private final SubscriptionRepository subscriptionRepository;

    public boolean isPremium(Authentication authentication) {
        if (authentication == null || !(authentication.getPrincipal() instanceof CustomUserDetails details)) {
            return false;
        }

        Optional<User> userOpt = userRepository.findById(details.getId());
        if (userOpt.isEmpty()) {
            return false;
        }
        User user = userOpt.get();

        User.SubscriptionSnapshot snapshot = user.getSubscription();
        Subscription persistedSubscription = subscriptionRepository
                .findFirstByUserIdOrderByExpiresAtDesc(user.getId())
                .orElse(null);

        Instant now = Instant.now();
        Instant premiumUntil = resolvePremiumUntil(snapshot, persistedSubscription);
        String planCode = resolvePlanCode(snapshot, persistedSubscription);
        SubscriptionStatus status = resolveStatus(snapshot, persistedSubscription);

        return status == SubscriptionStatus.ACTIVE
                && isPremiumPlan(planCode)
                && (premiumUntil == null || premiumUntil.isAfter(now));
    }

    private Instant resolvePremiumUntil(User.SubscriptionSnapshot snapshot, Subscription persistedSubscription) {
        if (snapshot != null && snapshot.getPremiumUntil() != null) {
            return snapshot.getPremiumUntil();
        }
        return persistedSubscription == null ? null : persistedSubscription.getExpiresAt();
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
}
