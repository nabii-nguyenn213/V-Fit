package com.vfit.modules.admin_dashboard.service.impl;

import com.vfit.modules.admin_dashboard.dto.MonthlyRevenueAggregationResult;
import com.vfit.modules.admin_dashboard.dto.MonthlyRevenueItem;
import com.vfit.modules.admin_dashboard.dto.MonthlyRevenueResponse;
import com.vfit.modules.admin_dashboard.dto.OrderDto;
import com.vfit.modules.admin_dashboard.dto.RegistrationTrendItem;
import com.vfit.modules.admin_dashboard.entity.Order;
import com.vfit.modules.admin_dashboard.repository.OrderRepository;
import com.vfit.modules.admin_dashboard.service.AdminDashboardService;
import com.vfit.modules.subscription.document.PaymentTransaction;
import com.vfit.modules.subscription.repository.PaymentTransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;

import com.vfit.modules.user.repository.UserRepository;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service("adminRevenueService")
@RequiredArgsConstructor
@Slf4j
public class AdminDashboardServiceImpl implements AdminDashboardService {

    private final OrderRepository orderRepository;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final UserRepository userRepository;
    private final MongoTemplate mongoTemplate;

    @Override
    public MonthlyRevenueResponse getMonthlyRevenueReport() {
        log.info("Generating dynamic monthly financial revenue report...");
        
        // 1. Fetch aggregated monthly statistics (timezone-aligned via MongoDB Repository)
        List<MonthlyRevenueAggregationResult> rawResults = paymentTransactionRepository.aggregateMonthlyRevenue();
        
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
        List<PaymentTransaction> recentOrders = paymentTransactionRepository.findTop5ByPaymentStatusOrderByCreatedAtDesc(com.vfit.modules.payment.enums.PaymentStatus.PAID);
        List<OrderDto> recentTransactions = recentOrders.stream()
            .map(payment -> {
                String email = userRepository.findById(payment.getUserId())
                    .map(com.vfit.modules.user.document.User::getEmail)
                    .orElse("unknown@vfit.com");
                return toOrderDto(payment, email);
            })
            .toList();
            
        long totalUsers = userRepository.countByRole(com.vfit.common.enums.RoleName.USER);
        long activeVipUsers = userRepository.countBySubscriptionStatusAndRole(
            com.vfit.common.enums.SubscriptionStatus.ACTIVE,
            com.vfit.common.enums.RoleName.USER
        );
        long freeUsers = userRepository.countBySubscriptionStatusAndRole(
            com.vfit.common.enums.SubscriptionStatus.FREE,
            com.vfit.common.enums.RoleName.USER
        );
        long onboardingCompletedUsers = userRepository.countByOnboardingStatusAndRole(
            com.vfit.common.enums.OnboardingStatus.COMPLETED,
            com.vfit.common.enums.RoleName.USER
        );
        long onboardingPendingUsers = userRepository.countByOnboardingStatusAndRole(
            com.vfit.common.enums.OnboardingStatus.PENDING,
            com.vfit.common.enums.RoleName.USER
        );

        // Group and count user registrations by day for non-admin users
        org.springframework.data.mongodb.core.aggregation.Aggregation userAggregation = org.springframework.data.mongodb.core.aggregation.Aggregation.newAggregation(
            org.springframework.data.mongodb.core.aggregation.Aggregation.match(org.springframework.data.mongodb.core.query.Criteria.where("role").is(com.vfit.common.enums.RoleName.USER)),
            org.springframework.data.mongodb.core.aggregation.Aggregation.project()
                .andExpression("dateToString('%Y-%m-%d', createdAt, 'Asia/Ho_Chi_Minh')").as("date"),
            org.springframework.data.mongodb.core.aggregation.Aggregation.group("date").count().as("count"),
            org.springframework.data.mongodb.core.aggregation.Aggregation.project("count").and("_id").as("date"),
            org.springframework.data.mongodb.core.aggregation.Aggregation.sort(org.springframework.data.domain.Sort.Direction.ASC, "date")
        );

        org.springframework.data.mongodb.core.aggregation.AggregationResults<RegistrationTrendItem> aggregationResults = mongoTemplate.aggregate(
            userAggregation,
            "users",
            RegistrationTrendItem.class
        );
        List<RegistrationTrendItem> registrationTrend = aggregationResults.getMappedResults();

        log.info("Financial report calculated. Lifetime Revenue: {} đ, Total Users: {}, Trend Items: {}", lifetimeRevenue, totalUsers, registrationTrend.size());
        return new MonthlyRevenueResponse(
            lifetimeRevenue,
            monthlyDetails,
            recentTransactions,
            totalUsers,
            activeVipUsers,
            freeUsers,
            onboardingCompletedUsers,
            onboardingPendingUsers,
            registrationTrend
        );
    }

    @Override
    public com.vfit.common.api.PaginatedResponse<OrderDto> getTransactions(int page, int size) {
        org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(page, size);
        org.springframework.data.domain.Page<PaymentTransaction> orderPage = paymentTransactionRepository.findByPaymentStatusOrderByCreatedAtDesc(com.vfit.modules.payment.enums.PaymentStatus.PAID, pageable);
        
        List<OrderDto> content = orderPage.getContent().stream()
            .map(payment -> {
                String email = userRepository.findById(payment.getUserId())
                    .map(com.vfit.modules.user.document.User::getEmail)
                    .orElse("unknown@vfit.com");
                return toOrderDto(payment, email);
            })
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

    @Override
    public List<OrderDto> getMonthlyRevenueDetails(String monthStr) {
        log.info("Fetching details for month: {}", monthStr);
        String[] parts = monthStr.split("-");
        if (parts.length != 2) {
            throw new IllegalArgumentException("Invalid month format. Expected YYYY-MM");
        }
        int year = Integer.parseInt(parts[0]);
        int month = Integer.parseInt(parts[1]);

        java.time.ZoneId vnZone = java.time.ZoneId.of("Asia/Ho_Chi_Minh");
        java.time.ZonedDateTime startZoned = java.time.LocalDate.of(year, month, 1)
            .atStartOfDay(vnZone);
        java.time.ZonedDateTime endZoned = startZoned.plusMonths(1).minusNanos(1);

        List<PaymentTransaction> orders = paymentTransactionRepository.findByPaymentStatusAndCreatedAtBetweenOrderByCreatedAtDesc(
            com.vfit.modules.payment.enums.PaymentStatus.PAID,
            startZoned.toInstant(),
            endZoned.toInstant()
        );

        return orders.stream()
            .map(payment -> {
                String email = userRepository.findById(payment.getUserId())
                    .map(com.vfit.modules.user.document.User::getEmail)
                    .orElse("unknown@vfit.com");
                return toOrderDto(payment, email);
            })
            .toList();
    }

    @Override
    public List<OrderDto> getUserTransactionHistory(String userId) {
        log.info("Fetching transaction history for user: {}", userId);
        String email = userRepository.findById(userId)
            .map(com.vfit.modules.user.document.User::getEmail)
            .orElse("unknown@vfit.com");

        List<OrderDto> history = new ArrayList<>();
        paymentTransactionRepository.findSuccessfulByUserId(userId).stream()
            .map(payment -> toOrderDto(payment, email))
            .forEach(history::add);
        orderRepository.findByUserIdAndStatusOrderByCreatedAtDesc(userId, "SUCCESS").stream()
            .map(order -> toOrderDto(order, email))
            .forEach(history::add);

        history.sort(Comparator.comparing(
            OrderDto::createdAt,
            Comparator.nullsLast(Comparator.reverseOrder())
        ));
        return history;
    }

    private OrderDto toOrderDto(PaymentTransaction payment, String email) {
        java.math.BigDecimal amount = payment.getFinalAmount() != null
            ? payment.getFinalAmount()
            : payment.getAmount();
        String orderType = payment.getPlan() != null
            ? payment.getPlan().planCode()
            : "PREMIUM";
        java.time.Instant transactionTime = payment.getPaidAt() != null
            ? payment.getPaidAt()
            : payment.getCreatedAt();

        return new OrderDto(
            payment.getId(),
            payment.getUserId(),
            email,
            orderType,
            amount != null ? amount.doubleValue() : 0.0,
            "SUCCESS",
            payment.getVoucherCode(),
            transactionTime
        );
    }

    private OrderDto toOrderDto(Order order, String email) {
        return new OrderDto(
            order.getId(),
            order.getUserId(),
            email,
            order.getOrderType() != null ? order.getOrderType() : "PREMIUM",
            order.getAmount() != null ? order.getAmount() : 0.0,
            order.getStatus(),
            order.getVoucherCode(),
            order.getCreatedAt()
        );
    }
}
