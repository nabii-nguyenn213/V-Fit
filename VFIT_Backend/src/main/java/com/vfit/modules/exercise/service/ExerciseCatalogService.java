package com.vfit.modules.exercise.service;

import com.vfit.common.enums.DifficultyLevel;
import com.vfit.modules.exercise.dto.response.ExerciseResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface ExerciseCatalogService {
    Page<ExerciseResponse> search(String muscleGroup, DifficultyLevel difficulty, String keyword, Pageable pageable);

    ExerciseResponse getById(String id);
}
