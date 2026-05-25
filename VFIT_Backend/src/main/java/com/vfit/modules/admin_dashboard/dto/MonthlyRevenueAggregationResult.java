package com.vfit.modules.admin_dashboard.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MonthlyRevenueAggregationResult {
    private String id; // Represents the year-month string "YYYY-MM"
    private Double totalRevenue;
    private Long totalOrders;
}
