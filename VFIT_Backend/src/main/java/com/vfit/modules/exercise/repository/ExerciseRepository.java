package com.vfit.modules.exercise.repository;

import com.vfit.modules.exercise.document.Exercise;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface ExerciseRepository extends MongoRepository<Exercise, String>, ExerciseSearchRepository {
}
