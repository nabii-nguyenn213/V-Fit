package com.vfit.modules.admin.service.impl;

import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.modules.admin.dto.DashboardStatsResponse;
import com.vfit.modules.admin.service.AdminDashboardService;
import com.vfit.modules.subscription.SubscriptionPlanCatalog;
import com.vfit.modules.user.repository.UserRepository;
import java.math.BigDecimal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AdminDashboardServiceImpl implements AdminDashboardService {
    private final UserRepository userRepository;

    @Override
    public DashboardStatsResponse getStats() {
        long monthlyVipCustomers = userRepository.countBySubscriptionStatusAndPlanCode(
                SubscriptionStatus.ACTIVE,
                SubscriptionPlanCatalog.VIP_MONTHLY.code());
        long yearlyVipCustomers = userRepository.countBySubscriptionStatusAndPlanCode(
                SubscriptionStatus.ACTIVE,
                SubscriptionPlanCatalog.VIP_YEARLY.code());
        BigDecimal monthlyRevenue = SubscriptionPlanCatalog.VIP_MONTHLY.price()
                .multiply(BigDecimal.valueOf(monthlyVipCustomers));
        BigDecimal yearlyRevenue = SubscriptionPlanCatalog.VIP_YEARLY.price()
                .multiply(BigDecimal.valueOf(yearlyVipCustomers));

        return DashboardStatsResponse.builder()
                .monthlyVipCustomers(monthlyVipCustomers)
                .yearlyVipCustomers(yearlyVipCustomers)
                .monthlyRevenue(monthlyRevenue)
                .yearlyRevenue(yearlyRevenue)
                .totalRevenue(monthlyRevenue.add(yearlyRevenue))
                .build();
    }
}
