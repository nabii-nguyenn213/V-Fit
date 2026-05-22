package com.vfit.bootstrap;

import com.vfit.common.enums.RoleName;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.modules.subscription.SubscriptionPlanCatalog;
import com.vfit.infrastructure.config.AppProperties;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.service.UserService;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class AdminSeeder {
    private final UserService userService;
    private final com.vfit.modules.user.repository.UserRepository userRepository;
    private final AppProperties appProperties;
    private final PasswordEncoder passwordEncoder;

    public void seed() {
        AppProperties.Bootstrap.Admin admin = appProperties.getBootstrap().getAdmin();
        if (!userRepository.existsByEmail(admin.getEmail().toLowerCase())) {
            userService.createLocalUser(admin.getEmail(), admin.getPassword(), admin.getFullName(), RoleName.ADMIN);
        }
        seedDemoUsers();
    }

    private void seedDemoUsers() {
        List<DemoUser> users = List.of(
                new DemoUser("tranduytrung251105@gmail.com", "123456A", "Tran Duy Trung", RoleName.USER, SubscriptionStatus.ACTIVE, SubscriptionPlanCatalog.VIP_YEARLY.code(), 365),
                new DemoUser("vip.month@vfit.local", "123456A", "VIP Month User", RoleName.USER, SubscriptionStatus.ACTIVE, SubscriptionPlanCatalog.VIP_MONTHLY.code(), 30),
                new DemoUser("minh.user@vfit.local", "123456A", "Minh Nguyen", RoleName.USER, SubscriptionStatus.FREE, null, 0),
                new DemoUser("linh.user@vfit.local", "123456A", "Linh Tran", RoleName.USER, SubscriptionStatus.FREE, null, 0));

        users.forEach(this::upsertDemoUser);
    }

    private void upsertDemoUser(DemoUser demoUser) {
        String email = demoUser.email().toLowerCase();
        User user = userRepository.findByEmail(email)
                .orElseGet(() -> User.builder().email(email).active(true).build());

        user.setPasswordHash(passwordEncoder.encode(demoUser.password()));
        user.setFullName(demoUser.fullName());
        user.setRole(demoUser.role());
        user.setOnboardingStatus(OnboardingStatus.COMPLETED);
        user.setActive(true);
        user.setSubscription(User.SubscriptionSnapshot.builder()
                .status(demoUser.subscriptionStatus())
                .planCode(demoUser.subscriptionPlanCode())
                .premiumUntil(demoUser.subscriptionDays() > 0
                        ? Instant.now().plus(demoUser.subscriptionDays(), ChronoUnit.DAYS)
                        : null)
                .build());
        userRepository.save(user);
    }

    private record DemoUser(
            String email,
            String password,
            String fullName,
            RoleName role,
            SubscriptionStatus subscriptionStatus,
            String subscriptionPlanCode,
            long subscriptionDays) {
    }
}
