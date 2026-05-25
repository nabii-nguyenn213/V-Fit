package com.vfit.modules.admin_dashboard.controller;

import com.vfit.common.api.ApiResponse;
import com.vfit.modules.admin_dashboard.dto.MonthlyRevenueResponse;
import com.vfit.modules.admin_dashboard.service.AdminDashboardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController("adminRevenueController")
@RequestMapping("/api/v1/admin/revenue")
@RequiredArgsConstructor
@Slf4j
public class AdminDashboardController {

    private final AdminDashboardService adminDashboardService;

    @GetMapping("/monthly")
    public ApiResponse<MonthlyRevenueResponse> getMonthlyRevenueReport() {
        log.info("Received request for REAL-TIME MONTHLY FINANCIAL MONITORING");
        MonthlyRevenueResponse response = adminDashboardService.getMonthlyRevenueReport();
        return ApiResponse.ok(response);
    }

    @GetMapping("/transactions")
    public ApiResponse<com.vfit.common.api.PaginatedResponse<com.vfit.modules.admin_dashboard.dto.OrderDto>> getTransactions(
            @org.springframework.web.bind.annotation.RequestParam(defaultValue = "0") int page,
            @org.springframework.web.bind.annotation.RequestParam(defaultValue = "5") int size) {
        log.info("Received request for PAGINATED TRANSACTIONS (page: {}, size: {})", page, size);
        return ApiResponse.ok(adminDashboardService.getTransactions(page, size));
    }
}
