package com.vfit.modules.admin_dashboard.dto;

public record MonthlyRevenueItem(
    String month,
    Double totalRevenue,
    Long totalOrders,
    Double growthRate
) {}
