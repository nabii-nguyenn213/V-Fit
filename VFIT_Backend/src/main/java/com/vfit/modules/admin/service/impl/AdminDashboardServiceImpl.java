package com.vfit.modules.admin.service.impl;

import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.modules.admin.dto.DashboardStatsResponse;
import com.vfit.modules.admin.service.AdminDashboardService;
import com.vfit.modules.subscription.SubscriptionPlanCatalog;
import com.vfit.modules.user.repository.UserRepository;
import com.vfit.modules.admin_dashboard.repository.OrderRepository;
import com.vfit.modules.admin_dashboard.dto.MonthlyRevenueAggregationResult;
import java.math.BigDecimal;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AdminDashboardServiceImpl implements AdminDashboardService {
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;

    @Override
    public DashboardStatsResponse getStats() {
        long monthlyVipCustomers = userRepository.countBySubscriptionStatusAndPlanCode(
                SubscriptionStatus.ACTIVE,
                SubscriptionPlanCatalog.VIP_MONTHLY.code());
        long yearlyVipCustomers = userRepository.countBySubscriptionStatusAndPlanCode(
                SubscriptionStatus.ACTIVE,
                SubscriptionPlanCatalog.VIP_YEARLY.code());
        
        // MRR (Current recurring revenue)
        BigDecimal monthlyRevenue = SubscriptionPlanCatalog.VIP_MONTHLY.price()
                .multiply(BigDecimal.valueOf(monthlyVipCustomers));
        BigDecimal yearlyRevenue = SubscriptionPlanCatalog.VIP_YEARLY.price()
                .multiply(BigDecimal.valueOf(yearlyVipCustomers));

        // Real Lifetime Revenue from orders collection
        List<MonthlyRevenueAggregationResult> aggregated = orderRepository.aggregateMonthlyRevenue();
        double lifetimeRevenue = 0.0;
        for (MonthlyRevenueAggregationResult res : aggregated) {
            if (res.getTotalRevenue() != null) {
                lifetimeRevenue += res.getTotalRevenue();
            }
        }

        return DashboardStatsResponse.builder()
                .monthlyVipCustomers(monthlyVipCustomers)
                .yearlyVipCustomers(yearlyVipCustomers)
                .monthlyRevenue(monthlyRevenue)
                .yearlyRevenue(yearlyRevenue)
                .totalRevenue(BigDecimal.valueOf(lifetimeRevenue))
                .build();
    }
}
