package com.vfit.modules.auth.repository;

import com.vfit.modules.auth.document.UserSession;
import java.util.List;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserSessionRepository extends MongoRepository<UserSession, String> {
    Optional<UserSession> findByRefreshTokenHash(String hash);
    List<UserSession> findByUserIdAndIsRevokedFalse(String userId);
    List<UserSession> findByUserId(String userId);
    void deleteByUserId(String userId);
}
