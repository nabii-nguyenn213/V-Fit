package com.vfit.modules.workout.service;

import com.vfit.modules.workout.dto.response.WorkoutProgramResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface WorkoutService {
    Page<WorkoutProgramResponse> getWorkoutPrograms(Pageable pageable);

    WorkoutProgramResponse getWorkoutProgramById(String id);
}
