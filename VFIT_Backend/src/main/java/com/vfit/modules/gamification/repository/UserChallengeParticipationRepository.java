package com.vfit.modules.gamification.repository;

import com.vfit.modules.gamification.document.UserChallengeParticipation;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;
import java.util.Optional;

public interface UserChallengeParticipationRepository extends MongoRepository<UserChallengeParticipation, String> {
    List<UserChallengeParticipation> findByUserId(String userId);
    
    List<UserChallengeParticipation> findByUserIdAndStatus(String userId, String status);
    
    List<UserChallengeParticipation> findByUserIdAndStatusIn(String userId, List<String> statuses);
    
    Optional<UserChallengeParticipation> findByUserIdAndChallengeId(String userId, String challengeId);
    
    Optional<UserChallengeParticipation> findByUserIdAndChallengeIdAndStatus(String userId, String challengeId, String status);
    
    boolean existsByUserIdAndChallengeIdAndStatus(String userId, String challengeId, String status);
}
