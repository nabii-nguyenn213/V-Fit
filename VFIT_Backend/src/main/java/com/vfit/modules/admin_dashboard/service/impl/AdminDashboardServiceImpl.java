package com.vfit.modules.admin_dashboard.service.impl;

import com.vfit.modules.admin_dashboard.dto.MonthlyRevenueAggregationResult;
import com.vfit.modules.admin_dashboard.dto.MonthlyRevenueItem;
import com.vfit.modules.admin_dashboard.dto.MonthlyRevenueResponse;
import com.vfit.modules.admin_dashboard.dto.OrderDto;
import com.vfit.modules.admin_dashboard.entity.Order;
import com.vfit.modules.admin_dashboard.repository.OrderRepository;
import com.vfit.modules.admin_dashboard.service.AdminDashboardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service("adminRevenueService")
@RequiredArgsConstructor
@Slf4j
public class AdminDashboardServiceImpl implements AdminDashboardService {

    private final OrderRepository orderRepository;

    @Override
    public MonthlyRevenueResponse getMonthlyRevenueReport() {
        log.info("Generating dynamic monthly financial revenue report...");
        
        // 1. Fetch aggregated monthly statistics (timezone-aligned via MongoDB Repository)
        List<MonthlyRevenueAggregationResult> rawResults = orderRepository.aggregateMonthlyRevenue();
        
        List<MonthlyRevenueItem> monthlyDetails = new ArrayList<>();
        double lifetimeRevenue = 0.0;
        
        // 2. Loop and calculate dynamic growth rates with Division by Zero safeguards
        for (int i = 0; i < rawResults.size(); i++) {
            MonthlyRevenueAggregationResult current = rawResults.get(i);
            double totalRevenue = current.getTotalRevenue() != null ? current.getTotalRevenue() : 0.0;
            lifetimeRevenue += totalRevenue;
            
            double growthRate = 0.0;
            if (i > 0) {
                MonthlyRevenueAggregationResult previous = rawResults.get(i - 1);
                double prevRevenue = previous.getTotalRevenue() != null ? previous.getTotalRevenue() : 0.0;
                
                if (prevRevenue == 0.0) {
                    // Division by zero safeguard
                    growthRate = 100.0;
                } else {
                    double rawRate = ((totalRevenue - prevRevenue) / prevRevenue) * 100.0;
                    growthRate = Math.round(rawRate * 100.0) / 100.0; // Round to 2 decimal places
                }
            }
            
            monthlyDetails.add(new MonthlyRevenueItem(
                current.getId(), // month "YYYY-MM"
                totalRevenue,
                current.getTotalOrders() != null ? current.getTotalOrders() : 0L,
                growthRate
            ));
        }
        
        // Round lifetime revenue to 2 decimal places
        lifetimeRevenue = Math.round(lifetimeRevenue * 100.0) / 100.0;
        
        // 3. Fetch top 5 recent successful transactions
        List<Order> recentOrders = orderRepository.findTop5ByStatusOrderByCreatedAtDesc("SUCCESS");
        List<OrderDto> recentTransactions = recentOrders.stream()
            .map(order -> new OrderDto(
                order.getId(),
                order.getUserId(),
                order.getOrderType() != null ? order.getOrderType() : "PREMIUM",
                order.getAmount() != null ? order.getAmount() : 0.0,
                order.getStatus(),
                order.getVoucherCode(),
                order.getCreatedAt()
            ))
            .toList();
            
        log.info("Financial report calculated. Lifetime Revenue: {} đ", lifetimeRevenue);
        return new MonthlyRevenueResponse(lifetimeRevenue, monthlyDetails, recentTransactions);
    }

    @Override
    public com.vfit.common.api.PaginatedResponse<OrderDto> getTransactions(int page, int size) {
        org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(page, size);
        org.springframework.data.domain.Page<Order> orderPage = orderRepository.findByStatusOrderByCreatedAtDesc("SUCCESS", pageable);
        
        List<OrderDto> content = orderPage.getContent().stream()
            .map(order -> new OrderDto(
                order.getId(),
                order.getUserId(),
                order.getOrderType() != null ? order.getOrderType() : "PREMIUM",
                order.getAmount() != null ? order.getAmount() : 0.0,
                order.getStatus(),
                order.getVoucherCode(),
                order.getCreatedAt()
            ))
            .toList();

        return com.vfit.common.api.PaginatedResponse.<OrderDto>builder()
            .content(content)
            .page(orderPage.getNumber())
            .size(orderPage.getSize())
            .totalElements(orderPage.getTotalElements())
            .totalPages(orderPage.getTotalPages())
            .last(orderPage.isLast())
            .build();
    }
}
