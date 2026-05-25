package com.vfit.modules.app.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.app.dto.response.AppConfigResponse;
import com.vfit.modules.app.service.AppConfigService;
import com.vfit.bootstrap.storage.CloudinaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/app")
@RequiredArgsConstructor
public class AppConfigController {
    private final AppConfigService appConfigService;
    private final CloudinaryService cloudinaryService;

    @GetMapping("/config")
    public ApiResponse<AppConfigResponse> publicConfig() {
        return ApiResponse.ok(appConfigService.getPublicConfig());
    }

    @GetMapping("/cloudinary-test")
    public ApiResponse<Map<String, Object>> testCloudinary() {
        boolean active = cloudinaryService.checkConnection();
        Map<String, Object> result = new HashMap<>();
        result.put("status", active ? "CONNECTED" : "FAILED");
        result.put("message", active ? "Cloudinary is configured correctly and connected." : "Cloudinary connection failed. Please check credentials.");
        return ApiResponse.ok(result);
    }
}
