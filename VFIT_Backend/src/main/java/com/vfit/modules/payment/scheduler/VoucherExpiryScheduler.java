package com.vfit.modules.payment.scheduler;

import com.vfit.modules.payment.enums.VoucherStatus;
import com.vfit.modules.payment.repository.VoucherRepository;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class VoucherExpiryScheduler {
    private final VoucherRepository voucherRepository;

    @Scheduled(fixedDelayString = "${payment.voucher-expiry-scan-delay-ms:60000}")
    public void expireVouchers() {
        List<com.vfit.modules.payment.entity.Voucher> expired = voucherRepository
                .findByStatusInAndExpiredAtBefore(List.of(VoucherStatus.ACTIVE), Instant.now());
        if (expired.isEmpty()) {
            return;
        }
        expired.forEach(voucher -> voucher.setStatus(VoucherStatus.EXPIRED));
        voucherRepository.saveAll(expired);
        log.info("[PAYMENT] Expired {} vouchers", expired.size());
    }
}
