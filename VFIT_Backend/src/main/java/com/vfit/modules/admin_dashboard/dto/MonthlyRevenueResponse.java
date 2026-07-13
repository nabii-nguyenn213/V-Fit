package com.vfit.modules.admin_dashboard.dto;

import java.util.List;

public record MonthlyRevenueResponse(
    Double lifetimeRevenue,
    List<MonthlyRevenueItem> monthlyDetails,
    List<OrderDto> recentTransactions,
    long totalUsers,
    long activeVipUsers,
    long freeUsers,
    long onboardingCompletedUsers,
    long onboardingPendingUsers
) {}
