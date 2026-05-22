package com.vfit.modules.gamification.repository;

import com.vfit.modules.gamification.document.Challenge;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface ChallengeRepository extends MongoRepository<Challenge, String> {
    Page<Challenge> findByActiveTrue(Pageable pageable);
}
