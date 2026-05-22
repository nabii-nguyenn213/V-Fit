package com.vfit.modules.workout.mapper;

import com.vfit.modules.workout.document.WorkoutProgram;
import com.vfit.modules.workout.dto.response.WorkoutProgramResponse;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface WorkoutMapper {
    WorkoutProgramResponse toResponse(WorkoutProgram workoutProgram);
}
