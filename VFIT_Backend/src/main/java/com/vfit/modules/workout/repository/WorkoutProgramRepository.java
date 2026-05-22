package com.vfit.modules.workout.repository;

import com.vfit.modules.workout.document.WorkoutProgram;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface WorkoutProgramRepository extends MongoRepository<WorkoutProgram, String> {
}
