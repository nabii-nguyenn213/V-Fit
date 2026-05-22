package com.vfit.modules.checkin.repository;

import com.vfit.modules.checkin.entity.CheckinLog;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CheckinLogRepository extends MongoRepository<CheckinLog, String> {
    long countByUserIdAndMonthKey(String userId, String monthKey);
    boolean existsByUserIdAndCheckinDate(String userId, String checkinDate);
}
