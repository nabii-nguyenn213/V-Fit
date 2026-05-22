package com.vfit.modules.exercise_library.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.exercise_library.dto.ExerciseCatalogResponse;
import com.vfit.modules.exercise_library.service.ExerciseLibraryService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/exercise-library")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminExerciseLibraryController {
    private final ExerciseLibraryService exerciseLibraryService;

    @PostMapping("/seed-default")
    public ApiResponse<ExerciseCatalogResponse> seedDefault(
            @RequestParam(defaultValue = "vi-VN") String locale) {
        return ApiResponse.ok(exerciseLibraryService.seedDefaultCatalog(locale));
    }
}
