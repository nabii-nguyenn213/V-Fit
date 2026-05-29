package com.vfit.modules.gamification.service;

import com.vfit.modules.gamification.document.UserChallengeParticipation;
import java.time.Instant;
import java.util.List;

public interface ChallengeParticipationService {
    UserChallengeParticipation joinChallenge(String userId, String challengeId);

    void mapPhotoToActiveChallenges(String userId, String photoId, String photoUrl, Instant uploadedAt);

    /**
     * Records a workout session check-in for the user.
     * Increments the streak on all IN_PROGRESS challenge participations,
     * using the same rules as photo check-in but without requiring a photo.
     * Idempotent per day — calling twice on the same date has no effect.
     */
    void recordWorkoutCheckin(String userId, String date);

    UserChallengeParticipation getParticipation(String userId, String challengeId);

    List<UserChallengeParticipation> getActiveParticipations(String userId);

    UserChallengeParticipation reviveStreak(String userId, String challengeId);
}
