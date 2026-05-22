package com.vfit.modules.user.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.user.dto.request.OnboardingProfileRequest;
import com.vfit.modules.user.dto.response.OnboardingResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.service.OnboardingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/users/onboarding")
@RequiredArgsConstructor
public class OnboardingController {
    private final OnboardingService onboardingService;

    @PutMapping("/profile")
    public ApiResponse<UserResponse> updatePhysicalProfile(@Valid @RequestBody OnboardingProfileRequest request) {
        return ApiResponse.ok(onboardingService.updatePhysicalProfile(request));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<OnboardingResponse> completeBodyScan(
            @RequestPart(value = "file", required = false) MultipartFile file,
            @RequestPart(value = "image", required = false) MultipartFile image,
            @RequestPart(value = "video", required = false) MultipartFile video) {
        MultipartFile upload = file != null ? file : image != null ? image : video;
        return ApiResponse.ok(onboardingService.completeBodyScan(upload));
    }
}
