package com.vfit.modules.payment.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.vfit.common.enums.SubscriptionStatus;
import com.vfit.common.exception.AppException;
import com.vfit.modules.checkin.repository.UserVoucherAtomicRepository;
import com.vfit.modules.checkin.repository.UserVoucherRepository;
import com.vfit.modules.payment.config.PaymentProperties;
import com.vfit.modules.payment.dto.CreatePaymentRequest;
import com.vfit.modules.payment.dto.PaymentResponse;
import com.vfit.modules.payment.entity.PaymentOrder;
import com.vfit.modules.payment.enums.PremiumPlan;
import com.vfit.modules.payment.repository.PaymentOrderRepository;
import com.vfit.modules.payment.service.impl.PaymentServiceImpl;
import com.vfit.modules.subscription.document.PaymentTransaction;
import com.vfit.modules.subscription.repository.PaymentTransactionRepository;
import com.vfit.modules.subscription.repository.SubscriptionRepository;
import com.vfit.modules.user.document.User;
import com.vfit.modules.user.repository.UserRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

@ExtendWith(MockitoExtension.class)
class PaymentServiceImplTest {
    private static final String USER_ID = "user-1";

    @Mock
    private PaymentOrderRepository paymentOrderRepository;
    @Mock
    private UserVoucherRepository userVoucherRepository;
    @Mock
    private UserVoucherAtomicRepository userVoucherAtomicRepository;
    @Mock
    private PaymentTransactionRepository paymentTransactionRepository;
    @Mock
    private SubscriptionRepository subscriptionRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private StringRedisTemplate redisTemplate;
    @Mock
    private ValueOperations<String, String> valueOperations;
    @Mock
    private VietQrService vietQrService;
    @Mock
    private PaymentProperties paymentProperties;
    @Mock
    private VoucherService voucherService;
    @InjectMocks
    private PaymentServiceImpl paymentService;

    @BeforeEach
    void configurePaymentInfrastructure() {
        when(paymentProperties.getBankCode()).thenReturn("VCB");
        when(paymentProperties.getAccountNumber()).thenReturn("0123456789");
        when(paymentProperties.getAccountName()).thenReturn("VFIT");
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.setIfAbsent(anyString(), eq("1"), any(Duration.class))).thenReturn(true);
    }

    @Test
    void createPremiumPaymentAllowsActiveVipTrialOutsidePaidRenewalWindow() {
        User trialUser = activeVipUser("VIP_TRIAL", Instant.now().plus(Duration.ofDays(10)));
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(trialUser));
        when(subscriptionRepository.findFirstByUserIdOrderByExpiresAtDesc(USER_ID)).thenReturn(Optional.empty());
        when(paymentProperties.getExpiryMinutes()).thenReturn(15L);
        when(paymentTransactionRepository.findByPaymentCode(anyString())).thenReturn(Optional.empty());
        when(voucherService.validateForPayment(eq(USER_ID), eq(PremiumPlan.MONTHLY), isNull()))
                .thenReturn(Optional.empty());
        when(vietQrService.buildQrUrl(any(), anyString())).thenReturn("https://example.com/vietqr.png");
        when(paymentTransactionRepository.save(any(PaymentTransaction.class))).thenAnswer(invocation -> {
            PaymentTransaction transaction = invocation.getArgument(0);
            transaction.setId("payment-1");
            return transaction;
        });

        PaymentResponse response = paymentService.createPremiumPayment(
                USER_ID,
                new CreatePaymentRequest(PremiumPlan.MONTHLY, null));

        assertThat(response.paymentId()).isEqualTo("payment-1");
        assertThat(response.plan()).isEqualTo(PremiumPlan.MONTHLY);
        verify(paymentTransactionRepository).save(any(PaymentTransaction.class));
    }

    @Test
    void createPremiumPaymentRejectsActivePaidVipOutsideRenewalWindow() {
        User paidUser = activeVipUser("VIP_MONTHLY", Instant.now().plus(Duration.ofDays(10)));
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(paidUser));
        when(subscriptionRepository.findFirstByUserIdOrderByExpiresAtDesc(USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> paymentService.createPremiumPayment(
                USER_ID,
                new CreatePaymentRequest(PremiumPlan.YEARLY, null)))
                .isInstanceOf(AppException.class)
                .hasMessage("VIP package is already active.");

        verify(paymentTransactionRepository, never()).save(any(PaymentTransaction.class));
    }

    private User activeVipUser(String planCode, Instant premiumUntil) {
        return User.builder()
                .id(USER_ID)
                .subscription(User.SubscriptionSnapshot.builder()
                        .status(SubscriptionStatus.ACTIVE)
                        .planCode(planCode)
                        .premiumUntil(premiumUntil)
                        .build())
                .build();
    }
}
