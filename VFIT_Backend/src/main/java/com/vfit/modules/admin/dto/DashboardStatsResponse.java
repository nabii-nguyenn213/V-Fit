package com.vfit.modules.admin.dto;

import java.math.BigDecimal;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class DashboardStatsResponse {
    private final long monthlyVipCustomers;
    private final long yearlyVipCustomers;
    private final BigDecimal monthlyRevenue;
    private final BigDecimal yearlyRevenue;
    private final BigDecimal totalRevenue;
}
