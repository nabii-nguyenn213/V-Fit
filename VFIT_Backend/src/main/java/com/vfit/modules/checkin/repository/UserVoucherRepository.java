package com.vfit.modules.checkin.repository;

import com.vfit.modules.checkin.entity.UserVoucher;
import com.vfit.modules.checkin.entity.UserVoucherStatus;
import java.time.Instant;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserVoucherRepository extends MongoRepository<UserVoucher, String> {
    boolean existsByUserIdAndMonthKeyAndRewardMilestone(String userId, String monthKey, Integer rewardMilestone);

    Optional<UserVoucher> findByUserIdAndCode(String userId, String code);

    Optional<UserVoucher> findByUserIdAndCodeAndStatusAndExpiredAtAfter(
            String userId,
            String code,
            UserVoucherStatus status,
            Instant now);
}
