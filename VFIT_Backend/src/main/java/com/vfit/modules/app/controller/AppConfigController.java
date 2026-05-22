package com.vfit.modules.app.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.app.dto.response.AppConfigResponse;
import com.vfit.modules.app.service.AppConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/app")
@RequiredArgsConstructor
public class AppConfigController {
    private final AppConfigService appConfigService;

    @GetMapping("/config")
    public ApiResponse<AppConfigResponse> publicConfig() {
        return ApiResponse.ok(appConfigService.getPublicConfig());
    }
}
