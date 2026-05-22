package com.vfit.modules.gamification.service;

import com.vfit.modules.gamification.document.UserChallengeParticipation;
import java.time.Instant;
import java.util.List;

public interface ChallengeParticipationService {
    UserChallengeParticipation joinChallenge(String userId, String challengeId);
    
    void mapPhotoToActiveChallenges(String userId, String photoId, String photoUrl, Instant uploadedAt);
    
    UserChallengeParticipation getParticipation(String userId, String challengeId);
    
    List<UserChallengeParticipation> getActiveParticipations(String userId);
    
    UserChallengeParticipation reviveStreak(String userId, String challengeId);
}
