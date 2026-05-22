package com.vfit.modules.exercise.mapper;

import com.vfit.modules.exercise.document.Exercise;
import com.vfit.modules.exercise.dto.response.ExerciseResponse;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface ExerciseMapper {
    ExerciseResponse toResponse(Exercise exercise);
}
