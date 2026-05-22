package com.vfit.modules.user.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.user.dto.request.ChangePasswordRequest;
import com.vfit.modules.user.dto.request.UpdateProfileRequest;
import com.vfit.modules.user.dto.response.BodyMetricResponse;
import com.vfit.modules.user.dto.response.UserResponse;
import com.vfit.modules.user.service.UserQueryService;
import com.vfit.modules.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UserQueryService userQueryService;
    private final UserService userService;

    @GetMapping("/me")
    public ApiResponse<UserResponse> me() {
        return ApiResponse.ok(userQueryService.getCurrentUser());
    }

    @PutMapping("/me")
    public ApiResponse<UserResponse> updateMe(@Valid @RequestBody UpdateProfileRequest request) {
        return ApiResponse.ok(userService.updateCurrentUser(request));
    }

    @PostMapping(value = "/me/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<UserResponse> uploadAvatar(
            @RequestPart(value = "file", required = false) MultipartFile file,
            @RequestPart(value = "image", required = false) MultipartFile image) {
        MultipartFile upload = file != null ? file : image;
        return ApiResponse.created(userService.uploadCurrentUserAvatar(upload));
    }

    @PutMapping("/change-password")
    public ApiResponse<Void> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        userService.changeCurrentUserPassword(request);
        return ApiResponse.message("Password changed");
    }

    @GetMapping("/me/body-metrics")
    public ApiResponse<BodyMetricResponse> bodyMetrics() {
        return ApiResponse.ok(userService.getCurrentUserBodyMetrics());
    }
}
