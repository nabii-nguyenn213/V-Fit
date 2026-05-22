package com.vfit.modules.exercise_library.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.exercise_library.dto.ExerciseCatalogResponse;
import com.vfit.modules.exercise_library.service.ExerciseLibraryService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/exercises")
@RequiredArgsConstructor
public class ExerciseLibraryController {
    private final ExerciseLibraryService exerciseLibraryService;

    @GetMapping("/grouped")
    public ApiResponse<ExerciseCatalogResponse> grouped(
            @RequestParam(defaultValue = "vi-VN") String locale) {
        return ApiResponse.ok(exerciseLibraryService.grouped(locale));
    }
}
