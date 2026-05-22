package com.vfit.modules.admin.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.admin.dto.DashboardStatsResponse;
import com.vfit.modules.admin.service.AdminDashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/dashboard")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminDashboardController {
    private final AdminDashboardService adminDashboardService;

    @GetMapping
    public ApiResponse<DashboardStatsResponse> dashboard() {
        return ApiResponse.ok(adminDashboardService.getStats());
    }
}
