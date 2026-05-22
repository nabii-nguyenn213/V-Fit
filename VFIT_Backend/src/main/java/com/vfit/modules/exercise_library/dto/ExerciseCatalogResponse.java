package com.vfit.modules.exercise_library.dto;

import java.util.List;

public record ExerciseCatalogResponse(
        int catalogVersion,
        List<MuscleGroupResponse> groups) {

    public record MuscleGroupResponse(
            String id,
            String name,
            List<SubMuscleGroupResponse> subGroups) {
    }

    public record SubMuscleGroupResponse(
            String id,
            String name,
            List<ExerciseItemResponse> exercises) {
    }

    public record ExerciseItemResponse(
            String id,
            String name,
            String videoUrl,
            String videoSearchHint,
            String description,
            List<String> equipment) {
    }

    public static ExerciseCatalogResponse empty() {
        return new ExerciseCatalogResponse(0, List.of());
    }
}
