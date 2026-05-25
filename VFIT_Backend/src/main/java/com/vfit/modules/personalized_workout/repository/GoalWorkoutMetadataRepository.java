package com.vfit.modules.personalized_workout.repository;

import com.vfit.common.enums.GoalType;
import com.vfit.modules.personalized_workout.document.GoalWorkoutMetadata;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface GoalWorkoutMetadataRepository extends MongoRepository<GoalWorkoutMetadata, String> {
    Optional<GoalWorkoutMetadata> findByGoalType(GoalType goalType);
}
