package com.vfit.modules.admin.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.admin.dto.SearchMetricItem;
import com.vfit.modules.admin.dto.TrafficMetricsResponse;
import com.vfit.modules.admin.service.AdminMetricsService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/metrics")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@Slf4j
public class AdminMetricsController {

    private final AdminMetricsService adminMetricsService;

    @GetMapping("/traffic")
    public ApiResponse<TrafficMetricsResponse> getTrafficMetrics(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("Admin requesting traffic metrics - Page: {}, Size: {}", page, size);
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);
        return ApiResponse.ok(adminMetricsService.getTrafficMetrics(safePage, safeSize));
    }

    @GetMapping("/searches")
    public ApiResponse<List<SearchMetricItem>> getSearchMetrics(
            @RequestParam(defaultValue = "20") int limit) {
        log.info("Admin requesting search metrics - Limit: {}", limit);
        int safeLimit = Math.min(Math.max(limit, 1), 100);
        return ApiResponse.ok(adminMetricsService.getSearchMetrics(safeLimit));
    }
}
