package com.vfit.modules.personalized_workout.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.common.util.SecurityUtil;
import com.vfit.modules.personalized_workout.dto.PersonalizedWorkoutResponse;
import com.vfit.modules.personalized_workout.service.PersonalizedWorkoutService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/workouts/personalized")
@RequiredArgsConstructor
public class PersonalizedWorkoutController {

    private final PersonalizedWorkoutService personalizedWorkoutService;

    @GetMapping
    public ApiResponse<PersonalizedWorkoutResponse> getPersonalizedWorkout() {
        String userId = SecurityUtil.requireCurrentUserId();
        PersonalizedWorkoutResponse response = personalizedWorkoutService.getPersonalizedWorkoutPlan(userId);
        return ApiResponse.ok(response);
    }
}
