package com.vfit.modules.exercise.service.impl;

import com.vfit.common.enums.DifficultyLevel;
import com.vfit.common.exception.ResourceNotFoundException;
import com.vfit.modules.exercise.dto.response.ExerciseResponse;
import com.vfit.modules.exercise.mapper.ExerciseMapper;
import com.vfit.modules.exercise.repository.ExerciseRepository;
import com.vfit.modules.exercise.service.ExerciseCatalogService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ExerciseCatalogServiceImpl implements ExerciseCatalogService {
    private final ExerciseRepository exerciseRepository;
    private final ExerciseMapper exerciseMapper;

    @Override
    public Page<ExerciseResponse> search(String muscleGroup, DifficultyLevel difficulty, String keyword, Pageable pageable) {
        return exerciseRepository.search(muscleGroup, difficulty, keyword, pageable).map(exerciseMapper::toResponse);
    }

    @Override
    public ExerciseResponse getById(String id) {
        return exerciseRepository.findById(id)
                .map(exerciseMapper::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("Exercise not found"));
    }
}
