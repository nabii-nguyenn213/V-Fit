package com.vfit.modules.ai.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.ai.dto.response.FoodCalorieEstimateResponse;
import com.vfit.modules.ai.service.AiFoodCalorieService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiNutritionScanController {
    private final AiFoodCalorieService aiFoodCalorieService;

    @PostMapping(
            value = "/food-calorie-estimate",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("@featureGate.isPremium(authentication)")
    public ApiResponse<FoodCalorieEstimateResponse> estimateFoodCalories(
            @RequestPart(value = "image", required = false) MultipartFile image) {
        return ApiResponse.ok(aiFoodCalorieService.estimate(image));
    }
}
