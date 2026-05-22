package com.vfit.modules.admin.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.app.dto.request.UpdateAppConfigRequest;
import com.vfit.modules.app.dto.response.AppConfigResponse;
import com.vfit.modules.app.service.AppConfigService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/app-config")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminAppConfigController {
    private final AppConfigService appConfigService;

    @GetMapping
    public ApiResponse<AppConfigResponse> getConfig() {
        return ApiResponse.ok(appConfigService.getPublicConfig());
    }

    @PutMapping
    public ApiResponse<AppConfigResponse> updateConfig(@Valid @RequestBody UpdateAppConfigRequest request) {
        return ApiResponse.ok(appConfigService.updatePublicConfig(request));
    }
}
