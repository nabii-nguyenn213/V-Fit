package com.vfit.security;

import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.modules.subscription.SubscriptionPlanCatalog;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.security.model.CustomUserDetails;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

@Component("featureGate")
@RequiredArgsConstructor
public class FeatureGate {
    private static final Set<String> PREMIUM_PLANS = Set.of(
            SubscriptionPlanCatalog.VIP_MONTHLY.code(),
            SubscriptionPlanCatalog.VIP_YEARLY.code());

    private final UserRepository userRepository;

    public boolean isPremium(Authentication authentication) {
        if (authentication == null || !(authentication.getPrincipal() instanceof CustomUserDetails details)) {
            return false;
        }
        return userRepository.findById(details.getId())
                .map(user -> user.getSubscription() != null
                        && user.getSubscription().getStatus() == SubscriptionStatus.ACTIVE
                        && PREMIUM_PLANS.contains(user.getSubscription().getPlanCode()))
                .orElse(false);
    }
}
