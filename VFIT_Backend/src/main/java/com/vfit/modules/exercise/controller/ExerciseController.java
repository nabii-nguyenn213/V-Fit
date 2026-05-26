package com.vfit.modules.exercise.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.api.PageResponse;
import com.vfit.common.enums.DifficultyLevel;
import com.vfit.modules.exercise.dto.response.ExerciseResponse;
import com.vfit.modules.exercise.service.ExerciseCatalogService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/exercises")
@RequiredArgsConstructor
public class ExerciseController {
    private final ExerciseCatalogService exerciseCatalogService;

    @GetMapping
    public ApiResponse<PageResponse<ExerciseResponse>> exercises(
            @RequestParam(required = false) String muscleGroup,
            @RequestParam(required = false) DifficultyLevel difficulty,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);
        return ApiResponse.ok(PageResponse.from(exerciseCatalogService.search(muscleGroup, difficulty, keyword, PageRequest.of(safePage, safeSize))));
    }

    @GetMapping("/{id}")
    public ApiResponse<ExerciseResponse> exercise(@PathVariable String id) {
        return ApiResponse.ok(exerciseCatalogService.getById(id));
    }
}
