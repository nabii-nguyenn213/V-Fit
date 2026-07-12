package com.vfit.modules.admin_dashboard.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.vfit.modules.admin_dashboard.dto.OrderDto;
import com.vfit.modules.admin_dashboard.entity.Order;
import com.vfit.modules.admin_dashboard.repository.OrderRepository;
import com.vfit.modules.admin_dashboard.service.impl.AdminDashboardServiceImpl;
import com.vfit.modules.payment.enums.PaymentStatus;
import com.vfit.modules.payment.enums.PremiumPlan;
import com.vfit.modules.subscription.document.PaymentTransaction;
import com.vfit.modules.subscription.repository.PaymentTransactionRepository;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AdminDashboardServiceImplTest {
    private static final String USER_ID = "user-1";

    @Mock
    private OrderRepository orderRepository;
    @Mock
    private PaymentTransactionRepository paymentTransactionRepository;
    @Mock
    private UserRepository userRepository;
    @InjectMocks
    private AdminDashboardServiceImpl service;

    @Test
    void getUserTransactionHistoryMergesSuccessfulPaymentsAndLegacyOrdersNewestFirst() {
        Instant oldest = Instant.parse("2026-05-01T02:00:00Z");
        Instant middle = Instant.parse("2026-06-01T02:00:00Z");
        Instant newest = Instant.parse("2026-07-01T02:00:00Z");
        User user = User.builder().id(USER_ID).email("member@vfit.com").build();
        PaymentTransaction successfulLegacyCheckout = PaymentTransaction.builder()
            .id("payment-success")
            .userId(USER_ID)
            .amount(BigDecimal.valueOf(150_000))
            .status("SUCCESS")
            .createdAt(oldest)
            .build();
        PaymentTransaction paidSepayTransaction = PaymentTransaction.builder()
            .id("payment-paid")
            .userId(USER_ID)
            .plan(PremiumPlan.YEARLY)
            .finalAmount(BigDecimal.valueOf(900_000))
            .amount(BigDecimal.valueOf(1_000_000))
            .voucherCode("YEAR100")
            .paymentStatus(PaymentStatus.PAID)
            .status("PAID")
            .createdAt(oldest)
            .paidAt(newest)
            .build();
        Order legacyOrder = Order.builder()
            .id("legacy-order")
            .userId(USER_ID)
            .orderType("VIP_MONTHLY")
            .amount(150_000.0)
            .status("SUCCESS")
            .createdAt(middle)
            .build();

        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(user));
        when(paymentTransactionRepository.findSuccessfulByUserId(USER_ID))
            .thenReturn(List.of(successfulLegacyCheckout, paidSepayTransaction));
        when(orderRepository.findByUserIdAndStatusOrderByCreatedAtDesc(USER_ID, "SUCCESS"))
            .thenReturn(List.of(legacyOrder));

        List<OrderDto> history = service.getUserTransactionHistory(USER_ID);

        assertThat(history).extracting(OrderDto::id)
            .containsExactly("payment-paid", "legacy-order", "payment-success");
        assertThat(history.get(0))
            .extracting(
                OrderDto::userEmail,
                OrderDto::orderType,
                OrderDto::amount,
                OrderDto::status,
                OrderDto::voucherCode,
                OrderDto::createdAt)
            .containsExactly(
                "member@vfit.com",
                "VIP_YEARLY",
                900_000.0,
                "SUCCESS",
                "YEAR100",
                newest);
        assertThat(history.get(2).status()).isEqualTo("SUCCESS");
        verify(paymentTransactionRepository).findSuccessfulByUserId(USER_ID);
        verify(orderRepository).findByUserIdAndStatusOrderByCreatedAtDesc(USER_ID, "SUCCESS");
    }
}
