package com.vfit.modules.payment.scheduler;

import com.vfit.modules.payment.enums.PaymentStatus;
import com.vfit.modules.subscription.document.PaymentTransaction;
import com.vfit.modules.subscription.repository.PaymentTransactionRepository;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class PaymentExpiryScheduler {
    private final PaymentTransactionRepository paymentTransactionRepository;

    @Scheduled(fixedDelayString = "${payment.expiry-scan-delay-ms:60000}")
    public void expirePendingPayments() {
        Instant now = Instant.now();
        List<PaymentTransaction> expired = paymentTransactionRepository
                .findByPaymentStatusInAndExpiredAtBefore(List.of(PaymentStatus.PENDING), now);
        if (expired.isEmpty()) {
            return;
        }
        expired.forEach(payment -> {
            payment.setPaymentStatus(PaymentStatus.EXPIRED);
            payment.setStatus(PaymentStatus.EXPIRED.name());
        });
        paymentTransactionRepository.saveAll(expired);
        log.info("[PAYMENT] Expired {} pending premium payments", expired.size());
    }
}
