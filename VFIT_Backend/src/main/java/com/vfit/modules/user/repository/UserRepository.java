package com.vfit.modules.user.repository;

import com.vfit.common.enums.RoleName;
import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.modules.user.document.User;
import java.util.Optional;
import java.time.Instant;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;

public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    Page<User> findByRole(RoleName role, Pageable pageable);

    @Query(value = "{ 'subscription.status': ?0, 'subscription.planCode': ?1 }", count = true)
    long countBySubscriptionStatusAndPlanCode(SubscriptionStatus status, String planCode);

    List<User> findByActiveFalseAndDeactivatedAtBefore(Instant threshold);

    void deleteByActiveFalseAndCreatedAtBefore(Instant threshold);
}
