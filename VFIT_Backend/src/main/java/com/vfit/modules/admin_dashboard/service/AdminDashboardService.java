package com.vfit.modules.admin_dashboard.service;

import com.vfit.common.api.PaginatedResponse;
import com.vfit.modules.admin_dashboard.dto.MonthlyRevenueResponse;
import com.vfit.modules.admin_dashboard.dto.OrderDto;

public interface AdminDashboardService {
    MonthlyRevenueResponse getMonthlyRevenueReport();
    PaginatedResponse<OrderDto> getTransactions(int page, int size);
}
