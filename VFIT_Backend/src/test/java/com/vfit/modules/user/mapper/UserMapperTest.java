package com.vfit.modules.user.mapper;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.vfit.common.enums.RoleName;
import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.modules.subscription.repository.SubscriptionRepository;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.dto.response.UserResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class UserMapperTest {
    @Mock
    private SubscriptionRepository subscriptionRepository;
    @InjectMocks
    private UserMapper userMapper;

    @Test
    void mapsActiveVipTrialAsRenewableRegardlessOfRemainingDuration() {
        User trialUser = activeVipUser("trial-user", "VIP_TRIAL", Duration.ofDays(10));
        when(subscriptionRepository.findFirstByUserIdOrderByExpiresAtDesc("trial-user"))
                .thenReturn(Optional.empty());

        UserResponse response = userMapper.toResponse(trialUser);

        assertThat(response.isPremiumActive()).isTrue();
        assertThat(response.isCanRenewPremium()).isTrue();
    }

    @Test
    void mapsActivePaidVipOutsideRenewalWindowAsNotRenewable() {
        User paidUser = activeVipUser("paid-user", "VIP_MONTHLY", Duration.ofDays(10));
        when(subscriptionRepository.findFirstByUserIdOrderByExpiresAtDesc("paid-user"))
                .thenReturn(Optional.empty());

        UserResponse response = userMapper.toResponse(paidUser);

        assertThat(response.isPremiumActive()).isTrue();
        assertThat(response.isCanRenewPremium()).isFalse();
    }

    private User activeVipUser(String id, String planCode, Duration remaining) {
        Instant now = Instant.now();
        return User.builder()
                .id(id)
                .email(id + "@example.com")
                .fullName("V-FIT User")
                .role(RoleName.USER)
                .active(true)
                .createdAt(now)
                .subscription(User.SubscriptionSnapshot.builder()
                        .status(SubscriptionStatus.ACTIVE)
                        .planCode(planCode)
                        .premiumUntil(now.plus(remaining))
                        .build())
                .build();
    }
}
