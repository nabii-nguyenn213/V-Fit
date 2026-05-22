package com.vfit.modules.user.document;

import com.vfit.common.enums.Gender;
import com.vfit.common.enums.GoalType;
import com.vfit.common.enums.OnboardingStatus;
import com.vfit.common.enums.RoleName;
import com.vfit.common.enums.SubscriptionStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "users")
public class User {
    @Id
    private String id;
    @Indexed(unique = true)
    private String email;
    private String passwordHash;
    private String fullName;
    private String avatarUrl;
    private Gender gender;
    private LocalDate dateOfBirth;
    private GoalType goalType;
    private RoleName role;
    @Builder.Default
    private OnboardingStatus onboardingStatus = OnboardingStatus.PENDING;
    @Builder.Default
    private boolean active = false;
    @Builder.Default
    private BodyMetrics bodyMetrics = new BodyMetrics();
    @Builder.Default
    private UserProgress progress = UserProgress.initial();
    @Builder.Default
    private SubscriptionSnapshot subscription = SubscriptionSnapshot.free();
    @Builder.Default
    private List<UserBadgeSnapshot> badges = new ArrayList<>();
    @CreatedDate
    private Instant createdAt;
    @LastModifiedDate
    private Instant updatedAt;

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BodyMetrics {
        private Double heightCm;
        private Double weightKg;
        private Double bodyFatPercent;
        private Double bmi;
        private Instant measuredAt;
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserProgress {
        private int xp;
        private int level;
        private int completedWorkouts;
        private int completedChallenges;

        public static UserProgress initial() {
            return UserProgress.builder().xp(0).level(1).completedWorkouts(0).completedChallenges(0).build();
        }
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubscriptionSnapshot {
        private SubscriptionStatus status;
        private String planCode;
        private Instant premiumUntil;

        public static SubscriptionSnapshot free() {
            return SubscriptionSnapshot.builder().status(SubscriptionStatus.FREE).build();
        }
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserBadgeSnapshot {
        private String badgeId;
        private String name;
        private String iconUrl;
        private Instant awardedAt;
    }
}
