package com.vfit.modules.workout.service.impl;

import com.vfit.common.exception.ResourceNotFoundException;
import com.vfit.modules.workout.dto.response.WorkoutProgramResponse;
import com.vfit.modules.workout.mapper.WorkoutMapper;
import com.vfit.modules.workout.repository.WorkoutProgramRepository;
import com.vfit.modules.workout.service.WorkoutService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class WorkoutServiceImpl implements WorkoutService {
    private final WorkoutProgramRepository workoutProgramRepository;
    private final WorkoutMapper workoutMapper;

    @Override
    public Page<WorkoutProgramResponse> getWorkoutPrograms(Pageable pageable) {
        return workoutProgramRepository.findAll(pageable).map(workoutMapper::toResponse);
    }

    @Override
    public WorkoutProgramResponse getWorkoutProgramById(String id) {
        return workoutProgramRepository.findById(id)
                .map(workoutMapper::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("Workout program not found"));
    }
}
