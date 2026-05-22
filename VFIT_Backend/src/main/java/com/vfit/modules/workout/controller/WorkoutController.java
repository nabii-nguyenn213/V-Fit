package com.vfit.modules.workout.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.api.PageResponse;
import com.vfit.modules.workout.dto.response.WorkoutProgramResponse;
import com.vfit.modules.workout.service.WorkoutService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/workouts")
@RequiredArgsConstructor
public class WorkoutController {
    private final WorkoutService workoutService;

    @GetMapping
    public ApiResponse<PageResponse<WorkoutProgramResponse>> workouts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(PageResponse.from(workoutService.getWorkoutPrograms(PageRequest.of(page, size))));
    }

    @GetMapping("/{id}")
    public ApiResponse<WorkoutProgramResponse> workout(@PathVariable String id) {
        return ApiResponse.ok(workoutService.getWorkoutProgramById(id));
    }
}
