package com.vfit.modules.exercise.repository;

import com.vfit.common.enums.DifficultyLevel;
import com.vfit.modules.exercise.document.Exercise;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface ExerciseSearchRepository {
    Page<Exercise> search(String muscleGroup, DifficultyLevel difficulty, String keyword, Pageable pageable);
}
