package com.vfit.modules.gamification.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "user_challenge_participations")
@CompoundIndex(name = "user_challenge_idx", def = "{'userId': 1, 'challengeId': 1}", unique = false)
public class UserChallengeParticipation {
    @Id
    private String id;

    @Indexed
    private String userId;

    @Indexed
    private String challengeId;

    @Builder.Default
    private String status = "IN_PROGRESS"; // PENDING, IN_PROGRESS, COMPLETED, FAILED

    private Instant startedAt;
    private Instant completedAt;

    @Builder.Default
    private int currentStreak = 0;

    @Builder.Default
    private int maxStreakAchieved = 0;

    private String lastCheckinDate; // YYYY-MM-DD

    @Builder.Default
    private List<VerifiedPhoto> verifiedPhotos = new ArrayList<>();

    @Indexed(unique = true)
    private String idempotencyKey; // Format: user_challenge_claim:userId:challengeId

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;
}
