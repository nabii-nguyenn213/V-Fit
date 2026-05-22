package com.vfit.modules.workout.repository;

import com.vfit.modules.workout.document.WorkoutHistory;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface WorkoutHistoryRepository extends MongoRepository<WorkoutHistory, String> {
}
